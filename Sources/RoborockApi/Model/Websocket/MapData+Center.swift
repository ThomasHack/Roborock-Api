//
//  MapData+Center.swift
//
//

import Foundation

extension MapData {
    public struct Center: Equatable {
        public var position: Point
        public var count: Int

        public init(position: Point, count: Int) {
            self.position = position
            self.count = count
        }
    }
}
