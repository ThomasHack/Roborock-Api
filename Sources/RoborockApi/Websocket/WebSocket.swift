//
//  WebSocket.swift
//  Websocket-Test
//
//  Created by Hack, Thomas on 28.07.23.
//

import ComposableArchitecture
import Foundation

public enum ConnectivityState {
    case connected
    case connecting
    case disconnected
}

@Reducer
public struct WebSocket {
    @Dependency(\.continuousClock) var clock
    @Dependency(\.webSocketClient) var webSocketClient

    public init() {}

    public struct State: Equatable {
        public var connectivityState = ConnectivityState.disconnected

        public init() {}
    }

    @CasePathable
    public enum Action: Equatable {
        case connect(URL)
        case disconnect
        case receivedSocketMessage(WebSocketClient.Message)
        case sendButtonTapped
        case webSocketClient(WebSocketClient.Action)
    }

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .connect(let url):
                state.connectivityState = .connecting
                return .run { send in
                    let actions = await self.webSocketClient.open(WebSocketClient.ID(), url, ["wss"])

                    await withThrowingTaskGroup(of: Void.self) { group in
                        for await action in actions {
                            group.addTask {
                                await send(.webSocketClient(action))
                            }

                            switch action {
                            case .didOpen:
                                group.addTask {
                                    while !Task.isCancelled {
                                        try await self.clock.sleep(for: .seconds(10))
                                        try? await self.webSocketClient.sendPing(WebSocketClient.ID())
                                    }
                                }
                                group.addTask {
                                    for await result in try await self.webSocketClient.receive(WebSocketClient.ID()) {
                                        switch result {
                                        case .success(let message):
                                            await send(.receivedSocketMessage(message))
                                        case .failure(let error):
                                            print(error.localizedDescription)
                                        }
                                    }
                                }

                            case .didClose:
                                return
                            }
                        }
                    }
                }
                .cancellable(id: WebSocketClient.ID())

            case .disconnect:
                state.connectivityState = .disconnected
                return .cancel(id: WebSocketClient.ID())

            case .receivedSocketMessage:
                break

            case .sendButtonTapped:
                return .run { _ in
                    // try await self.webSocket.send(WebSocketClient.ID(), .string(messageToSend))
                } catch: { _, _ in
                }
                .cancellable(id: WebSocketClient.ID())

            case .webSocketClient(.didClose):
                state.connectivityState = .disconnected
                return .cancel(id: WebSocketClient.ID())

            case .webSocketClient(.didOpen):
                state.connectivityState = .connected
            }
            return .none
        }
    }
}
