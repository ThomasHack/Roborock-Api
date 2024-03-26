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

    public init(manufacturer: String, modelName: String, modelDetails: ModelDetails, implementation: String) {
        self.manufacturer = manufacturer
        self.modelName = modelName
        self.modelDetails = modelDetails
        self.implementation = implementation
    }

    public struct ModelDetails: Equatable, Decodable {
        public var supportedAttachments: [SupportedAttachments]

        public init(supportedAttachments: [SupportedAttachments]) {
            self.supportedAttachments = supportedAttachments
        }

        public enum SupportedAttachments: String, Decodable {
            case watertank
            case mop
        }
    }
}
