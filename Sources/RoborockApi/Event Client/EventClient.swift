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

    public var connect: (ID, URL) async throws -> Void
    public var subscribe: @Sendable (ID, EventEndpoint) async throws -> AsyncStream<Action>
}

extension EventClient: DependencyKey {
    private static var baseUrl: URL?

    public static var liveValue: Self {
        return Self(
            connect: { id, baseUrl in
                self.baseUrl = baseUrl
            },
            subscribe: { id, endpoint in
                return try await EventSocketActor.shared.subscribe(id: id, baseUrl: baseUrl, and: endpoint)
            }
        )

        final actor EventSocketActor: GlobalActor {
            typealias Dependencies = (connection: URLSessionDataTask, delegate: EventClientDelegate)

            static let shared = EventSocketActor()

            var dependencies: [ID: Dependencies] = [:]

            func subscribe(id: ID, baseUrl: URL?, and endpoint: EventEndpoint) async throws -> AsyncStream<Action> {
                guard let baseUrl = baseUrl else {
                    throw RestClientError.missingBaseUrl
                }
                guard let request = endpoint.makeRequest(with: baseUrl) else {
                    throw RestClientError.invalidEndpoint
                }
                let delegate = EventClientDelegate()
                let urlSession = URLSession(configuration: .default, delegate: delegate, delegateQueue: .main)
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
