//
//  MapData+Point.swift
//
//

import Foundation

extension MapData {
    public struct Point: Equatable {
        public var x: Int
        public var y: Int

        public init(x: Int, y: Int) {
            self.x = x
            self.y = y
        }
    }
}
