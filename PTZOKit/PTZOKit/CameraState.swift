//
//  CameraState.swift
//  PTZOKit
//
//  Created by Nick Robison on 11/16/25.
//

import Foundation
import Spatial
import SDKit

struct CameraState {
    var commandStatus: CommandStatus = .idle
    var orientation: Point3D = Point3D.zero
    var activePreset: CameraPreset? = nil
}
