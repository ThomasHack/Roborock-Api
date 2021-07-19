//
//  MapData+RobotPosition.swift
//
//

import Foundation

extension MapData {
    public struct RobotPosition: Equatable {
        public var position: Point
        public var angle: Int?

        public init(position: Point, angle: Int? = nil) {
            self.position = position
            self.angle = angle
        }
    }
}
