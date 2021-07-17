//
//  RestClient.swift
//
//
//  Created by Thomas Hack on 13.07.21.
//  https://github.com/rand256/valetudo/wiki/REST-API

import Combine
import Foundation

enum HttpMethods: String {
    case get = "GET"
    case put = "PUT"
}

protocol RequestType {
    associatedtype RequestData
    static func prepare(_ request: inout URLRequest, with data: RequestData)
}

enum RequestTypes {
    enum Get: RequestType {
        static func prepare(_ request: inout URLRequest, with _: Void) {
            request.cachePolicy = .reloadIgnoringLocalCacheData
        }
    }

    enum Put: RequestType {
        static func prepare(_ request: inout URLRequest, with data: Data) {
            request.httpMethod = HttpMethods.put.rawValue
            request.httpBody = data
            request.allHTTPHeaderFields = [
                "Content-Type": "application/json",
                "Accept": "application/json"
            ]
        }

        static func prepare(_ request: inout URLRequest) {
            request.httpMethod = HttpMethods.put.rawValue
            request.allHTTPHeaderFields = [
                "Content-Type": "application/json",
                "Accept": "application/json"
            ]
        }
    }
}

public enum RestClientError: Error, Equatable {
    case invalidUrl
    case invalidHttpCode
    case invalidRequestData
    case invalidResponseData
}

protocol RestClientProtocol {
    func fetchStatus() -> AnyPublisher<RestStatus, RestClientError>
    func fetchSegments() -> AnyPublisher<Segments, RestClientError>
    func cleanSegments(_ segments: [Int], repeats: Int, order: Int) -> AnyPublisher<String, RestClientError>
    func stopCleaning() -> AnyPublisher<String, RestClientError>
    func pauseCleaning() -> AnyPublisher<String, RestClientError>
    func driveHome() -> AnyPublisher<String, RestClientError>
    func setFanspeed(_ fanspeed: Int) -> AnyPublisher<String, RestClientError>
}

public struct RestClient: RestClientProtocol {
    var baseUrl: String?
    var urlSession = URLSession.shared

    public init(baseUrl: String) {
        self.baseUrl = baseUrl
    }

    enum Endpoint {
        case currentStatus
        case fetchSegments
        case cleanSegments
        case stopCleaning
        case pauseCleaning
        case driveHome
        case setFanSpeed

        var path: String {
            switch self {
            case .currentStatus:
                return "current_status"
            case .fetchSegments:
                return "segment_names"
            case .cleanSegments:
                return "start_cleaning_segment"
            case .stopCleaning:
                return "stop_cleaning"
            case .pauseCleaning:
                return "pause_cleaning"
            case .driveHome:
                return "drive_home"
            case .setFanSpeed:
                return "fanspeed"
            }
        }
    }

    enum RequestData {
        case segments(SegmentsRequestData)
        case fanspeed(FanspeedRequestData)
    }

    // MARK: - Roborock requests

    public func fetchStatus() -> AnyPublisher<RestStatus, RestClientError> {
        let request = makeRequest(with: Endpoint.currentStatus.path)
        return sendRequest(request)
    }

    public func fetchSegments() -> AnyPublisher<Segments, RestClientError> {
        let request = makeRequest(with: Endpoint.fetchSegments.path)
        return sendRequest(request)
    }

    public func cleanSegments(_ segments: [Int], repeats: Int, order: Int) -> AnyPublisher<String, RestClientError> {
        let requestData = SegmentsRequestData(segments: segments, repeats: repeats, order: order)
        let request = makeRequest(with: Endpoint.cleanSegments.path, requestData: RequestData.segments(requestData))
        return sendRequest(request)
    }

    public func stopCleaning() -> AnyPublisher<String, RestClientError> {
        let request = makeRequest(with: Endpoint.stopCleaning.path)
        return sendRequest(request)
    }

    public func pauseCleaning() -> AnyPublisher<String, RestClientError> {
        let request = makeRequest(with: Endpoint.pauseCleaning.path)
        return sendRequest(request)
    }

    public func driveHome() -> AnyPublisher<String, RestClientError> {
        let request = makeRequest(with: Endpoint.driveHome.path)
        return sendRequest(request)
    }

    public func setFanspeed(_ fanspeed: Int) -> AnyPublisher<String, RestClientError> {
        let requestData = FanspeedRequestData(speed: fanspeed)
        let request = makeRequest(with: Endpoint.setFanSpeed.path, requestData: RequestData.fanspeed(requestData))
        return sendRequest(request)
    }

    // MARK: - General requests

    private func makeRequest(with path: String, requestData: RequestData? = nil) -> Result<URLRequest, RestClientError> {
        guard let baseUrl = baseUrl, let url = URL(string: baseUrl + path) else {
            return .failure(.invalidUrl)
        }

        var request = URLRequest(url: url)
        guard let requestData = requestData else {
            RequestTypes.Put.prepare(&request)
            return .success(request)
        }

        do {
            switch requestData {
            case .fanspeed(let fanspeedRequestData):
                let data = try JSONEncoder().encode(fanspeedRequestData)
                RequestTypes.Put.prepare(&request, with: data)
            case .segments(let segmentsRequestData):
                let data = try JSONEncoder().encode(segmentsRequestData)
                RequestTypes.Put.prepare(&request, with: data)
            }
            return .success(request)
        } catch {
            return .failure(.invalidRequestData)
        }
    }

    public func sendRequest<T: Decodable>(_ request: Result<URLRequest, RestClientError>) -> AnyPublisher<T, RestClientError> {
        switch request {
        case .success(let request):
            return publisher(with: request, responseType: T.self)
        case .failure(let error):
            return Result.Publisher(.failure(error))
                .eraseToAnyPublisher()
        }
    }

    private func publisher<T: Decodable>(with request: URLRequest, responseType: T.Type = T.self, decoder: JSONDecoder = .init()) -> AnyPublisher<T, RestClientError> {
        urlSession.dataTaskPublisher(for: request)
            .map{ data, _ in data }
            .decode(type: T.self, decoder: decoder)
            .mapError{ _ in RestClientError.invalidResponseData }
            .eraseToAnyPublisher()
    }
}
