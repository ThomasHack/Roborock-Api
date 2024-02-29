//
//  EventEndpoint.swift
//  
//
//  Created by Hack, Thomas on 29.02.24.
//

import Foundation

public struct EventEndpoint: Equatable {
    var path: String

    public static var stateAttributesStream: Self {
        EventEndpoint(path: "robot/state/attributes/sse")
    }
    public static var mapStream: Self {
        EventEndpoint(path: "robot/state/map/sse")
    }

    func makeRequest(with baseUrl: URL) -> URLRequest? {
        guard var components = URLComponents(url: baseUrl, resolvingAgainstBaseURL: false) else { return nil }
        components.path = "/api/v2/" + path

        guard let url = components.url else { return nil }

        return URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
    }
}
