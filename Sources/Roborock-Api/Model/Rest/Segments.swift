//
//  Segment.swift
// 
//
//  Created by Thomas Hack on 08.05.21.
//

import Foundation

public struct Segments: Equatable, Decodable, Hashable {
    public let data: [Segment]

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        data = try container.decode([Segment].self)
    }

    public init(segment: [Segment]) {
        self.data = segment
    }
}
