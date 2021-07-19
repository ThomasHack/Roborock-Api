//
//  MapData+Version.swift
//
//

import Foundation

extension MapData {
    public struct Version: Equatable {
        public var major: Int
        public var minor: Int

        public init(major: Int, minor: Int) {
            self.major = major
            self.minor = minor
        }
    }
}
