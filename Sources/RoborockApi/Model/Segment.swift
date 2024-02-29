//
//  Segment.swift
//  
//
//  Created by Hack, Thomas on 24.02.24.
//

import Foundation

public struct Segment: Equatable, Codable, Hashable {
    public var id: String
    public var name: String?

    public init(id: String, name: String? = nil) {
        self.id = id
        self.name = name
    }
}

public struct MapSegmentsRequest: Equatable, Codable {
    public var action: ActionType
    public var segmentIds: [String]
    public var iterations: Int
    public var customOrder: Bool

    public init(action: ActionType = .startSegmentAction, segmentIds: [String], iterations: Int, customOrder: Bool = true) {
        self.action = action
        self.segmentIds = segmentIds
        self.iterations = iterations
        self.customOrder = customOrder
    }

    enum CodingKeys: String, CodingKey {
        case action
        case customOrder = "customOrder"
        case segmentIds = "segment_ids"
        case iterations
    }

    public enum ActionType: String, Codable {
        case startSegmentAction = "start_segment_action"
    }
}
