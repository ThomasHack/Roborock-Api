//
//  MapData+Segments.swift
//
//
//  Created by Thomas Hack on 12.07.21.
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
