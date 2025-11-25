//
//  CameraPreset.swift
//  PTZOKit
//
//  Created by Nick Robison on 11/9/25.
//

import Foundation

public struct CameraPreset: Equatable, Sendable {
    public let name: String
    public let value: PresetValue
    
    public init(name: String, value: PresetValue) {
        self.name = name
        self.value = value
    }
}

public enum PresetValue: Equatable, Sendable {
    case presetID(String)
}

extension CameraPreset: Identifiable {
    public var id: String {
        self.name
    }
}
