//
//  EventClient.swift
//  
//  Credit to https://github.com/fanout/chat-demo-ios/blob/master/ios-eventsource/Utilities/EventSource.swift
//  Created by Hack, Thomas on 26.02.24.
//

import Foundation

import ComposableArchitecture
import Foundation

public struct EventClient {
    public struct ID: Hashable, @unchecked Sendable {
        let rawValue: AnyHashable

        init<RawValue: Hashable & Sendable>(_ rawValue: RawValue) {
            self.rawValue = rawValue
        }

        public init() {
            struct RawValue: Hashable, Sendable {}
            self.rawValue = RawValue()
        }
    }

    @CasePathable
    public enum Action: Equatable {
        case didConnect
        case didDisconnect
        case didCompleteWithError
        case didReceiveKeepAlive
        case didUpdateStateAttributes([StateAttribute])
        case didUpdateMap(Map)
    }

    public var subscribe: @Sendable (ID, URL, EventEndpoint) async throws -> AsyncStream<Action>
}



extension EventClient: DependencyKey {
    public static var liveValue: Self {
        return Self(
            subscribe: { id, baseUrl, endpoint in
                try await EventSocketActor.shared.subscribe(id: id, baseUrl: baseUrl, and: endpoint)
            }
        )

        final actor EventSocketActor: GlobalActor {

            typealias Dependencies = (connection: URLSessionDataTask, delegate: EventClientDelegate)

            static let shared = EventSocketActor()

            var dependencies: [ID: Dependencies] = [:]

            func subscribe(id: ID, baseUrl: URL, and endpoint: EventEndpoint) async throws -> AsyncStream<Action> {
                guard let request = endpoint.makeRequest(with: baseUrl) else {
                    throw RestClientError.invalidEndpoint
                }
                let delegate = EventClientDelegate()
                let configuration = URLSessionConfiguration.default
                let urlSession = URLSession(configuration: configuration, delegate: delegate, delegateQueue: .main)
                let task = urlSession.dataTask(with: request)
                defer {
                    task.resume()
                }
                var continuation: AsyncStream<Action>.Continuation!
                let stream = AsyncStream<Action> {
                    $0.onTermination = { _ in
                        task.cancel()
                        Task { await self.removeDependencies(id: id) }
                    }
                    continuation = $0
                }
                delegate.continuation = continuation
                self.dependencies[id] = (task, delegate)
                return stream
            }

            func close(id: ID) async throws {
                defer { self.dependencies[id] = nil }
                try self.connection(id: id).cancel()
            }

            private func connection(id: ID) throws -> URLSessionDataTask {
                guard let dependencies = self.dependencies[id]?.connection else {
                    struct Closed: Error {}
                    throw Closed()
                }
                return dependencies
            }

            private func removeDependencies(id: ID) {
                self.dependencies[id] = nil
            }
        }
    }
}

public enum EventType: String, Decodable {
    case stateAttributes = "StateAttributesUpdated"
    case map = "MapUpdated"
}

public enum  EventData: Decodable {
    case stateAttributes([StateAttribute])
    case map(Map)
}

class EventClientDelegate: NSObject, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
    var continuation: AsyncStream<EventClient.Action>.Continuation?

    var buffer = NSMutableData()
    var expectedContentLength = 0
    private let validNewlineCharacters = ["\n", "\r"]

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
        self.continuation?.yield(.didCompleteWithError)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)
        let events = extractEventsFromBuffer()
        parseEvents(events)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let httpResponse = response as? HTTPURLResponse else {
            self.continuation?.yield(.didDisconnect)
            completionHandler(.cancel)
            return
        }
        guard httpResponse.statusCode == 200 else {
            self.continuation?.yield(.didDisconnect)
            completionHandler(.cancel)
            return
        }
        self.continuation?.yield(.didConnect)
        completionHandler(.allow)
    }

    private func extractEventsFromBuffer() -> [String] {
        var events = [String]()
        var searchRange =  NSRange(location: 0, length: buffer.length)
        while let foundRange = searchForEventInRange(searchRange) {
            if foundRange.location > searchRange.location {
                let dataChunk = buffer.subdata(with: NSRange(location: searchRange.location, length: foundRange.location - searchRange.location))

                if let text = String(bytes: dataChunk, encoding: .utf8) {
                    events.append(text)
                }
            }
            searchRange.location = foundRange.location + foundRange.length
            searchRange.length = buffer.length - searchRange.location
        }
        buffer.replaceBytes(in: NSRange(location: 0, length: searchRange.location), withBytes: nil, length: 0)
        return events
    }

    private func searchForEventInRange(_ searchRange: NSRange) -> NSRange? {
        let delimiters = validNewlineCharacters.map { "\($0)\($0)".data(using: String.Encoding.utf8)! }
        for delimiter in delimiters {
            let foundRange = buffer.range(of: delimiter, options: NSData.SearchOptions(), in: searchRange)
            if foundRange.location != NSNotFound {
                return foundRange
            }
        }
        return nil
    }

    private func parseEvents(_ events: [String]) {
        for event in events {
            if event.starts(with: ":") {
                continue
            }
            let substrings = event.components(separatedBy: "\n")
            let event = substrings[0].replacing("event: ", with: "")

            guard substrings.count >= 2, let data = substrings[1].replacing("data: ", with: "").data(using: .utf8) else { continue }

            do {
                switch EventType(rawValue: event) {
                case .map:
                    let result = try JSONDecoder().decode(Map.self, from: data)
                    self.continuation?.yield(.didUpdateMap(result))
                case .stateAttributes:
                    let result = try JSONDecoder().decode([StateAttribute].self, from: data)
                    self.continuation?.yield(.didUpdateStateAttributes(result))
                case .none:
                    continue
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
