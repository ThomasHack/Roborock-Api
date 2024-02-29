//
//  RobotInfo.swift
//
//
//  Created by Hack, Thomas on 24.02.24.
//

import Foundation

public struct RobotInfo: Equatable, Decodable {
    public var manufacturer: String
    public var modelName: String
    public var modelDetails: ModelDetails
    public var implementation: String

    public struct ModelDetails: Equatable, Decodable {
        public var supportedAttachments: [SupportedAttachments]

        public enum SupportedAttachments: String, Decodable {
            case watertank
            case mop
        }
    }
}
