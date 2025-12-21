//
//  CameraConfiguration.swift
//  PTZOKit
//
//  Created by Nick Robison on 11/26/25.
//

import Foundation

struct CameraConfiguration: Codable, Equatable, Hashable {
    var username: String
    // TODO: Obviously, this shouldn't be here. Delegate to Keychain?
    var password: String
}
