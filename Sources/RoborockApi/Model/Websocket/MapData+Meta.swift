//
//  MapData+Meta.swift
//
//

import Foundation

extension MapData {
    public struct Meta: Equatable {
        public var headerLength: Int
        public var dataLength: Int
        public var version: Version
        public var mapIndex: Int
        public var mapSequence: Int

        public init(headerLength: Int, dataLength: Int, version: Version, mapIndex: Int, mapSequence: Int) {
            self.headerLength = headerLength
            self.dataLength = dataLength
            self.version = version
            self.mapIndex = mapIndex
            self.mapSequence = mapSequence
        }
    }
}
