//
//  RestClient.swift
//
//  https://github.com/rand256/valetudo/wiki/REST-API

import Combine
import Foundation

public struct RestClient {
    public var connect: (URL) -> Void
    public var fetchState: () async throws -> RobotState
    public var fetchStateAttributes: () async throws -> [StateAttribute]
    public var fetchCurrentStatistics: () async throws -> [StatisticsDataPoint]
    public var fetchTotalStatistics: () async throws -> [StatisticsDataPoint]
    public var fetchMap: () async throws -> Map
    public var fetchSegments: () async throws -> [Segment]
    public var cleanSegments: (_ segments: [Segment]) async throws -> Bool
    public var stopCleaning: () async throws -> Bool
    public var pauseCleaning: () async throws -> Bool
    public var driveHome: () async throws -> Bool
    public var controlFanSpeed: (_ preset: FanSpeedControlPreset) async throws -> Bool
    public var controlWaterUsage: (_ preset: WaterUsageControlPreset) async throws -> Bool
}

extension RestClient {
    private static let urlSession = URLSession(configuration: .default,
                                               delegate: RoborockURLSessionDelegate(),
                                               delegateQueue: nil)
    private static var baseUrl = URL(string: "http://example.org")!

    public static let live = RestClient(
        connect: { url in
            baseUrl = url
        },
        fetchState: {
            return try await urlSession.request(with: baseUrl, and: .state)
        },
        fetchStateAttributes: {
            return try await urlSession.request(with: baseUrl, and: .stateAttributes)
        },
        fetchCurrentStatistics: {
            return try await urlSession.request(with: baseUrl, and: .currentStatistics)
        },
        fetchTotalStatistics: {
            return try await urlSession.request(with: baseUrl, and: .totalStatistics)
        },
        fetchMap: {
            return try await urlSession.request(with: baseUrl, and: .map)
        },
        fetchSegments: {
            return try await urlSession.request(with: baseUrl, and: .mapSegments)
        },
        cleanSegments: { segments in
            let request = MapSegmentsRequest(segmentIds: segments.map { $0.id }, iterations: 1)
            let data = try JSONEncoder().encode(request)
            return try await urlSession.request(with: baseUrl, and: .cleanSegments(data))
        },
        stopCleaning: {
            let data = try JSONEncoder().encode(BasicControlAction(action: .stop))
            return try await urlSession.request(with: baseUrl, and: .basicControl(data))
        },
        pauseCleaning: {
            let data = try JSONEncoder().encode(BasicControlAction(action: .pause))
            return try await urlSession.request(with: baseUrl, and: .basicControl(data))
        },
        driveHome: {
            let data = try JSONEncoder().encode(BasicControlAction(action: .home))
            return try await urlSession.request(with: baseUrl, and: .basicControl(data))
        },
        controlFanSpeed: { preset in
            let data = try JSONEncoder().encode(FanSpeedControl(name: preset))
            return try await urlSession.request(with: baseUrl, and: .fanSpeedControl(data))
        },
        controlWaterUsage: { preset in
            let data = try JSONEncoder().encode(WaterUsageControl(name: preset))
            return try await urlSession.request(with: baseUrl, and: .waterUsageControl(data))
        }
    )
}

extension URLSession {
    func request(with baseUrl: URL, and endpoint: Endpoint<Bool>) async throws -> Bool {
        guard let request = endpoint.makeRequest(with: baseUrl) else {
            throw RestClientError.invalidEndpoint
        }

        for try await (_, response) in dataTaskPublisher(for: request).values {
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    return true
                } else {
                    throw RestClientError.invalidHttpCode(httpResponse.statusCode)
                }
            }
        }
        throw RestClientError.invalidResponseData
    }

    func request<Response: Decodable>(with baseUrl: URL, and endpoint: Endpoint<Response>) async throws -> Response {
        guard let request = endpoint.makeRequest(with: baseUrl) else {
            throw RestClientError.invalidEndpoint
        }
        
        for try await (data, _) in dataTaskPublisher(for: request).values {
            return try JSONDecoder().decode(Response.self, from: data)
        }
        throw RestClientError.invalidResponseData
    }
}
