//
//  RestClientError.swift
//
//

import Foundation

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
