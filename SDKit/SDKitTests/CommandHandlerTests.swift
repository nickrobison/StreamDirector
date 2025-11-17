//
//  CommandHandlerTests.swift
//  SDKit
//
//  Created by Nick Robison on 11/16/25.
//

import Testing
import Clocks
import OSLog
import ConcurrencyExtras
@testable import SDKit
internal import Mocking

fileprivate let testLogger = Logger(subsystem: "com.nickrobison.SDKit", category: "Testing")

private actor HandlerState {
    var healthCount: Int = 0
    
    func incHealthCount() {
        healthCount += 1
    }
}

fileprivate class HappyHandler: CommandHandler {
    
    let state: HandlerState = HandlerState()
    
    override func doConnect() async -> Result<(), any Error> {
        await Task.yield()
        return .success(())
    }
    
    override func doHealthCheck() async -> Result<(), any Error> {
        await state.incHealthCount()
        return .success(())
    }
    
    
    
    init(_ clock: any Clock<Duration>) {
        super.init(logger: testLogger, config: CommandHandlerConfig(), clock: clock)
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
    func testHealthCheck() async throws {
        let handler = HappyHandler(clock)
        await waitForChanges(to: \.connectionState, on: handler)
        await clock.advance(by: .seconds(2))
        let timesCalled = await handler.state.healthCount
        #expect(timesCalled >= 1)
        
    }
}

func waitForChanges<T, U>(to keyPath: KeyPath<T, U>, on parent: T, timeout: Duration = .seconds(1)) async {
    await withCheckedContinuation { continuation in
        withObservationTracking {
            _ = parent[keyPath: keyPath]
        } onChange: {
            continuation.resume()
        }
    }
}
