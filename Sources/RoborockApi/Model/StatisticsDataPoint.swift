//
//  StatisticsDataPoint.swift
//  
//
//  Created by Hack, Thomas on 24.02.24.
//

import Foundation

public struct StatisticsDataPoint: Equatable, Decodable {
    public var type: DataPointType
    public var value: Int

    public init(type: DataPointType, value: Int) {
        self.type = type
        self.value = value
    }

    public enum DataPointType: String, Decodable {
        case time
        case area
        case count
    }
}
