//
//  PTZoCameraTests.swift
//  PTZOKitTests
//
//  Created by Nick Robison (Moody's) on 11/14/25.
//

import Testing
@testable import PTZOKit

struct PTZOCameraTests {
    
    @Test func example() async throws {
        let client = MockClient()
        let camera = PTZOCamera(name: "test", client: client)
        var iter = camera.connectionStatus.values.makeAsyncIterator()
        
        
    }
}
