//
//  ResponseString.swift
//
//

import Foundation

public struct ResponseString: Equatable, Decodable {
    var message: String

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.message = try container.decode(String.self)
    }
}

public struct StatusUpdate: Decodable {
    public let status: Status

    enum CodingKeys: String, CodingKey {
        case status
    }
}
