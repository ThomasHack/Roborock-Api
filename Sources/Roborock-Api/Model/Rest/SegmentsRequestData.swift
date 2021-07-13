//
//  File.swift
//  
//
//  Created by Hack, Thomas on 13.07.21.
//

import Foundation

public struct SegmentsRequestData: Codable {
    public var segments: [Int]
    public var repeats: Int
    public var order: Int

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.segments = try container.decode([Int].self)
        self.repeats = try container.decode(Int.self)
        self.order = try container.decode(Int.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(segments)
        try container.encode(repeats)
        try container.encode(order)
    }

    public init(segments: [Int], repeats: Int, order: Int) {
        self.segments = segments
        self.repeats = repeats
        self.order = order
    }
}
