//
//  EventClientDelegate.swift
//  
//
//  Created by Hack, Thomas on 11.03.24.
//

import Foundation

public enum EventType: String, Decodable {
    case stateAttributes = "StateAttributesUpdated"
    case map = "MapUpdated"
}

public enum  EventData: Decodable {
    case stateAttributes([StateAttribute])
    case map(Map)
}

class EventClientDelegate: ClientCertificateDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
    var continuation: AsyncStream<EventClient.Action>.Continuation?

    private var buffer = NSMutableData()
    private var expectedContentLength = 0
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
