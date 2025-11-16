//
//  PTZOCamera.swift
//  PTZOKit
//
//  Created by Nick Robison (Moody's) on 11/14/25.
//

import Foundation
import OSLog
import Synchronization

@Observable
class PTZOCamera<C: APIProtocol>: @unchecked Sendable {

    private let logger: Logger
    private let client: C
    
    private let state: Mutex<CameraState>
    
    var commandStatus: CommandStatus {
        get {
            self.access(keyPath: \.commandStatus)
            return state.withLock { state in
                state.commandStatus
            }
        }
        set {
            self.withMutation(keyPath: \.commandStatus) {
                state.withLock { state in
                    state.commandStatus = newValue
                }
            }
        }
    }
    
    var connectionStatus: ConnectionState {
        get {
            self.access(keyPath: \.connectionStatus)
            return state.withLock { state in
                state.connectionStatus
            }
        }
        set {
            self.withMutation(keyPath: \.connectionStatus) {
                state.withLock { state in
                    state.connectionStatus = newValue
                }
            }
        }
    }
    
    var currentPreset: CameraPreset? {
        get {
            self.access(keyPath: \.currentPreset)
            return state.withLock { state in
                state.activePreset
            }
        }
        set {
            self.withMutation(keyPath: \.currentPreset) {
                state.withLock { state in
                    state.activePreset = newValue
                }
            }
        }
    }

    init(name: String, client: C) {
        self.logger = Logger.init(
            subsystem:
                "com.nickrobison.StreamDirector.PTZOKit.PTZOCamera.\(name)",
            category: "Camera"
        )
        self.client = client
        self.logger.info("Connecting to camera")
        self.state = Mutex(CameraState.init())
    }
    
    func callPreset(_ preset: Int) async {
        let _ = await executeCameraCommand {
            try await self.client.presetCall(query: .init(presetNumber: preset))
        }
        self.currentPreset = CameraPreset(name: "<none>", value: PresetValue.presetID(String(preset)))
        
    }

    func connect() async throws {
        self.connectionStatus = .connecting
        await Task.yield()
        self.connectionStatus = .connected
    }
    
    private func executeCameraCommand<T>(_ command: @escaping () async throws -> T) async -> T? {
        logger.info("Executing camera command")
        self.commandStatus = .executing
        do {
            defer { self.commandStatus = .idle}
            return try await command()
        } catch let error {
            logger.error("Command execution failed: \(error.localizedDescription)")
            self.commandStatus = .failed(message: error.localizedDescription)
            return nil
        }
    }
}
