//
//  MapData+Segments.swift
//
//

import Foundation

extension MapData {
    public struct Segments: Equatable {
        public var count: Int
        public var center: [Int: Center]

        public init(count: Int, center: [Int: Center]) {
            self.count = count
            self.center = center
        }
    }
}
