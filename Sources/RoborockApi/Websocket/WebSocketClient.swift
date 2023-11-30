//
//  WebsocketClient.swift
//
//
//  Created by Hack, Thomas on 28.07.23.
//

import ComposableArchitecture
import Foundation

public struct WebSocketClient {
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
        case didOpen(protocol: String?)
        case didClose(code: URLSessionWebSocketTask.CloseCode, reason: Data?)
    }

    @CasePathable
    public enum Message: Equatable {
        struct Unknown: Error {}
        case data(Data)
        case string(String)

        init(_ message: URLSessionWebSocketTask.Message) throws {
            switch message {
            case let .data(data): self = .data(data)
            case let .string(string): self = .string(string)
            @unknown default: throw Unknown()
            }
        }
    }

    public var open: @Sendable (ID, URL, [String]) async -> AsyncStream<Action>
    public var receive: @Sendable (ID) async throws -> AsyncStream<Result<Message, Error>>
    public var send: @Sendable (ID, URLSessionWebSocketTask.Message) async throws -> Void
    public var sendPing: @Sendable (ID) async throws -> Void
}


