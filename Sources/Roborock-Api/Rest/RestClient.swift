//
//  RestClient.swift
//  RoborockApi
//
//  Created by Hack, Thomas on 13.07.21.
//

import Combine
import Foundation

protocol RequestType {
    associatedtype RequestData

    static func prepare(_ request: inout URLRequest, with data: RequestData)
}

enum HttpMethods: String {
    case get = "GET"
    case put = "PUT"
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
    case url
    case invalidHttpCode
}

protocol RestClientProtocol {
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

    enum Endpoints: String {
        case fetchSegments = "segment_names"
        case cleanSegments = "start_cleaning_segment"
        case stopCleaning = "stop_cleaning"
        case pauseCleaning = "pause_cleaning"
        case driveHome = "drive_home"
        case setFanSpeed = "fanspeed"
    }

    enum RequestData {
        case segments(SegmentsRequestData)
        case fanspeed(FanspeedRequestData)
    }

    public func fetchSegments() -> AnyPublisher<Segments, RestClientError> {
        guard let request = makeGetRequest(with: Endpoints.fetchSegments.rawValue) else {
            return Result.Publisher(.failure(RestClientError.url))
                .eraseToAnyPublisher()
        }
        return publisher(with: request, responseType: Segments.self)
    }

    public func cleanSegments(_ segments: [Int], repeats: Int, order: Int) -> AnyPublisher<String, RestClientError> {
        let requestData = SegmentsRequestData(segments: segments, repeats: repeats, order: order)

        guard let request = makeDataPutRequest(with: Endpoints.cleanSegments.rawValue, requestData: RequestData.segments(requestData)) else {
            return Result.Publisher(.failure(RestClientError.url))
                .eraseToAnyPublisher()
        }
        return publisher(with: request, responseType: String.self)
    }

    public func stopCleaning() -> AnyPublisher<String, RestClientError> {
        guard let request = makePutRequest(with: Endpoints.stopCleaning.rawValue) else {
            return Result.Publisher(.failure(RestClientError.url))
                .eraseToAnyPublisher()
        }
        return publisher(with: request, responseType: String.self)
    }

    public func pauseCleaning() -> AnyPublisher<String, RestClientError> {
        guard let request = makePutRequest(with: Endpoints.pauseCleaning.rawValue) else {
            return Result.Publisher(.failure(RestClientError.url))
                .eraseToAnyPublisher()
        }
        return publisher(with: request, responseType: String.self)
    }

    public func driveHome() -> AnyPublisher<String, RestClientError> {
        guard let request = makePutRequest(with: Endpoints.driveHome.rawValue) else {
            return Result.Publisher(.failure(RestClientError.url))
                .eraseToAnyPublisher()
        }
        return publisher(with: request, responseType: String.self)
    }

    public func setFanspeed(_ fanspeed: Int) -> AnyPublisher<String, RestClientError> {
        let requestData = FanspeedRequestData(speed: fanspeed)

        guard let request = makeDataPutRequest(with: Endpoints.setFanSpeed.rawValue, requestData: RestClient.RequestData.fanspeed(requestData)) else {
            return Result.Publisher(.failure(RestClientError.url))
                .eraseToAnyPublisher()
        }
        return publisher(with: request, responseType: String.self)
    }

    private func makeGetRequest(with url: String) -> URLRequest? {
        guard let baseUrl = baseUrl, let url = URL(string: baseUrl + url) else { return nil }
        var request = URLRequest(url: url)
        RequestTypes.Get.prepare(&request, with: ())
        return request
    }

    private func makePutRequest(with url: String) -> URLRequest? {
        guard let baseUrl = baseUrl, let url = URL(string: baseUrl + url) else { return nil }
        var request = URLRequest(url: url)
        RequestTypes.Put.prepare(&request)
        return request
    }

    private func makeDataPutRequest(with url: String, requestData: RequestData) -> URLRequest? {
        guard let baseUrl = baseUrl, let url = URL(string: baseUrl + url) else { return nil }
        var request = URLRequest(url: url)

        do {
            switch requestData {
            case .fanspeed(let fanspeedRequestData):
                let data = try JSONEncoder().encode(fanspeedRequestData)
                RequestTypes.Put.prepare(&request, with: data)
            case .segments(let segmentsRequestData):
                let data = try JSONEncoder().encode(segmentsRequestData)
                RequestTypes.Put.prepare(&request, with: data)
            }
            return request
        } catch {
            return nil
        }
    }

    private func publisher<T: Decodable>(with request: URLRequest, responseType: T.Type = T.self, decoder: JSONDecoder = .init()) -> AnyPublisher<T, RestClientError> {
        urlSession.dataTaskPublisher(for: request)
            .map{ data, _ in data }
            .decode(type: T.self, decoder: decoder)
            .mapError{ _ in RestClientError.url }
            .eraseToAnyPublisher()
    }
}
