//
//  CameraProtocol.swift
//  PTZOKit
//
//  Created by Nick Robison (Moody's) on 11/14/25.
//

import Foundation
internal import Mocking

#if DEBUG
@MockedMembers
final class MockClient: APIProtocol {
    func presetCall(_ input: Operations.PresetCall.Input) async throws -> Operations.PresetCall.Output
    
    
}
#endif

