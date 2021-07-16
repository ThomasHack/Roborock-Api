//
//  MapData+Path.swift
// 
//
//  Created by Thomas Hack on 29.06.21.
//

import Foundation

extension MapData {
    public struct Path: Equatable {
        public var currentAngle: Int
        public var points: [Point]
        public var type: PathType

        public init(currentAngle: Int, points: [Point], type: PathType) {
            self.currentAngle = currentAngle
            self.points = points
            self.type = type
        }
    }
}