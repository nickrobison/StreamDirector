//
//  CommandHandlerTests.swift
//  SDKit
//
//  Created by Nick Robison on 11/16/25.
//

import Clocks
import ConcurrencyExtras
internal import Mocking
import OSLog
import Testing

@testable import SDKit

private let testLogger = Logger(
    subsystem: "com.nickrobison.SDKit",
    category: "Testing"
)

private actor HandlerState {
    var healthCount: Int = 0

    func incHealthCount() {
        healthCount += 1
    }
}

private class HappyHandler: CommandHandler {

    let state: HandlerState

    override func doConnect() async -> Result<(), any Error> {
        await Task.yield()
        return .success(())
    }

    override func doHealthCheck() async -> Result<(), any Error> {
        await state.incHealthCount()
        return .success(())
    }

    init(_ clock: any Clock<Duration>, state: HandlerState = HandlerState()) {
        self.state = state
        super.init(
            logger: testLogger,
            config: CommandHandlerConfig(),
            clock: clock
        )
    }
}

private class FailingConnectionHandler: CommandHandler {
    enum TestError: Error {
        case connectionFailed
    }

    override func doConnect() async -> Result<(), any Error> {
        await Task.yield()
        return .failure(TestError.connectionFailed)
    }

    init(_ clock: any Clock<Duration>) {
        super.init(
            logger: testLogger,
            config: CommandHandlerConfig(),
            clock: clock
        )
    }
}

private class FailingHealthCheckHandler: CommandHandler {
    enum TestError: Error {
        case healthCheckFailed
    }

    override func doConnect() async -> Result<(), any Error> {
        await Task.yield()
        return .success(())
    }

    override func doHealthCheck() async -> Result<(), any Error> {
        await Task.yield()
        return .failure(TestError.healthCheckFailed)
    }

    init(_ clock: any Clock<Duration>) {
        super.init(
            logger: testLogger,
            config: CommandHandlerConfig(),
            clock: clock
        )
    }
}

private class FlakyHealthCheckHandler: CommandHandler {
    enum TestError: Error {
        case healthCheckFailed
    }

    private let state: HandlerState

    override func doConnect() async -> Result<(), any Error> {
        await Task.yield()
        return .success(())
    }

    override func doHealthCheck() async -> Result<(), any Error> {
        let count = await state.healthCount
        await state.incHealthCount()
        if count == 0 {
            return .failure(TestError.healthCheckFailed)
        }
        return .success(())
    }

    init(_ clock: any Clock<Duration>, state: HandlerState) {
        self.state = state
        super.init(
            logger: testLogger,
            config: CommandHandlerConfig(),
            clock: clock
        )
    }
}

struct CommandHandlerTests {

    private let clock = TestClock()

    @Test
    func testConnection() async throws {
        try await withMainSerialExecutor {
            let handler = HappyHandler(clock)
            #expect(handler.connectionState == .disconnected)
            await Task.yield()
            #expect(handler.connectionState == .connecting)
            await Task.yield()
            #expect(handler.connectionState == .connected)
        }
    }

    @Test
    func testConnectionFailure() async throws {
        try await withMainSerialExecutor {
            let handler = FailingConnectionHandler(clock)
            #expect(handler.connectionState == .disconnected)
            await Task.yield()
            #expect(handler.connectionState == .connecting)
            await waitForChanges(to: \.connectionState, on: handler)
            guard case .failed = handler.connectionState else {
                #expect(
                    false,
                    "Expected failed state. But got \(handler.connectionState)"
                )
                return
            }
        }
    }

    @Test
    func testHealthCheck() async throws {
        try await withMainSerialExecutor {
            let handler = HappyHandler(clock)
            await waitForConnected(handler)
            await clock.advance(by: .seconds(2))
            // We need to yield to let the health check task run
            await Task.yield()
            let timesCalled = await handler.state.healthCount
            #expect(timesCalled >= 1)
        }
    }

    @Test
    func testHealthCheckFailure() async throws {
        let handler = FailingHealthCheckHandler(clock)
        await waitForConnected(handler)
        #expect(handler.connectionState == .connected)

        // Advance clock to trigger health check
        await clock.advance(by: .seconds(1))

        // Wait for the state to change to failed
        await waitForChanges(to: \.connectionState, on: handler)

        guard case .failed = handler.connectionState else {
            #expect(
                Bool(false),
                "Expected failed state after health check, but got \(handler.connectionState)"
            )
            return
        }
    }

    @Test
    func testHealthCheckRecovery() async throws {
        let handlerState = HandlerState()
        let handler = FlakyHealthCheckHandler(clock, state: handlerState)

        // Wait for connection
        await waitForConnected(handler)
        #expect(handler.connectionState == .connected)

        // Advance clock for first (failing) health check
        await clock.advance(by: .seconds(1))
        await waitForChanges(to: \.connectionState, on: handler)
        guard case .failed = handler.connectionState else {
            #expect(
                Bool(false),
                "Expected failed state, got \(handler.connectionState)"
            )
            return
        }
        var count = await handlerState.healthCount
        #expect(count == 1)

        // Advance clock for second (successful) health check
        await clock.advance(by: .seconds(1))
        await waitForConnected(handler)
        #expect(handler.connectionState == .connected)
        count = await handlerState.healthCount
        #expect(count == 2)
    }

    private func waitForConnected(_ handler: CommandHandler) async {
        var changes = 0
        // We expect 2 changes: disconnected -> connecting -> connected
        while handler.connectionState != .connected && changes < 2 {
            await waitForChanges(to: \.connectionState, on: handler)
            changes += 1
        }
    }
}

func waitForChanges<T: Observable, U>(
    to keyPath: KeyPath<T, U>,
    on parent: T,
    timeout: Duration = .seconds(1)
) async {
    await withCheckedContinuation { continuation in
        withObservationTracking {
            _ = parent[keyPath: keyPath]
        } onChange: {
            continuation.resume()
        }
    }
}

enum TestTimeoutError: Error {
    case timedOut
}

func withTimeout<T>(
    seconds: TimeInterval,
    operation: @escaping () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        group.addTask {
            try await Task.sleep(for: .seconds(seconds))
            throw TestTimeoutError.timedOut
        }
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}
