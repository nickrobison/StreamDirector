//
//  CommandHandler.swift
//  SDKit
//
//  Created by Nick Robison on 11/16/25.
//
import OSLog

/// An observable class that manages the connection and health status of a device.
///
/// This class provides a base implementation for connecting to a device, performing health checks,
/// and managing the connection state. It is designed to be subclassed, with the subclass providing
/// the specific implementation for the `doConnect()` and `doHealthCheck()` methods.
///
/// The `CommandHandler` automatically attempts to connect when initialized and, upon a successful connection,
/// starts a periodic health check. The connection state is published via the `connectionState` property.
@Observable
open class CommandHandler: Connectable {
    // TODO: Really?
    open func doConnect() async -> Result<(), any Error> {
        fatalError("unimplemented. Please override")
    }
    
    open func doHealthCheck() async -> Result<(), any Error> {
        fatalError("unimplemented. Please override")
    }
    
    public let logger: Logger

    private let _connectionState: State<ConnectionState>
    private let clock: any Clock<Duration>
    private let config: CommandHandlerConfig
    private var healthTask: Task<Void, Error>?

    public var connectionState: ConnectionState {
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

    public init(
        logger: Logger,
        config: CommandHandlerConfig,
        connectionState: ConnectionState = .disconnected,
        clock: any Clock<Duration>
    ) {
        self.logger = logger
        self._connectionState = State(connectionState)
        self.clock = clock
        self.config = config
        Task {
            await connect()
        }
    }
    
    deinit {
        healthTask?.cancel()
        healthTask = nil
    }

    private func connect() async {
        self.logger.info("Attempting to connect to device")
        self.connectionState = .connecting
        let result = await self.doConnect()
        switch result {

        case .success():
            logger.info("Connection succeeded")
            self.connectionState = .connected
            // Register healthcheck handler
            self.registerHealthCheck()
        case .failure(let err):
            // TODO: Add retry handling here
            self.logger.error("Connection failed due to: \(err.localizedDescription)")
            self.connectionState = .failed(err.localizedDescription)
        }
    }
    
    private func registerHealthCheck() {
        self.logger.info("Registering health check with interval of \(self.config.healthCheckInterval)")
        self.healthTask = Task { [weak self] in
            guard let self = self else { return }
            while !Task.isCancelled {
                try? await self.clock.sleep(for: self.config.healthCheckInterval)
                if Task.isCancelled { return }
                self.logger.info("Performing healthcheck")
                let result = await self.doHealthCheck()
                switch result {
                case .success():
                    self.logger.info("Health check passed")
                    self.connectionState = .connected
                case .failure(let err):
                    // TODO: Add error handling here
                    self.logger.error("Connection failed due to: \(err.localizedDescription)")
                    self.connectionState = .failed(err.localizedDescription)
                }
            }
        }
    }
}
