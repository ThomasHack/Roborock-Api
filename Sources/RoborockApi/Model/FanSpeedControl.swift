//
//  File.swift
//  
//
//  Created by Hack, Thomas on 24.02.24.
//

import Foundation

public enum FanSpeedControlPreset: String, Codable, CaseIterable {
    case off
    case low
    case medium
    case high
    case max
}

public struct FanSpeedControl: Equatable, Codable {
    public var name: FanSpeedControlPreset

    public init(name: FanSpeedControlPreset) {
        self.name = name
    }
}
