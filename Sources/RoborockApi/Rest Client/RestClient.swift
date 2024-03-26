//
//  RestClient.swift
//
//  https://github.com/rand256/valetudo/wiki/REST-API

import Combine
import ComposableArchitecture
import Foundation

public struct RestClient {
    public struct ID: Hashable, @unchecked Sendable {
        let rawValue: AnyHashable

        init<RawValue: Hashable & Sendable>(_ rawValue: RawValue) {
            self.rawValue = rawValue
        }

        public init() {
            struct RawValue: Hashable, Sendable {}
            self.rawValue = RawValue()
        }
    }

    public var connect: (ID, URL) async throws -> Void
    public var fetchInfo: (ID) async throws -> RobotInfo
    public var fetchState: (ID) async throws -> RobotState
    public var fetchStateAttributes: (ID) async throws -> [StateAttribute]
    public var fetchCurrentStatistics: (ID) async throws -> [StatisticsDataPoint]
    public var fetchTotalStatistics: (ID) async throws -> [StatisticsDataPoint]
    public var fetchMap: (ID) async throws -> Map
    public var fetchSegments: (ID) async throws -> [Segment]
    public var cleanSegments: (_ id: ID, _ segments: [Segment]) async throws -> Bool
    public var stopCleaning: (ID) async throws -> Bool
    public var pauseCleaning: (ID) async throws -> Bool
    public var driveHome: (ID) async throws -> Bool
    public var controlFanSpeed: (_ id: ID, _ preset: FanSpeedControlPreset) async throws -> Bool
    public var controlWaterUsage: (_ id: ID, _ preset: WaterUsageControlPreset) async throws -> Bool
}

extension RestClient: DependencyKey {
    private static let urlSession = URLSession(configuration: .default,
                                               delegate: RestClientDelegate(),
                                               delegateQueue: nil)
    private static var baseUrl: URL?

    public static var liveValue: Self {
        return Self(
            connect: { id, url in
                baseUrl = url
                return await RestClientActor.shared.connect(id: id)
            },
            fetchInfo: { id in
                return try await RestClientActor.shared.request(id: id, with: baseUrl, and: .info)
            },
            fetchState: { id in
                return try await RestClientActor.shared.request(id: id, with: baseUrl, and: .state)
            },
            fetchStateAttributes: { id in
                return try await RestClientActor.shared.request(id: id, with: baseUrl, and: .stateAttributes)
            },
            fetchCurrentStatistics: { id in
                return try await RestClientActor.shared.request(id: id, with: baseUrl, and: .currentStatistics)
            },
            fetchTotalStatistics: { id in
                return try await RestClientActor.shared.request(id: id, with: baseUrl, and: .totalStatistics)
            },
            fetchMap: { id in
                return try await RestClientActor.shared.request(id: id, with: baseUrl, and: .map)
            },
            fetchSegments: { id in
                return try await RestClientActor.shared.request(id: id, with: baseUrl, and: .mapSegments)
            },
            cleanSegments: { id, segments in
                let request = MapSegmentsRequest(segmentIds: segments.map { $0.id }, iterations: 1)
                let data = try JSONEncoder().encode(request)
                return try await RestClientActor.shared.request(id: id, with: baseUrl, and: .cleanSegments(data))
            },
            stopCleaning: { id in
                let request = BasicControlAction(action: .stop)
                let data = try JSONEncoder().encode(request)
                return try await RestClientActor.shared.request(id: id, with: baseUrl, and: .basicControl(data))
            },
            pauseCleaning: { id in
                let request = BasicControlAction(action: .pause)
                let data = try JSONEncoder().encode(request)
                return try await RestClientActor.shared.request(id: id, with: baseUrl, and: .basicControl(data))
            },
            driveHome: { id in
                let request = BasicControlAction(action: .home)
                let data = try JSONEncoder().encode(request)
                return try await RestClientActor.shared.request(id: id, with: baseUrl, and: .basicControl(data))
            },
            controlFanSpeed: {id,  preset in
                let request = FanSpeedControl(name: preset)
                let data = try JSONEncoder().encode(request)
                return try await RestClientActor.shared.request(id: id, with: baseUrl, and: .fanSpeedControl(data))
            },
            controlWaterUsage: {id, preset in
                let request = WaterUsageControl(name: preset)
                let data = try JSONEncoder().encode(request)
                return try await RestClientActor.shared.request(id: id, with: baseUrl, and: .waterUsageControl(data))
            }
        )

        final actor RestClientActor: GlobalActor {
            typealias Dependencies = (session: URLSession, delegate: RestClientDelegate)

            static let shared = RestClientActor()

            var dependencies: [ID: Dependencies] = [:]

            func connect(id: ID) {
                let delegate = RestClientDelegate()
                let urlSession = URLSession(configuration: .default, delegate: delegate, delegateQueue: .main)
                self.dependencies[id] = (urlSession, delegate)
            }

            func request(id: ID, with baseUrl: URL?, and endpoint: RestEndpoint<Bool>) async throws -> Bool {
                return try await self.urlSession(id: id).request(with: baseUrl, and: endpoint)
            }

            func request<Response: Decodable>(id: ID, with baseUrl: URL?, and endpoint: RestEndpoint<Response>) async throws -> Response {
                return try await self.urlSession(id: id).request(with: baseUrl, and: endpoint)
            }

            func close(id: ID) async throws {
                defer { self.dependencies[id] = nil }
                try self.urlSession(id: id).invalidateAndCancel()
            }

            private func urlSession(id: ID) throws -> URLSession {
                guard let dependencies = self.dependencies[id]?.session else {
                    struct Closed: Error {}
                    throw Closed()
                }
                return dependencies
            }

            private func removeDependencies(id: ID) {
                self.dependencies[id] = nil
            }
        }
    }
}

extension URLSession {
    func request(with baseUrl: URL?, and endpoint: RestEndpoint<Bool>) async throws -> Bool {
        guard let baseUrl = baseUrl else {
            throw RestClientError.missingBaseUrl
        }
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

    func request<Response: Decodable>(with baseUrl: URL?, and endpoint: RestEndpoint<Response>) async throws -> Response {
        guard let baseUrl = baseUrl else {
            throw RestClientError.missingBaseUrl
        }
        guard let request = endpoint.makeRequest(with: baseUrl) else {
            throw RestClientError.invalidEndpoint
        }
        
        for try await (data, _) in dataTaskPublisher(for: request).values {
            return try JSONDecoder().decode(Response.self, from: data)
        }
        throw RestClientError.invalidResponseData
    }
}
