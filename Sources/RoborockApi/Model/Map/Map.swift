//
//  Map.swift
//  
//
//  Created by Hack, Thomas on 24.02.24.
//

import CoreGraphics
import Foundation

public struct Map: Equatable, Decodable {
    public var size: Size
    public var pixelSize: Int
    public var layers: [Layer]
    public var entities: [Entity]
    public var metaData: MetaData

    public var calculatedDimensions: Dimensions {
        var dimensions = Dimensions()
        for layer in layers {
            dimensions.min.x = min(CGFloat(layer.dimensions.x.min), dimensions.min.x)
            dimensions.max.x = max(CGFloat(layer.dimensions.x.max), dimensions.max.x)
            dimensions.min.y = min(CGFloat(layer.dimensions.y.min), dimensions.min.y)
            dimensions.max.y = max(CGFloat(layer.dimensions.y.max), dimensions.max.y)
        }

        dimensions.sum.width = (dimensions.max.x - dimensions.min.x + 1)
        dimensions.sum.height = (dimensions.max.y - dimensions.min.y + 1)
        return dimensions
    }

    public struct Size: Equatable, Decodable {
        public var x: Int
        public var y: Int

        public var cgSize: CGSize {
            return CGSize(width: x, height: y)
        }
    }

    public struct MetaData: Equatable, Decodable {
        public var vendorMapId: Int
        public var version: Int
        public var nonce: String
        public var totalLayerArea: Int
    }

    public struct Dimensions: Equatable {
        public var min: CGPoint
        public var max: CGPoint
        public var sum: CGSize

        public init(min: CGPoint = CGPoint(x: CGFloat.infinity, y: CGFloat.infinity), max: CGPoint = .zero, sum: CGSize = .zero) {
            self.min = min
            self.max = max
            self.sum = sum
        }
    }
}
