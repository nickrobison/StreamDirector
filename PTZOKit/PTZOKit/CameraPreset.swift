//
//  CameraPreset.swift
//  PTZOKit
//
//  Created by Nick Robison on 11/9/25.
//

import Foundation
import SQLiteData

struct CameraPreset: Equatable {
    let name: String
    let value: PresetValue
}

enum PresetValue: Codable, Equatable, Hashable {
    case presetID(String)
}

extension CameraPreset: Identifiable {
    var id: String {
        self.name
    }
}
