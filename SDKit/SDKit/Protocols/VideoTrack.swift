//
//  VideoTrack.swift
//  SDKit
//
//  Created by Nick Robison on 11/9/25.
//

import Foundation

public protocol VideoTrack: Identifiable {
    var name: String { get }
    var input: (any VideoDevice)? { get }
}
