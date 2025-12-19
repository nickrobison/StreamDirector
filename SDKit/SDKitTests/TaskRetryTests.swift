//
//  TaskRetryTests.swift
//  SDKit
//
//  Created by Nick Robison on 12/18/25.
//

import Testing
import Foundation
import Clocks
import OSLog
@testable import SDKit

struct TaskRetryTests {
    
    struct TestError: Error, Equatable {}

    @Test
    func testSuccessFirstTry() async throws {
        let task = Task.retrying(times: 3, minDelay: .milliseconds(1)) {
            return "Success"
        }
        
        let result = try await task.value
        #expect(result == "Success")
    }

    @Test
    func testSuccessAfterRetries() async throws {
        actor Counter {
            var count = 0
            func increment() { count += 1 }
            func getCount() -> Int { count }
        }
        let counter = Counter()
        let clock = TestClock()
        
        let task = Task.retrying(clock: clock, times: 5, minDelay: .seconds(1), jitter: 0) {
            await counter.increment()
            if await counter.getCount() < 3 {
                throw TestError()
            }
            return "Success"
        }
        
        // Wait for the task to start and fail the first time
        await Task.yield()
        await clock.advance(by: .seconds(1))
        
        // Wait for the second failure
        await Task.yield()
        await clock.advance(by: .seconds(2))
        
        // Third attempt should succeed
        let result = try await task.value
        #expect(result == "Success")
        let count = await counter.getCount()
        #expect(count == 3)
    }

    @Test
    func testFailureAfterMaxRetries() async throws {
        actor Counter {
            var count = 0
            func increment() { count += 1 }
            func getCount() -> Int { count }
        }
        let counter = Counter()
        let clock = TestClock()
        
        let task = Task<String, Error>.retrying(clock: clock, times: 3, minDelay: .seconds(1), jitter: 0) {
            await counter.increment()
            throw TestError()
        }
        
        // Attempt 1 fails. Sleep 1s.
        await Task.yield()
        await clock.advance(by: .seconds(1))
        
        // Attempt 2 fails. Sleep 2s.
        await Task.yield()
        await clock.advance(by: .seconds(2))
        
        // Attempt 3 fails. Rethrows.
        
        do {
            _ = try await task.value
            #expect(Bool(false), "Should have thrown an error")
        } catch {
            #expect(error is TestError)
        }
        
        let count = await counter.getCount()
        #expect(count == 3)
    }
    
    @Test
    func testZeroRetryCountDefaultsToOne() async throws {
        actor Counter {
            var count = 0
            func increment() { count += 1 }
            func getCount() -> Int { count }
        }
        let counter = Counter()
        
        // Pass 0, should default to 1 attempt (0 retries technically, but code ensures 1 run)
        let task = Task<String, Error>.retrying(times: 0, minDelay: .milliseconds(1)) {
            await counter.increment()
            throw TestError()
        }
        
        do {
            _ = try await task.value
        } catch {
            // Expected
        }
        
        let count = await counter.getCount()
        #expect(count == 1)
    }
    
    @Test
    func testCancellationStopsRetries() async throws {
        actor Counter {
            var count = 0
            func increment() { count += 1 }
            func getCount() -> Int { count }
        }
        let counter = Counter()
        let clock = TestClock()
        
        let task = Task<String, Error>.retrying(clock: clock, times: 10, minDelay: .seconds(1), jitter: 0) {
            await counter.increment()
            throw TestError()
        }
        
        // Let it run slightly to trigger at least one fail
        await Task.yield()
        
        // Cancel before advancing clock (while it's sleeping)
        task.cancel()
        
        // Advance clock to wake it up if needed, though cancellation should trigger immediately
        await clock.advance(by: .seconds(1))
        
        do {
            _ = try await task.value
            #expect(Bool(false), "Should have thrown CancellationError")
        } catch {
            // Task.sleep throws CancellationError when cancelled
            #expect(error is CancellationError || error is TestError) 
        }
        
        // Ensure it doesn't keep going
        await clock.advance(by: .seconds(100))
        
        let count = await counter.getCount()
        #expect(count < 10)
    }
}
