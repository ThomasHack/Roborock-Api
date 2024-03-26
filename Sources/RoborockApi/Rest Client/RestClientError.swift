//
//  RestClientError.swift
//
//

import Foundation

public enum RestClientError: Error, Equatable {
    case missingBaseUrl
    case invalidUrl
    case invalidHttpCode(Int)
    case invalidRequestData
    case invalidResponseData
    case invalidEndpoint

    var localizedDescription: String {
        switch self {
        case .missingBaseUrl:
            return "Missing base URL"
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
