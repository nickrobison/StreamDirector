//
//  CameraPreset.swift
//  PTZOKit
//
//  Created by Nick Robison on 11/9/25.
//

import Foundation

struct CameraPreset: Equatable {
    let name: String
    let value: PresetValue
}

enum PresetValue: Equatable {
    case presetID(String)
}

extension CameraPreset: Identifiable {
    var id: String {
        self.name
    }
}
