//
//  Connectable.swift
//  SDKit
//
//  Created by Nick Robison on 11/16/25.
//

import Foundation

public protocol Connectable {
    func doConnect() async -> Result<(), Error>
    func doHealthCheck() async -> Result<(), Error>
}
