//
//  PTZoCameraTests.swift
//  PTZOKitTests
//
//  Created by Nick Robison (Moody's) on 11/14/25.
//

import Observation
import Testing
import ConcurrencyExtras
@testable import PTZOKit

struct PTZOCameraTests {

    @Test func example() async throws {
        let client = MockClient()

        let camera = PTZOCamera(name: "test", client: client)
        #expect(camera.connectionStatus == .disconnected)
        try await withMainSerialExecutor {

            let task = Task { try await camera.connect() }
            await Task.yield()
            #expect(camera.connectionStatus == .connecting)
            try await task.value
            #expect(camera.connectionStatus == .connected)

            client._presetCall.implementation = .returns(
                Operations.PresetCall.Output.ok(.init())
            )

            #expect(camera.currentPreset == nil)
            let preset = 1
            let _ = await camera.callPreset(preset)
            #expect(camera.currentPreset.map(\.value) == preset.toPreset())
        }
    }
}

extension Int {

    fileprivate func toPreset() -> PresetValue {
        .presetID(String(self))
    }
}
