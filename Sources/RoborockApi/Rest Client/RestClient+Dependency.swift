//
//  RestClient+Dependency.swift
//  Roborock
//
//  Created by Hack, Thomas on 11.03.23.
//

import ComposableArchitecture

extension DependencyValues {
  public var restClient: RestClient {
    get { self[RestClient.self] }
    set { self[RestClient.self] = newValue }
  }
}
