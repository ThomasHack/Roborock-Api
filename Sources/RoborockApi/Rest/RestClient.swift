//
//  RestClient.swift
//
//  https://github.com/rand256/valetudo/wiki/REST-API

import Combine
import Foundation

protocol RestClientProtocol {
    func fetchStatus() -> AnyPublisher<RestStatus, RestClientError>
    func fetchSegments() -> AnyPublisher<Segments, RestClientError>
    func cleanSegments(_ segments: SegmentsRequestData) -> AnyPublisher<ResponseString, RestClientError>
    func stopCleaning() -> AnyPublisher<ResponseString, RestClientError>
    func pauseCleaning() -> AnyPublisher<ResponseString, RestClientError>
    func driveHome() -> AnyPublisher<ResponseString, RestClientError>
    func setFanspeed(_ fanspeed: FanspeedRequestData) -> AnyPublisher<ResponseString, RestClientError>
}

public struct RestClient: RestClientProtocol {
    var baseUrl: String
    var urlSession = URLSession.shared
    
    public init(baseUrl: String) {
        self.baseUrl = baseUrl
    }

    public func fetchStatus() -> AnyPublisher<RestStatus, RestClientError> {
        return urlSession.publisher(with: self.baseUrl, and: .currentStatus)
    }
    
    public func fetchSegments() -> AnyPublisher<Segments, RestClientError> {
        return urlSession.publisher(with: self.baseUrl, and: .segmentNames)
    }
    
    public func cleanSegments(_ segments: SegmentsRequestData) -> AnyPublisher<ResponseString, RestClientError> {
        do {
            let data = try JSONEncoder().encode(segments)
            return urlSession.publisher(with: self.baseUrl, and: .cleanSegments(data))
        } catch {
            return Fail(error: RestClientError.invalidRequestData)
                .eraseToAnyPublisher()
        }
    }
    
    public func stopCleaning() -> AnyPublisher<ResponseString, RestClientError> {
        return urlSession.publisher(with: self.baseUrl, and: .stopCleaning)
    }
    
    public func pauseCleaning() -> AnyPublisher<ResponseString, RestClientError> {
        return urlSession.publisher(with: self.baseUrl, and: .pauseCleaning)
    }
    
    public func driveHome() -> AnyPublisher<ResponseString, RestClientError> {
        return urlSession.publisher(with: self.baseUrl, and: .driveHome)
    }
    
    public func setFanspeed(_ fanspeed: FanspeedRequestData) -> AnyPublisher<ResponseString, RestClientError> {
        do {
            let data = try JSONEncoder().encode(fanspeed)
            return urlSession.publisher(with: self.baseUrl, and: .setFanSpeed(data))
        } catch {
            return Fail(error: RestClientError.invalidRequestData)
                .eraseToAnyPublisher()
        }
    }
}

extension URLSession {
    func publisher<Response: Decodable>(with baseUrl: String, and endpoint: Endpoint<Response>) -> AnyPublisher<Response, RestClientError> {
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
