//
//  Map+Layer.swift
//  
//
//  Created by Hack, Thomas on 24.02.24.
//

import UIKit

extension Map {
    public struct Layer: Equatable, Decodable {
        public var dimensions: Dimensions
        public var compressedPixels: [Int]
        public var metaData: MetaData
        public var type: LayerType

        public var pixels: [CGPoint] = []

        enum CodingKeys: CodingKey {
            case dimensions
            case compressedPixels
            case metaData
            case type
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.dimensions = try container.decode(Dimensions.self, forKey: .dimensions)
            self.compressedPixels = try container.decode([Int].self, forKey: .compressedPixels)
            self.metaData = try container.decode(MetaData.self, forKey: .metaData)
            self.type = try container.decode(LayerType.self, forKey: .type)

            for i in stride(from: 0, to: compressedPixels.count, by: 3) {
                let xStart = compressedPixels[i]
                let y = compressedPixels[i+1]
                let count = compressedPixels[i+2]

                for j in 0..<count {
                    let point = CGPoint(x: xStart + j, y: y)
                    pixels.append(point)
                }
            }
        }

        public struct MetaData: Equatable, Decodable {
            // public var area: Int
            public var segmentId: String?
            public var active: Bool?
        }

        public enum LayerType: String, Equatable, Codable {
            case floor
            case wall
            case segment
        }

        public struct Dimensions: Equatable, Decodable {
            public var x: Dimension
            public var y: Dimension
            public var pixelCount: Int

            public var min: CGPoint {
                CGPoint(x: x.min, y: y.min)
            }

            public var max: CGPoint {
                CGPoint(x: x.max, y: y.max)
            }

            public var mid: CGPoint {
                CGPoint(x: x.mid, y: y.mid)
            }

            public var avg: CGPoint {
                CGPoint(x: x.avg, y: y.avg)
            }
        }

        public struct Dimension: Equatable, Decodable {
            public var min: Int
            public var max: Int
            public var mid: Int
            public var avg: Int
        }

        public struct Pixel: Equatable, Decodable {
            public var x: Int
            public var y: Int

            public init(x: Int, y: Int) {
                self.x = x
                self.y = y
            }
        }
    }
}
