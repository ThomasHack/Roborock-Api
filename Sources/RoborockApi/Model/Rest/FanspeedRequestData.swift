//
//  FanspeedRequestData.swift
//
//

import Foundation

public struct FanspeedRequestData: Codable {
    public var speed: Int

    enum CodingKeys: String, CodingKey {
        case speed
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.speed = try container.decode(Int.self, forKey: .speed)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(speed, forKey: .speed)
    }

    public init(speed: Int) {
        self.speed = speed
    }
}
