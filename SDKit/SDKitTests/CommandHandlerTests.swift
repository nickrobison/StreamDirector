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

@Observable
private final class HappyHandler: CommandHandler {

    let _connectionState: State<ConnectionState>

    var connectionState: ConnectionState {
        get {
            self.access(keyPath: \.connectionState)
            return _connectionState.data
        }
        set {
            self.withMutation(keyPath: \.connectionState) {
                _connectionState.data = newValue
            }
        }
    }

    let clock: any Clock<Duration>

    @ObservationIgnored
    let healthTask: State<Task<(), Never>?>

    let logger: Logger

    let state: HandlerState

    func doConnect() async -> Result<(), any Error> {
        await Task.yield()
        return .success(())
    }

    func doHealthCheck() async -> Result<(), any Error> {
        await state.incHealthCount()
        return .success(())
    }

    init(_ clock: any Clock<Duration>, state: HandlerState = HandlerState()) {
        self.state = state
        self.clock = clock
        self.logger = testLogger
        self._connectionState = .init(.disconnected)
        self.healthTask = .init(nil)
        Task {
            await connect(config: CommandHandlerConfig())
        }
    }
}

@Observable
private final class FailingConnectionHandler: CommandHandler {
    enum TestError: Error {
        case connectionFailed
    }


    let _connectionState: State<ConnectionState>

    var connectionState: ConnectionState {
        get {
            self.access(keyPath: \.connectionState)
            return _connectionState.data
        }
        set {
            self.withMutation(keyPath: \.connectionState) {
                _connectionState.data = newValue
            }
        }
    }

    let clock: any Clock<Duration>

    @ObservationIgnored
    let healthTask: State<Task<(), Never>?>

    let logger: Logger

    let state: HandlerState

    func doConnect() async -> Result<(), any Error> {
        debugPrint("I'm doing to fail")
        await Task.yield()
        return .failure(TestError.connectionFailed)
    }

    func doHealthCheck() async -> Result<(), any Error> {
        await state.incHealthCount()
        return .success(())
    }

    init(_ clock: any Clock<Duration>, state: HandlerState = HandlerState()) {
        self.state = state
        self.clock = clock
        self.logger = testLogger
        self._connectionState = .init(.disconnected)
        self.healthTask = .init(nil)
        Task {
            await connect(config: CommandHandlerConfig())
        }
    }
}

@Observable
private final class FailingHealthCheckHandler: CommandHandler {
    enum TestError: Error {
        case healthCheckFailed
    }

    let _connectionState: State<ConnectionState>

    var connectionState: ConnectionState {
        get {
            self.access(keyPath: \.connectionState)
            return _connectionState.data
        }
        set {
            self.withMutation(keyPath: \.connectionState) {
                _connectionState.data = newValue
            }
        }
    }

    let clock: any Clock<Duration>

    @ObservationIgnored
    let healthTask: State<Task<(), Never>?>

    let logger: Logger

    let state: HandlerState

    func doConnect() async -> Result<(), any Error> {
        await Task.yield()
        return .success(())
    }

    func doHealthCheck() async -> Result<(), any Error> {
        await Task.yield()
        return .failure(TestError.healthCheckFailed)
    }

    init(_ clock: any Clock<Duration>, state: HandlerState = HandlerState()) {
        self.state = state
        self.clock = clock
        self.logger = testLogger
        self._connectionState = .init(.disconnected)
        self.healthTask = .init(nil)
        Task {
            await connect(config: CommandHandlerConfig())
        }
    }
}


@Observable
private final class FlakyHealthCheckHandler: CommandHandler {
    enum TestError: Error {
        case healthCheckFailed
    }

    private let state: HandlerState

    let _connectionState: State<ConnectionState>
    let logger: Logger

    var connectionState: ConnectionState {
        get {
            self.access(keyPath: \.connectionState)
            return _connectionState.data
        }
        set {
            self.withMutation(keyPath: \.connectionState) {
                _connectionState.data = newValue
            }
        }
    }

    let clock: any Clock<Duration>

    @ObservationIgnored
    let healthTask: State<Task<(), Never>?>

    func doConnect() async -> Result<(), any Error> {
        await Task.yield()
        return .success(())
    }

