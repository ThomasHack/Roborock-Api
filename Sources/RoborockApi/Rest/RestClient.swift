//
//  RestClient.swift
//
//  https://github.com/rand256/valetudo/wiki/REST-API

import Combine
import Foundation

public struct RestClient {
    public var connect: (URL) -> Void
    public var fetchStatus: () -> AnyPublisher<RestStatus, RestClientError>
    public var fetchSegments: () -> AnyPublisher<Segments, RestClientError>
    public var cleanSegments: (_ segments: SegmentsRequestData) -> AnyPublisher<ResponseString, RestClientError>
    public var stopCleaning: () -> AnyPublisher<ResponseString, RestClientError>
    public var pauseCleaning: () -> AnyPublisher<ResponseString, RestClientError>
    public var driveHome: () -> AnyPublisher<ResponseString, RestClientError>
    public var setFanspeed: (_ fanspeed: FanspeedRequestData) -> AnyPublisher<ResponseString, RestClientError>
}

extension RestClient {
    private static let urlSession = URLSession(configuration: .default,
                                               delegate: RestClientURLSessionDelegate(),
                                               delegateQueue: nil)
    private static var baseUrl = URL(string: "http://example.org")!

    public static let live = RestClient(
        connect: { url in
            baseUrl = url
        },
        fetchStatus: {
            return urlSession.publisher(with: baseUrl, and: .currentStatus)
        },
        fetchSegments: {
            return urlSession.publisher(with: baseUrl, and: .segmentNames)
        },
        cleanSegments: { segments in
            do {
                let data = try JSONEncoder().encode(segments)
                return urlSession.publisher(with: baseUrl, and: .cleanSegments(data))
            } catch {
                return Fail(error: RestClientError.invalidRequestData)
                    .eraseToAnyPublisher()
            }
        },
        stopCleaning: {
            return urlSession.publisher(with: baseUrl, and: .stopCleaning)
        },
        pauseCleaning: {
            return urlSession.publisher(with: baseUrl, and: .pauseCleaning)
        },
        driveHome: {
            return urlSession.publisher(with: baseUrl, and: .driveHome)
        },
        setFanspeed: { fanspeed in
            do {
                let data = try JSONEncoder().encode(fanspeed)
                return urlSession.publisher(with: baseUrl, and: .setFanSpeed(data))
            } catch {
                return Fail(error: RestClientError.invalidRequestData)
                    .eraseToAnyPublisher()
            }
        })
}

extension URLSession {
    func publisher<Response: Decodable>(with baseUrl: URL, and endpoint: Endpoint<Response>) -> AnyPublisher<Response, RestClientError> {
        guard let request = endpoint.makeRequest(with: baseUrl) else {
            return Fail(error: RestClientError.invalidEndpoint)
                .eraseToAnyPublisher()
        }
        
        return dataTaskPublisher(for: request)
            .map{ data, _ in data }
            .decode(type: Response.self, decoder: JSONDecoder())
            .mapError{ error in RestClientError.invalidResponseData }
            .eraseToAnyPublisher()
    }
}
