//
//  File.swift
//  
//
//  Created by Hack, Thomas on 24.02.24.
//

import Foundation

public enum WaterUsageControlPreset: String, Codable, CaseIterable {
    case off
    case low
    case medium
    case high
}

public struct WaterUsageControl: Equatable, Codable {
    public var name: WaterUsageControlPreset

    public init(name: WaterUsageControlPreset) {
        self.name = name
    }
}