    func doHealthCheck() async -> Result<(), any Error> {
        let count = await state.healthCount
        await state.incHealthCount()
        if count == 0 {
            return .failure(TestError.healthCheckFailed)
        }
        return .success(())
    }

    init(_ clock: any Clock<Duration>, state: HandlerState = HandlerState()) {
        self.state = state
        self.clock = clock
        self.logger = testLogger
        self._connectionState = .init(.disconnected)
        self.healthTask = .init(nil)
        Task {
            await connect(config: CommandHandlerConfig())
        }
    }
}

struct CommandHandlerTests {

    private let clock = TestClock()

    @Test
    func testConnection() async throws {
        await withMainSerialExecutor {
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
            _ = try await waitUntil(path: \.connectionState, on: handler) { state in
                guard case .failed = handler.connectionState else {
                    return false
                }
                return true
            }
        }
    }

    @Test
    func testHealthCheck() async throws {
        let handler = HappyHandler(clock)
        try await waitForConnected(handler)
        debugPrint("Connected")
        await clock.advance(by: .seconds(2))
        debugPrint("Advanced")
        // We need to yield to let the health check task run
        await Task.yield()
        let timesCalled = await handler.state.healthCount
        #expect(timesCalled >= 1)
    }

    @Test
    func testHealthCheckFailure() async throws {
        let handler = FailingHealthCheckHandler(clock)
        try await waitForConnected(handler)
        #expect(handler.connectionState == .connected)

        debugPrint("Advancing")
        // Advance clock to trigger health check
        await clock.advance(by: .seconds(1))

        // Wait for the state to change to failed
        _ = try await waitUntil(path: \.connectionState, on: handler) { state in
            guard case .failed = handler.connectionState else {
                return false
            }
            return true
        }
    }

    @Test
    func testHealthCheckRecovery() async throws {
        let handlerState = HandlerState()
        let handler = FlakyHealthCheckHandler(clock, state: handlerState)

        // Wait for connection
        try await waitForConnected(handler)
        #expect(handler.connectionState == .connected)

        // Advance clock for first (failing) health check
        await clock.advance(by: .seconds(1))
        _ = try await waitUntil(path: \.connectionState, on: handler) { state in
            guard case .failed = handler.connectionState else {
                return false
            }
            return true
        }
        var count = await handlerState.healthCount
        #expect(count == 1)

        // Advance clock for second (successful) health check
        await clock.advance(by: .seconds(1))
        try await waitForConnected(handler)
        #expect(handler.connectionState == .connected)
        count = await handlerState.healthCount
        #expect(count == 2)
    }

    private func waitForConnected(_ handler: HappyHandler) async throws {
        debugPrint("Wait for connected")
        try await waitUntil(
            path: \.connectionState,
            on: handler
        ) { result in
            return result == .connected
        }
    }
    private func waitForConnected(_ handler: FailingHealthCheckHandler) async throws {
        debugPrint("Wait for connected")
        try await waitUntil(
            path: \.connectionState,
            on: handler
        ) { result in
            return result == .connected
        }
    }
    
    private func waitForConnected(_ handler: FlakyHealthCheckHandler) async throws {
        debugPrint("Wait for connected")
        try await waitUntil(
            path: \.connectionState,
            on: handler
        ) { result in
            return result == .connected
        }
    }
}

func waitForChanges<T: Observable, U: Sendable>(
    to keyPath: KeyPath<T, U>,
    on parent: T,
    timeout: Duration = .seconds(1)
) async -> U {
    await withCheckedContinuation { continuation in
        withObservationTracking {
            let res = parent[keyPath: keyPath]
            debugPrint("I have value: \(res)")
            continuation.resume(returning: res)
        } onChange: {
            debugPrint("I changed")
        }
    }
}

func waitUntil<T: Observable, U: Sendable & Equatable>(
    path keyPath: KeyPath<T, U>,
    on parent: T,
    timeout: Duration = .seconds(1),
    _ predicate: @escaping (U?) -> Bool,
) async throws {
    debugPrint("First wait")
    debugPrint("Let's wait for this")
    var result: U? = nil
    while (!predicate(result)) {
        result = await waitForChanges(to: keyPath, on: parent)
        debugPrint("Changed!")
    }
}
