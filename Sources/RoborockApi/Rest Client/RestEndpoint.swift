//
//  Endpoint.swift
//
//  https://www.swiftbysundell.com/articles/creating-generic-networking-apis-in-swift/

import Foundation

public typealias HttpHeaders = [String: String]

public struct RestEndpoint<Response: Decodable>: Equatable {
    var path: String
    var httpMethod: HttpMethod
    var headers: HttpHeaders?
    var body: Data?
    var queryItems: [URLQueryItem]?
}

extension RestEndpoint {
    func makeRequest(with baseUrl: URL) -> URLRequest? {
        guard var components = URLComponents(url: baseUrl, resolvingAgainstBaseURL: false) else { return nil }
        components.path = "/api/v2/" + path
        components.queryItems = queryItems

        guard let url = components.url else { return nil }
        
        var request = URLRequest(url: url)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpMethod = httpMethod.rawValue
        request.httpBody = body
        return request
    }
    func makeStreamRequest(with baseUrl: URL) -> URLRequest? {
        guard var components = URLComponents(url: baseUrl, resolvingAgainstBaseURL: false) else { return nil }
        components.path = "/api/v2/" + path
        components.queryItems = queryItems

        guard let url = components.url else { return nil }

        return URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
    }
}

extension RestEndpoint where Response == RobotInfo {
    static var info: Self {
        RestEndpoint(path: "robot", httpMethod: .get)
    }
}

extension RestEndpoint where Response == RobotState {
    static var stateStream: Self {
        RestEndpoint(path: "robot/state/sse", httpMethod: .get)
    }
    static var state: Self {
        RestEndpoint(path: "robot/state", httpMethod: .get)
    }
}

extension RestEndpoint where Response == [StateAttribute] {
    static var stateAttributesStream: Self {
        RestEndpoint(path: "robot/state/attributes/sse", httpMethod: .get)
    }
    static var stateAttributes: Self {
        RestEndpoint(path: "robot/state/attributes", httpMethod: .get)
    }
}

extension RestEndpoint where Response == Map {
    static var mapStream: Self {
        RestEndpoint(path: "robot/state/map/sse", httpMethod: .get)
    }
    static var map: Self {
        RestEndpoint(path: "robot/state/map", httpMethod: .get)
    }
}

extension RestEndpoint where Response == [StatisticsDataPoint] {
    static var currentStatistics: Self {
        RestEndpoint(path: "robot/capabilities/CurrentStatisticsCapability", httpMethod: .get)
    }
    static var totalStatistics: Self {
        RestEndpoint(path: "robot/capabilities/TotalStatisticsCapability", httpMethod: .get)
    }
}

extension RestEndpoint where Response == [FanSpeedControlPreset] {
    static var fanSpeedControl: Self {
        RestEndpoint(path: "robot/capabilities/FanSpeedControlCapability/preset", httpMethod: .get)
    }
}

extension RestEndpoint where Response == [WaterUsageControlPreset] {
    static var waterUsageControl: Self {
        RestEndpoint(path: "robot/capabilities/WaterUsageControlCapability/preset", httpMethod: .get)
    }
}

extension RestEndpoint where Response == [Segment] {
    static var mapSegments: Self {
        RestEndpoint(path: "robot/capabilities/MapSegmentationCapability", httpMethod: .get)
    }
}

extension RestEndpoint {
    static func basicControl(_ body: Data) -> Self {
        RestEndpoint(path: "robot/capabilities/BasicControlCapability", httpMethod: .put, body: body)
    }
    static func fanSpeedControl(_ body: Data) -> Self {
        RestEndpoint(path: "robot/capabilities/FanSpeedControlCapability/preset", httpMethod: .put, body: body)
    }

    static func waterUsageControl(_ body: Data) -> Self {
        RestEndpoint(path: "robot/capabilities/WaterUsageControlCapability/presets", httpMethod: .put, body: body)
    }
    static func cleanSegments(_ body: Data) -> Self {
        RestEndpoint(path: "robot/capabilities/MapSegmentationCapability", httpMethod: .put, body: body)
    }
}
