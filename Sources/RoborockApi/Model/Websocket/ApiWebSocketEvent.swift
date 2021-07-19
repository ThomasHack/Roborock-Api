//
//  ApiWebSocketEvent.swift
//
//

import Foundation

public enum ApiWebSocketEvent: Equatable {
    case connected
    case disconnected
    case text(String)
    case binary(Data)
    case ping
    case pong
    // case viabilityChanged
    // reconnectSuggested
    case cancelled
    case error(NSError?)
}
