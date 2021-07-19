//
//  Segment.swift
//
//

import Foundation

public struct Segment: Equatable, Decodable, Hashable {
    public let id: Int
    public let name: String

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.id = try container.decode(Int.self)
        self.name = try container.decode(String.self)
    }

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}
