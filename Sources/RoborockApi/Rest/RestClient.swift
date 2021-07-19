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

struct Endpoint<Request: Encodable, Response: Decodable> {
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
        components.path = "/" + path
        components.queryItems = queryItems
        
        guard let url = components.url else { return nil }

        return URLRequest(url: url)
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

extension Endpoint where Request == SegmentsRequestData, Response == Segments {
    static func cleanSegments(_ segments: SegmentsRequestData) throws -> Self {
        do {
            let body = try JSONEncoder().encode(segments)
            return Endpoint(path: "start_cleaning_segment", httpMethod: .put, body: body)
        } catch {
            throw RestClientError.invalidRequestData
        }
    }
}

extension Endpoint where Request == FanspeedRequestData, Response == ResponseString {
    static func setFanSpeed(_ fanspeed: FanspeedRequestData) throws -> Self {
        do {
            let body = try JSONEncoder().encode(fanspeed)
            return Endpoint(path: "fanspeed", httpMethod: .put, body: body)
        } catch {
            throw RestClientError.invalidRequestData
        }
    }
}

extension Endpoint where Response == ResponseString {
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
    // case invalidEndpoint(endpoint: Endpoint<EndpointKind, Decodable>)
    
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
        // case .invalidEndpoint(endpoint: (Kind: EndpointKind, Response: Decodable)):
        //    return "Invalid endpoint."
        }
    }
}

protocol RestClientProtocol {
    func fetchStatus() -> AnyPublisher<RestStatus, RestClientError>
    func fetchSegments() -> AnyPublisher<Segments, RestClientError>
    func cleanSegments(_ segments: [Int], repeats: Int, order: Int) -> AnyPublisher<ResponseString, RestClientError>
    func stopCleaning() -> AnyPublisher<ResponseString, RestClientError>
    func pauseCleaning() -> AnyPublisher<ResponseString, RestClientError>
    func driveHome() -> AnyPublisher<ResponseString, RestClientError>
    func setFanspeed(_ fanspeed: Fanspeed) -> AnyPublisher<ResponseString, RestClientError>
}

public struct RestClient: RestClientProtocol {
    var baseUrl: String?
    var urlSession = URLSession.shared
    
    public init(baseUrl: String) {
        self.baseUrl = baseUrl
    }
    
    // MARK: - Roborock requests
    
    public func fetchStatus() -> AnyPublisher<RestStatus, RestClientError> {
        return urlSession.publisher(for: .currentStatus)
    }
    
    public func fetchSegments() -> AnyPublisher<Segments, RestClientError> {
        return urlSession.publisher(for: .segmentNames)
    }
    
    public func cleanSegments(_ segments: [Int], repeats: Int, order: Int) -> AnyPublisher<ResponseString, RestClientError> {
        let requestData = SegmentsRequestData(segments: segments, repeats: repeats, order: order)
        return urlSession.publisher(for: .cleanSegments(requestData))
    }
    
    public func stopCleaning() -> AnyPublisher<ResponseString, RestClientError> {
        return urlSession.publisher(for: .stopCleaning)
    }
    
    public func pauseCleaning() -> AnyPublisher<ResponseString, RestClientError> {
        return urlSession.publisher(for: .pauseCleaning)
    }
    
    public func driveHome() -> AnyPublisher<ResponseString, RestClientError> {
        return urlSession.publisher(for: .driveHome)
    }
    
    public func setFanspeed(_ fanspeed: Fanspeed) -> AnyPublisher<ResponseString, RestClientError> {
        let requestData = FanspeedRequestData(speed: fanspeed.rawValue)
        return try urlSession.publisher(for: .setFanSpeed(requestData))
    }
}

extension URLSession {
    func publisher<Request, Response>(for endpoint: Endpoint<Request, Response>, encoder: JSONEncoder = .init(), decoder: JSONDecoder = .init()) -> AnyPublisher<Response, RestClientError> {
        guard let request = endpoint.makeRequest() else {
            // return Fail(error: RestClientError.invalidEndpoint(endpoint: endpoint))
            return Fail(error: RestClientError.invalidRequestData)
                .eraseToAnyPublisher()
        }
        
        return dataTaskPublisher(for: request)
            .map{ data, _ in data }
            .decode(type: Response.self, decoder: decoder)
            .mapError{ _ in RestClientError.invalidResponseData }
            .eraseToAnyPublisher()
    }
}
