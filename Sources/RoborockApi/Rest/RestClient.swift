//
//  RestClient.swift
//
//
//  Created by Thomas Hack on 13.07.21.
//  https://github.com/rand256/valetudo/wiki/REST-API

import Combine
import Foundation

public typealias HttpHeaders = [String: String]

enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
    case head = "HEAD"
    case trace = "TRACE"
    case connect = "CONNECT"
    case options = "OPTIONS"
}

public struct Endpoint<Response: Decodable>: Equatable {
    var path: String
    var httpMethod: HttpMethod
    var headers: HttpHeaders?
    var body: Data?
    var queryItems: [URLQueryItem]?
}

extension Endpoint {
    func makeRequest() -> URLRequest? {
        var components = URLComponents()
        components.scheme = "http"
        components.host = "roborock"
        components.path = "/api/" + path
        components.queryItems = queryItems

        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        request.httpMethod = httpMethod.rawValue
        return request
    }
}

extension Endpoint where Response == Segments {
    static var segmentNames: Self {
        Endpoint(path: "segment_names", httpMethod: .get)
    }
}

extension Endpoint where Response == RestStatus {
    static var currentStatus: Self {
        Endpoint(path: "current_status", httpMethod: .get)
    }
}

extension Endpoint where Response == ResponseString {
    static func setFanSpeed(_ body: Data) -> Self {
        return Endpoint(path: "fanspeed", httpMethod: .put, body: body)
    }

    static func cleanSegments(_ body: Data) -> Self {
        return Endpoint(path: "start_cleaning_segment", httpMethod: .put, body: body)
    }

    static var stopCleaning: Self {
        Endpoint(path: "stop_cleaning", httpMethod: .put)
    }
    static var pauseCleaning: Self {
        Endpoint(path: "pause_cleaning", httpMethod: .put)
    }
    static var driveHome: Self {
        Endpoint(path: "drive_home", httpMethod: .put)
    }
}

public enum RestClientError: Error, Equatable {
    case invalidUrl
    case invalidHttpCode
    case invalidRequestData
    case invalidResponseData
    case invalidEndpoint
    
    var localizedDescription: String {
        switch self {
        case .invalidUrl:
            return "Invalid Url."
        case .invalidHttpCode:
            return "Invalid HTTP code."
        case .invalidRequestData:
            return "Invalid request data."
        case .invalidResponseData:
            return "Invalid response data."
        case .invalidEndpoint:
            return "InvaliD endpoint."
        }
    }
}

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
    var baseUrl: String?
    var urlSession = URLSession.shared
    
    public init(baseUrl: String) {
        self.baseUrl = baseUrl
    }

    // MARK: - Roborock requests
    
    public func fetchStatus() -> AnyPublisher<RestStatus, RestClientError> {
        return urlSession.publisher(.currentStatus)
    }
    
    public func fetchSegments() -> AnyPublisher<Segments, RestClientError> {
        return urlSession.publisher(.segmentNames)
    }
    
    public func cleanSegments(_ segments: SegmentsRequestData) -> AnyPublisher<ResponseString, RestClientError> {
        do {
            let data = try JSONEncoder().encode(segments)
            return urlSession.publisher(Endpoint.cleanSegments(data))
        } catch {
            return Fail(error: RestClientError.invalidRequestData)
                .eraseToAnyPublisher()
        }
    }
    
    public func stopCleaning() -> AnyPublisher<ResponseString, RestClientError> {
        return urlSession.publisher(.stopCleaning)
    }
    
    public func pauseCleaning() -> AnyPublisher<ResponseString, RestClientError> {
        return urlSession.publisher(.pauseCleaning)
    }
    
    public func driveHome() -> AnyPublisher<ResponseString, RestClientError> {
        return urlSession.publisher(.driveHome)
    }
    
    public func setFanspeed(_ fanspeed: FanspeedRequestData) -> AnyPublisher<ResponseString, RestClientError> {
        do {
            let data = try JSONEncoder().encode(fanspeed)
            return urlSession.publisher(Endpoint.setFanSpeed(data))
        } catch {
            return Fail(error: RestClientError.invalidRequestData)
                .eraseToAnyPublisher()
        }
    }
}

extension URLSession {
    func publisher<Response: Decodable>(_ endpoint: Endpoint<Response>) -> AnyPublisher<Response, RestClientError> {
        guard let request = endpoint.makeRequest() else {
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
