//
//  CameraRecord.swift
//  PTZOKit
//
//  Created by Nick Robison on 11/26/25.
//

import Foundation
import SQLiteData
import SDKit

@Table
nonisolated struct CameraRecord: Hashable, Identifiable {
    let id: UUID
    var name: String
    var hostname: String
    var port: Int
    @Column(as: CameraConfiguration.JSONRepresentation.self)
    var configuration: CameraConfiguration
}

@Table
struct PresetRecord: Hashable, Identifiable, Equatable {
    let id: Int
    var name: String
    var cameraId: CameraRecord.ID
    @Column(as: PresetValue.JSONRepresentation.self)
    var value: PresetValue
}


