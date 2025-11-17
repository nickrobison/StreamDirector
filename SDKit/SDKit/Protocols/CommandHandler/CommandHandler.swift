//
//  CommandHandler.swift
//  SDKit
//
//  Created by Nick Robison on 11/17/25.
//
import OSLog

public protocol CommandHandler: AnyObject, Connectable, Sendable {
    var _connectionState: State<ConnectionState> { get }
    var clock: any Clock<Duration> { get }
    var healthTask: Task<Void, Error>? { get set }

    var logger: Logger { get }

    func connect(config: CommandHandlerConfig) async
    func startHealthCheck(_ config: CommandHandlerConfig)
}

extension CommandHandler {
    func connect(config: CommandHandlerConfig) async {
        logger.info("Attempting to connect to device")
        _connectionState.data = .connecting
        let result = await doConnect()
        switch result {
        case .success():
            logger.info("Connection succeeded")
            _connectionState.data = .connected
            // Register healthcheck handler
            startHealthCheck(config)
        case .failure(let err):
            // TODO: Add retry handling here
            logger.error(
                "Connection failed due to: \(err.localizedDescription)"
            )
            _connectionState.data = .failed(err.localizedDescription)
        }
    }

    func startHealthCheck(_ config: CommandHandlerConfig) {
        logger.info(
            "Registering health check with interval of \(config.healthCheckInterval)"
        )
        healthTask = Task {
            while !Task.isCancelled {
                try? await clock.sleep(
                    for: config.healthCheckInterval
                )
                if Task.isCancelled { return }
                self.logger.info("Performing healthcheck")
                let result = await self.doHealthCheck()
                switch result {
                case .success():
                    logger.info("Health check passed")
                    _connectionState.data = .connected
                case .failure(let err):
                    // TODO: Add error handling here
                    self.logger.error(
                        "Connection failed due to: \(err.localizedDescription)"
                    )
                    _connectionState.data = .failed(err.localizedDescription)
                }
            }
        }
    }
}
