//
//  PTZOCamera.swift
//  PTZOKit
//
//  Created by Nick Robison (Moody's) on 11/14/25.
//

import Foundation
import OSLog
import Synchronization
import SDKit

@Observable
final class PTZOCamera<C: APIProtocol>: Sendable {

    private let logger: Logger
    private let client: C
    
    private let state: State<CameraState>
    
    var commandStatus: CommandStatus {
        get {
            self.access(keyPath: \.commandStatus)
            return self.state.commandStatus
        }
        set {
            self.withMutation(keyPath: \.commandStatus) {
                self.state.commandStatus = newValue
            }
        }
    }
    
    var connectionStatus: ConnectionState {
        get {
            self.access(keyPath: \.connectionStatus)
            return self.state.connectionStatus
        }
        set {
            self.withMutation(keyPath: \.connectionStatus) {
                self.state.connectionStatus = newValue
            }
        }
    }
    
    var currentPreset: CameraPreset? {
        get {
            self.access(keyPath: \.currentPreset)
            return state.activePreset
        }
        set {
            self.withMutation(keyPath: \.currentPreset) {
                state.activePreset = newValue
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
        self.state = State(CameraState.init())
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
