//
//  Endpoint.swift
//
//  https://www.swiftbysundell.com/articles/creating-generic-networking-apis-in-swift/

import Foundation

public typealias HttpHeaders = [String: String]

public struct Endpoint<Response: Decodable>: Equatable {
    var path: String
    var httpMethod: HttpMethod
    var headers: HttpHeaders?
    var body: Data?
    var queryItems: [URLQueryItem]?
}

extension Endpoint {
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

extension Endpoint where Response == RobotState {
    static var stateStream: Self {
        Endpoint(path: "robot/state/sse", httpMethod: .get)
    }
    static var state: Self {
        Endpoint(path: "robot/state", httpMethod: .get)
    }
}

extension Endpoint where Response == [StateAttribute] {
    static var stateAttributesStream: Self {
        Endpoint(path: "robot/state/attributes/sse", httpMethod: .get)
    }
    static var stateAttributes: Self {
        Endpoint(path: "robot/state/attributes", httpMethod: .get)
    }
}

extension Endpoint where Response == Map {
    static var mapStream: Self {
        Endpoint(path: "robot/state/map/sse", httpMethod: .get)
    }
    static var map: Self {
        Endpoint(path: "robot/state/map", httpMethod: .get)
    }
}

extension Endpoint where Response == [StatisticsDataPoint] {
    static var currentStatistics: Self {
        Endpoint(path: "robot/capabilities/CurrentStatisticsCapability", httpMethod: .get)
    }
    static var totalStatistics: Self {
        Endpoint(path: "robot/capabilities/TotalStatisticsCapability", httpMethod: .get)
    }
}

extension Endpoint where Response == [FanSpeedControlPreset] {
    static var fanSpeedControl: Self {
        Endpoint(path: "robot/capabilities/FanSpeedControlCapability/preset", httpMethod: .get)
    }
}

extension Endpoint where Response == [WaterUsageControlPreset] {
    static var waterUsageControl: Self {
        Endpoint(path: "robot/capabilities/WaterUsageControlCapability/preset", httpMethod: .get)
    }
}

extension Endpoint where Response == [Segment] {
    static var mapSegments: Self {
        Endpoint(path: "robot/capabilities/MapSegmentationCapability", httpMethod: .get)
    }
}

extension Endpoint {
    static func basicControl(_ body: Data) -> Self {
        Endpoint(path: "robot/capabilities/BasicControlCapability", httpMethod: .put, body: body)
    }
    static func fanSpeedControl(_ body: Data) -> Self {
        Endpoint(path: "robot/capabilities/FanSpeedControlCapability/preset", httpMethod: .put, body: body)
    }

    static func waterUsageControl(_ body: Data) -> Self {
        Endpoint(path: "robot/capabilities/WaterUsageControlCapability/presets", httpMethod: .put, body: body)
    }
    static func cleanSegments(_ body: Data) -> Self {
        Endpoint(path: "robot/capabilities/MapSegmentationCapability", httpMethod: .put, body: body)
    }
}
