//
//  PTZOCamera.swift
//  PTZOKit
//
//  Created by Nick Robison (Moody's) on 11/14/25.
//

import Foundation
import OSLog
@preconcurrency import Combine

enum ConnectionStatus {
    case connected
    case disconnected
    case connecting
}

enum CommandStatus {
    case idle
    case executing
    case failed(message: String)
}

actor PTZOCamera<C: APIProtocol> {
    
    private let statusPublisher: CurrentValueSubject<ConnectionStatus, Never> = .init(.disconnected)
    private let commandStatusPublisher: CurrentValueSubject<CommandStatus, Never> = .init(.idle)

    private let logger: Logger
    private let client: C
    
    nonisolated let commandStatus: AnyPublisher<CommandStatus, Never>
    nonisolated let connectionStatus: AnyPublisher<ConnectionStatus, Never>

    init(name: String, client: C) {
        self.logger = Logger.init(
            subsystem:
                "com.nickrobison.StreamDirector.PTZOKit.PTZOCamera.\(name)",
            category: "Camera"
        )
        self.client = client
        self.logger.info("Connecting to camera")
        self.connectionStatus = statusPublisher.eraseToAnyPublisher()
        self.commandStatus = commandStatusPublisher.eraseToAnyPublisher()
        Task {
            await connect()
        }
    }
    
    func callPreset(_ preset: Int) async {
        let _ = await executeCameraCommand {
            try await self.client.presetCall(query: .init(presetNumber: preset))
        }
    }

    private func connect() async {
        statusPublisher.send(.connecting)
        statusPublisher.send(.connected)
    }
    
    private func executeCameraCommand<T>(_ command: @escaping () async throws -> T) async -> T? {
        logger.info("Executing camera command")
        commandStatusPublisher.send(.executing)
        do {
            return try await command()
        } catch let error {
            logger.error("Command execution failed: \(error.localizedDescription)")
            commandStatusPublisher.send(.failed(message: error.localizedDescription))
            return nil
        }
    }
}
