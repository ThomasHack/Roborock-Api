//
//  RestClient+Dependency.swift
//  Roborock
//
//  Created by Hack, Thomas on 11.03.23.
//

import ComposableArchitecture

extension RestClient: DependencyKey {
    public static let liveValue = RestClient.live
}

extension DependencyValues {
  public var restClient: RestClient {
    get { self[RestClient.self] }
    set { self[RestClient.self] = newValue }
  }
}
