//
//  PTZoCameraTests.swift
//  PTZOKitTests
//
//  Created by Nick Robison on 11/14/25.
//

import Observation
import Testing
import ConcurrencyExtras
import Clocks
@testable import PTZOKit

struct PTZOCameraTests {
    
    private let clock = TestClock()

    @Test func example() async throws {
        let client = MockClient()

        // TODO: This is mostly useless as it just tests what the CommandHandler tests test
        // But at least we know things compile?
        await withMainSerialExecutor {
            let camera = PTZOCamera(name: "test", client: client, clock: clock)
            #expect(camera.connectionState == .disconnected)
            await Task.yield()
            #expect(camera.connectionState == .connecting)
            await Task.yield()
            #expect(camera.connectionState == .connected)

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
