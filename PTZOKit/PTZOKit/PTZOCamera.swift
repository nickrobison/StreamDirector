//
//  PTZOCamera.swift
//  PTZOKit
//
//  Created by Nick Robison on 11/14/25.
//

import Foundation
import OSLog
import Synchronization
import SDKit
import Clocks

@Observable
final class PTZOCamera<C: APIProtocol>: AbstractCommandHandler, Sendable {

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
        let logger = Logger.init(
            subsystem:
                "com.nickrobison.StreamDirector.PTZOKit.PTZOCamera.\(name)",
            category: "Camera"
        )
        self.client = client
        self.state = State(CameraState.init())
        super.init(logger: logger, config: CommandHandlerConfig(), clock: ContinuousClock())
    }
    
    func callPreset(_ preset: Int) async {
        let _ = await executeCameraCommand {
            try await self.client.presetCall(query: .init(presetNumber: preset))
        }
        self.currentPreset = CameraPreset(name: "<none>", value: PresetValue.presetID(String(preset)))
        
    }
    
    public override func doConnect() async -> Result<(), any Error> {
        await Task.yield()
        return .success(())
    }
    
    public override func doHealthCheck() async -> Result<(), any Error> {
        await Task.yield()
        return .success(())
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
