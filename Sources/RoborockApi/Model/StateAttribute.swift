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

    public init(type: AttributeType, data: Attribute) {
        self.type = type
        self.data = data
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

    public struct AttachmentStateAttribute: Decodable, Equatable, Identifiable, Hashable {
        public let id: UUID
        public var type: AttachmentType
        public var attached: Bool

        enum CodingKeys: CodingKey {
            case type
            case attached
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = UUID()
            self.type = try container.decode(AttachmentType.self, forKey: .type)
            self.attached = try container.decode(Bool.self, forKey: .attached)
        }

        public init(type: AttachmentType, attached: Bool) {
            self.id = UUID()
            self.type = type
            self.attached = attached
        }

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

    public enum OperationModePreset: Decodable {
        case vacuum, mop, vacuum_and_mop
    }

    public struct PresetSelectionStateAttribute: Decodable, Equatable {
        public var type: PresetType
        public var value: PresetValue

        public init(type: PresetType, value: PresetValue) {
            self.type = type
            self.value = value
        }

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

        public init(level: Int, flag: StatusFlag) {
            self.level = level
            self.flag = flag
        }

        public enum StatusFlag: String, Decodable {
            case none, charging, discharging, charged
        }
    }

    public struct ConsumableStateAttribute: Decodable, Equatable {
        public var type: String
        public var subType: String
        public var remaining: Remaining

        public init(type: String, subType: String, remaining: Remaining) {
            self.type = type
            self.subType = subType
            self.remaining = remaining
        }

        public struct Remaining: Decodable, Equatable {
            public var value: Int
            public var unit: Unit

            public enum Unit: String, Decodable {
                case percent, minutes
            }
        }
    }
}
