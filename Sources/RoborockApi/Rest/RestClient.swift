//
//  RestClient.swift
//
//  https://github.com/rand256/valetudo/wiki/REST-API

import Combine
import Foundation

public struct RestClient {
    public var connect: (URL) -> Void
    public var fetchStatus: () async throws -> RestStatus
    public var fetchSegments: () async throws -> Segments
    public var cleanSegments: (_ segments: SegmentsRequestData) async throws -> ResponseString
    public var stopCleaning: () async throws -> ResponseString
    public var pauseCleaning: () async throws -> ResponseString
    public var driveHome: () async throws -> ResponseString
    public var setFanspeed: (_ fanspeed: FanspeedRequestData) async throws -> ResponseString
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
        fetchStatus: {
            return try await urlSession.publisher(with: baseUrl, and: .currentStatus)
        },
        fetchSegments: {
            return try await urlSession.publisher(with: baseUrl, and: .segmentNames)
        },
        cleanSegments: { segments in
            let data = try JSONEncoder().encode(segments)
            return try await urlSession.publisher(with: baseUrl, and: .cleanSegments(data))
        },
        stopCleaning: {
            return try await urlSession.publisher(with: baseUrl, and: .stopCleaning)
        },
        pauseCleaning: {
            return try await urlSession.publisher(with: baseUrl, and: .pauseCleaning)
        },
        driveHome: {
            return try await urlSession.publisher(with: baseUrl, and: .driveHome)
        },
        setFanspeed: { fanspeed in
            do {
                let data = try JSONEncoder().encode(fanspeed)
                return try await urlSession.publisher(with: baseUrl, and: .setFanSpeed(data))
            } catch {
                throw RestClientError.invalidRequestData
            }
        })
}

extension URLSession {
    func publisher<Response: Decodable>(with baseUrl: URL, and endpoint: Endpoint<Response>) async throws -> Response {
        guard let request = endpoint.makeRequest(with: baseUrl) else {
            throw RestClientError.invalidEndpoint
        }
        
        for try await (data, _) in dataTaskPublisher(for: request).values {
            return try JSONDecoder().decode(Response.self, from: data)
        }
        throw RestClientError.invalidResponseData
    }
}
