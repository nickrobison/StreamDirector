//
//  CommandHandler.swift
//  SDKit
//
//  Created by Nick Robison on 11/16/25.
//
import OSLog

@Observable
open class CommandHandler: Connectable {
    // TODO: Really?
    public func doConnect() async -> Result<(), any Error> {
        fatalError("unimplemented. Please override")
    }
    
    public func doHealthCheck() async -> Result<(), any Error> {
        fatalError("unimplemented. Please override")
    }
    
    private let logger: Logger

    private let _connectionState: State<ConnectionState>
    private let clock: any Clock<Duration>
    private let config: CommandHandlerConfig
    private var healthTask: Task<Void, Error>?

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

    init(
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
        // TODO: Fix this warning. How?
        self.logger.info("Registering health check with interval of \(self.config.healthCheckInterval)")
        self.healthTask = Task {
            while true {
                try await self.clock.sleep(for: self.config.healthCheckInterval)
                self.logger.info("Performing healthcheck")
                let result = await self.doHealthCheck()
                switch result {
                case .success():
                    // TODO: Should we check before setting?
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
