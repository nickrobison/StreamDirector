//
//  PTZOCamera.swift
//  PTZOKit
//
//  Created by Nick Robison on 11/14/25.
//

import Foundation
import OSLog
import SDKit
import Clocks
import OpenAPIURLSession

@Observable
final class PTZOCamera<C: APIProtocol>: CommandHandler {
    let _connectionState: State<ConnectionState>
    
    let clock: any Clock<Duration>
    
    let healthTask: State<Task<(), Never>?>
    

    private let client: C
    
    let logger: Logger
    
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
    
    var connectionState: ConnectionState {
        get {
            self.access(keyPath: \.connectionState)
            return self._connectionState.data
        }
        set {
            self.withMutation(keyPath: \.connectionState) {
                self._connectionState.data = newValue
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

    init(name: String, client: C, clock: any Clock<Duration>) {
        self.logger = Logger.init(
            subsystem:
                "com.nickrobison.StreamDirector.PTZOKit.PTZOCamera.\(name)",
            category: "Camera"
        )
        self.client = client
        self.state = State(CameraState.init())
        self.healthTask = .init(nil)
        self.clock = clock
        self._connectionState = .init(.disconnected)
        Task {
            // TODO: Inject this
            await connect(config: CommandHandlerConfig())
        }
        
    }
    
    func callPreset(_ preset: Int) async {
        let _ = await executeCameraCommand {
            try await self.client.presetCall(query: .init(presetNumber: preset))
        }
        self.currentPreset = CameraPreset(name: "<none>", value: PresetValue.presetID(String(preset)))
        
    }
    
    public func doConnect() async -> Result<(), any Error> {
        await Task.yield()
        return .success(())
    }
    
    public func doHealthCheck() async -> Result<(), any Error> {
        await Task.yield()
        return .success(())
    }
    
    private func executeCameraCommand<T>(_ command: @escaping () async throws -> T) async -> T? {
        logger.info("Executing camera command")
        self.commandStatus = .executing
        do {
            defer { self.commandStatus = .idle}
            return try await executeCommand(command)
        } catch let error {
            logger.error("Command execution failed: \(error.localizedDescription)")
            self.commandStatus = .failed(message: error.localizedDescription)
            return nil
        }
    }
}

extension PTZOCamera {
    
    convenience init(record: CameraRecord) {
        let url = URL(string: "http://\(record.hostname):\(record.port)")!
        let client = Client(serverURL: url, transport: URLSessionTransport())
        self.init(name: record.name, client: client as! C, clock: .suspending)
    }
}
