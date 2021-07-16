//
//  MapData+Center.swift
//
//
//  Created by Thomas Hack on 12.07.21.
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