//
//  PTZoCameraTests.swift
//  PTZOKitTests
//
//  Created by Nick Robison (Moody's) on 11/14/25.
//

import Testing
import Observation
@testable import PTZOKit

struct PTZOCameraTests {
    
    @Test func example() async throws {
        let client = MockClient()
        
        let camera = PTZOCamera(name: "test", client: client)
        #expect(camera.connectionStatus == .disconnected)
        let _ = try await camera.connect()
        #expect(camera.connectionStatus == .connected)
        
        client._presetCall.implementation = .returns(Operations.PresetCall.Output.ok(.init()))
        
        #expect(camera.currentPreset == nil)
        let preset = 1
        let _ = await camera.callPreset(preset)
        #expect(camera.currentPreset.map(\.value) == preset.toPreset())
    }
}

private extension Int {
    
    func toPreset() -> PresetValue {
        .presetID(String(self))
    }
}
