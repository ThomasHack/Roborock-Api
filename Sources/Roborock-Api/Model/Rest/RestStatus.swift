//
//  File.swift
//  
//
//  Created by Hack, Thomas on 14.07.21.
//

import Foundation

public struct RestStatus: Equatable, Decodable {
    public var messageVersion: Int
    public var state: Int
    public var battery: Int
    public var cleanTime: Int
    public var cleanArea: Int
    public var errorCode: Int
    public var mapPresent: Int
    public var inCleaning: Int
    public var inReturning: Int
    public var inFreshState: Int
    public var labStatus: Int
    public var waterBoxStatus: Int
    public var fanPower: Int
    public var dndEnabled: Int
    public var mapStatus: Int
    public var lockStatus: Int
    public var humanState: String
    public var humanError: String
    public var model: String

    enum CodingKeys: String, CodingKey {
        case messageVersion = "msg_ver"
        case state = "state"
        case battery = "battery"
        case cleanTime = "clean_time"
        case cleanArea = "clean_area"
        case errorCode = "error_code"
        case mapPresent = "map_present"
        case inCleaning = "in_cleaning"
        case inReturning = "in_returning"
        case inFreshState = "in_fresh_state"
        case labStatus = "lab_status"
        case waterBoxStatus = "water_box_status"
        case fanPower = "fan_power"
        case dndEnabled = "dnd_enabled"
        case mapStatus = "map_status"
        case lockStatus = "lock_status"
        case humanState = "human_state"
        case humanError = "human_error"
        case model = "model"
    }

    public init(messageVersion: Int, state: Int, battery: Int, cleanTime: Int, cleanArea: Int, errorCode: Int, mapPresent: Int, inCleaning: Int, inReturning: Int, inFreshState: Int, labStatus: Int, waterBoxStatus: Int, fanPower: Int, dndEnabled: Int, mapStatus: Int, lockStatus: Int, humanState: String, humanError: String, model: String) {
        self.messageVersion = messageVersion
        self.state = state
        self.battery = battery
        self.cleanTime = cleanTime
        self.cleanArea = cleanArea
        self.errorCode = errorCode
        self.mapPresent = mapPresent
        self.inCleaning = inCleaning
        self.inReturning = inReturning
        self.inFreshState = inFreshState
        self.labStatus = labStatus
        self.waterBoxStatus = waterBoxStatus
        self.fanPower = fanPower
        self.dndEnabled = dndEnabled
        self.mapStatus = mapStatus
        self.lockStatus = lockStatus
        self.humanState = humanState
        self.humanError = humanError
        self.model = model
    }
}
