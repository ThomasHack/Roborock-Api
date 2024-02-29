//
//  Map+Entity.swift
//  
//
//  Created by Hack, Thomas on 24.02.24.
//

import UIKit

extension Map {
    public struct Entity: Equatable, Decodable {
        public var compressedPoints: [Int]
        public var metaData: MetaData
        public var type: EntityType

        public var points: [CGPoint] = []

        enum CodingKeys: String, CodingKey {
            case compressedPoints = "points"
            case metaData
            case type
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.compressedPoints = try container.decode([Int].self, forKey: .compressedPoints)
            self.metaData = try container.decode(MetaData.self, forKey: .metaData)
            self.type = try container.decode(EntityType.self, forKey: .type)

            for i in stride(from: 0, to: compressedPoints.count, by: 2) {
                let point = CGPoint(x: compressedPoints[i], y: compressedPoints[i + 1])
                points.append(point)
            }
        }

        public struct MetaData: Equatable, Decodable {
            public var angle: Int?

            public init(angle: Int? = nil) {
                self.angle = angle
            }
        }

        public enum EntityType: String, Equatable, Codable {
            case activeZone = "active_zone"
            case chargerLocation = "charger_location"
            case goToTarget = "go_to_target"
            case noGoArea = "no_go_area"
            case noMopArea = "no_mop_area"
            case path = "path"
            case predictedPath = "predicted_path"
            case robotPosition = "robot_position"
            case virtualWall = "virtual_wall"
        }

        public struct Point: Equatable, Decodable {
            public var x: Int
            public var y: Int

            public var cgPoint: CGPoint {
                return CGPoint(x: y, y: y)
            }

            public init(x: Int, y: Int) {
                self.x = x
                self.y = y
            }
        }
    }
}
