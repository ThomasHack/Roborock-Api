//
//  File.swift
//  
//
//  Created by Hack, Thomas on 24.02.24.
//

import Foundation

public struct BasicControlAction: Equatable, Codable {
    var action: Action

    public init(action: Action) {
        self.action = action
    }

    public enum Action: String, Codable {
        case start
        case stop
        case pause
        case home
    }
}
