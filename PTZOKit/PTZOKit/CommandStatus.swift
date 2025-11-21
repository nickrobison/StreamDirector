//
//  CommandStatus.swift
//  PTZOKit
//
//  Created by Nick Robison on 11/16/25.
//

import Foundation

enum CommandStatus: Sendable {
    case idle
    case executing
    case failed(message: String)
}
