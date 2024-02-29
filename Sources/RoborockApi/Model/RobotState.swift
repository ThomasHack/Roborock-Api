//
//  RobotState.swift
//  
//
//  Created by Hack, Thomas on 19.02.24.
//

import UIKit

public struct RobotState: Equatable, Decodable {
    public var attributes: [StateAttribute]
    public var map: Map
}
