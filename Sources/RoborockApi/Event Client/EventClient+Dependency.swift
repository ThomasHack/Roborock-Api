//
//  EventClient+Dependency.swift
//  
//
//  Created by Hack, Thomas on 29.02.24.
//

import ComposableArchitecture

extension DependencyValues {
    public var eventClient: EventClient {
        get { self[EventClient.self] }
        set { self[EventClient.self] = newValue }
    }
}
