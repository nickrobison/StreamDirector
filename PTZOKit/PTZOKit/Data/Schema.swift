//
//  CameraRecord.swift
//  PTZOKit
//
//  Created by Nick Robison on 11/26/25.
//

import Foundation
import SQLiteData

@Table
nonisolated struct CameraRecord: Hashable, Identifiable {
    let id: UUID
    var name: String
    var hostname: String
    var port: String
    @Column(as: CameraConfiguration.JSONRepresentation.self)
    var configuration: CameraConfiguration
}

@Table
struct PresetRecord: Hashable, Identifiable {
    let id: Int
    var name: String
    var cameraId: CameraRecord.ID
    @Column(as: PresetValue.JSONRepresentation.self)
    var value: PresetValue
}
