//
//  WebSocketClient+Dependency.swift
//  Websocket-Test
//
//  Created by Hack, Thomas on 28.07.23.
//

import ComposableArchitecture
import Foundation

extension DependencyValues {
    public var webSocketClient: WebSocketClient {
        get { self[WebSocketClient.self] }
        set { self[WebSocketClient.self] = newValue }
    }
}

extension WebSocketClient: DependencyKey {
    public static var liveValue: Self {
        return Self(
            open: { await WebSocketActor.shared.open(id: $0, url: $1, protocols: $2) },
            receive: { try await WebSocketActor.shared.receive(id: $0) },
            send: { try await WebSocketActor.shared.send(id: $0, message: $1) },
            sendPing: { try await WebSocketActor.shared.sendPing(id: $0) }
        )

        final actor WebSocketActor: GlobalActor {
            typealias Dependencies = (socket: URLSessionWebSocketTask, delegate: RoborockURLSessionDelegate)

            static let shared = WebSocketActor()

            var dependencies: [ID: Dependencies] = [:]

            func open(id: ID, url: URL, protocols: [String]) -> AsyncStream<Action> {
                let delegate = RoborockURLSessionDelegate()
                let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
                let socket = session.webSocketTask(with: url, protocols: protocols)
                defer { socket.resume() }
                var continuation: AsyncStream<Action>.Continuation!
                let stream = AsyncStream<Action> {
                    $0.onTermination = { _ in
                        socket.cancel()
                        Task { await self.removeDependencies(id: id) }
                    }
                    continuation = $0
                }
                delegate.continuation = continuation
                self.dependencies[id] = (socket, delegate)
                return stream
            }

            func close(id: ID, with closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) async throws {
                defer { self.dependencies[id] = nil }
                try self.socket(id: id).cancel(with: closeCode, reason: reason)
            }

            func receive(id: ID) throws -> AsyncStream<Result<Message, Error>> {
                let socket = try self.socket(id: id)
                return AsyncStream { continuation in
                    let task = Task {
                        while !Task.isCancelled {
                            continuation.yield(await Result { try await Message(socket.receive()) })
                        }
                        continuation.finish()
                    }
                    continuation.onTermination = { _ in task.cancel() }
                }
            }

            func send(id: ID, message: URLSessionWebSocketTask.Message) async throws {
                try await self.socket(id: id).send(message)
            }

            func sendPing(id: ID) async throws {
                let socket = try self.socket(id: id)
                return try await withCheckedThrowingContinuation { continuation in
                    socket.sendPing { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                }
            }

            private func socket(id: ID) throws -> URLSessionWebSocketTask {
                guard let dependencies = self.dependencies[id]?.socket else {
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

