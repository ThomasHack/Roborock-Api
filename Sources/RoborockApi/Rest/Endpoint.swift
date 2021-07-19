//
//  Endpoint.swift
//  
//

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
    func makeRequest(with baseUrl: String) -> URLRequest? {
        guard var components = URLComponents(string: baseUrl) else { return nil }
        components.path = "/api/" + path
        components.queryItems = queryItems

        guard let url = URL(string: baseUrl) else { return nil }

        var request = URLRequest(url: url)
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
