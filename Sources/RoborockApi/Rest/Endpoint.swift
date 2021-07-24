//
//  Endpoint.swift
//
//  https://www.swiftbysundell.com/articles/creating-generic-networking-apis-in-swift/

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
    func makeRequest(with baseUrl: URL) -> URLRequest? {
        guard var components = URLComponents(url: baseUrl, resolvingAgainstBaseURL: false) else { return nil }
        components.path = "/api/" + path
        components.queryItems = queryItems

        guard let url = components.url else { return nil }
        
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = httpMethod.rawValue
        request.httpBody = body
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
