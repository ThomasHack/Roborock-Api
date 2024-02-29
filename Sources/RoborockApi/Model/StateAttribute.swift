//
//  StateAttribute.swift
//
//
//  Created by Hack, Thomas on 19.02.24.
//

import Foundation

public struct StateAttribute: Decodable, Equatable {
    public var type: AttributeType
    public var data: Attribute

    enum CodingKeys: String, CodingKey {
        case type = "__class"
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(AttributeType.self, forKey: .type)
        switch type {
        case .attachment:
            let attachment = try AttachmentStateAttribute(from: decoder)
            data = .attachment(attachment)
        case .status:
            let status = try StatusStateAttribute(from: decoder)
            data = .status(status)
        case .preset:
            let preset = try PresetSelectionStateAttribute(from: decoder)
            data = .preset(preset)
        case .battery:
            let battery = try BatteryStateAttribute(from: decoder)
            data = .battery(battery)
        case .consumable:
            let consumable = try ConsumableStateAttribute(from: decoder)
            data = .consumable(consumable)
        }
    }

    public enum AttributeType: String, Decodable, Equatable {
        case attachment = "AttachmentStateAttribute"
        case status = "StatusStateAttribute"
        case preset = "PresetSelectionStateAttribute"
        case battery = "BatteryStateAttribute"
        case consumable = "ConsumableStateAttribute"
    }

    public enum Attribute: Equatable, Decodable {
        case attachment(AttachmentStateAttribute)
        case status(StatusStateAttribute)
        case preset(PresetSelectionStateAttribute)
        case battery(BatteryStateAttribute)
        case consumable(ConsumableStateAttribute)
    }

    public struct AttachmentStateAttribute: Decodable, Equatable {
        public var type: AttachmentType
        public var attached: Bool

        public enum AttachmentType: String, Decodable {
            case dustbin, watertank, mop
        }
    }

    public struct StatusStateAttribute: Decodable, Equatable {
        public var value: Status
        public var flag: StatusFlag

        public init(value: Status, flag: StatusFlag) {
            self.value = value
            self.flag = flag
        }

        public enum Status: String, Decodable {
            case error = "error"
            case docked = "docked"
            case idle = "idle"
            case returning = "returning"
            case cleaning = "cleaning"
            case paused = "paused"
            case manualControl = "manual_control"
            case moving = "moving"
        }

        public enum StatusFlag: String, Decodable {
            case none, zone, segment, spot, target, resumable, mapping
        }
    }

    public struct PresetSelectionStateAttribute: Decodable, Equatable {
        public var type: PresetType
        public var value: PresetValue

        public enum PresetType: String, Decodable {
            case fanSpeed = "fan_speed"
            case waterGrade = "water_grade"
            case operationMode = "operation_mode"
        }

        public enum PresetValue: String, Decodable {
            case off, min, low, medium, high, max, turbo, custom, vacuum, mop, vacuum_and_mop
        }
    }

    public struct BatteryStateAttribute: Decodable, Equatable {
        public var level: Int
        public var flag: StatusFlag

        public enum StatusFlag: String, Decodable {
            case none, charging, discharging, charged
        }
    }

    public struct ConsumableStateAttribute: Decodable, Equatable {
        public var type: String
        public var subType: String
        public var remaining: Remaining

        public struct Remaining: Decodable, Equatable {
            public var value: Int
            public var unit: Unit

            public enum Unit: String, Decodable {
                case percent, minutes
            }
        }
    }
}
