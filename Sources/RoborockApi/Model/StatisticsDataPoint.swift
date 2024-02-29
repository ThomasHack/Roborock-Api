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

    public enum DataPointType: String, Decodable {
        case time
        case area
    }
}
