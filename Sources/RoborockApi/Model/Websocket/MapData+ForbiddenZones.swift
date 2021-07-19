//
//  MapData+ForbiddenZones.swift
//
//

import Foundation

extension MapData {
    public struct ForbiddenZones: Equatable {
        public var count: Int
        public var zones: [[Point]]

        public init(count: Int, zones: [[Point]]) {
            self.count = count
            self.zones = zones
        }
    }
}
