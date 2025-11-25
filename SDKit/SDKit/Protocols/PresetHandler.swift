//
//  PresetHandler.swift
//  SDKit
//
//  Created by Nick Robison on 11/24/25.
//

import Foundation
import Mocking

@Mocked(compilationCondition: .debug)
public protocol PresetHandler: Sendable {
    func getPresets() async throws -> [CameraPreset]
    func getActivePreset() async throws -> CameraPreset?
    func set(preset: CameraPreset) async throws -> ()
    func add(preset: CameraPreset) async throws -> ()
    func remove(preset: CameraPreset) async throws -> ()
}
