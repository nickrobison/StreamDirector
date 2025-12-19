//
//  TaskRetryTests.swift
//  SDKit
//
//  Created by Nick Robison on 12/18/25.
//

import Testing
import Foundation
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
        
        let task = Task.retrying(times: 5, minDelay: .milliseconds(1)) {
            await counter.increment()
            if await counter.getCount() < 3 {
                throw TestError()
            }
            return "Success"
        }
        
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
        
        let task = Task<String, Error>.retrying(times: 3, minDelay: .milliseconds(1)) {
            await counter.increment()
            throw TestError()
        }
        
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
        
        let task = Task<String, Error>.retrying(times: 10, minDelay: .milliseconds(100)) {
            await counter.increment()
            throw TestError()
        }
        
        // Let it run slightly to trigger at least one fail, then cancel
        try await Task.sleep(for: .milliseconds(50))
        task.cancel()
        
        do {
            _ = try await task.value
            #expect(Bool(false), "Should have thrown CancellationError")
        } catch {
            // Task.sleep throws CancellationError when cancelled, or the task mechanics might throw it
            #expect(error is CancellationError || error is TestError) 
        }
        
        // Wait a bit to ensure it doesn't keep going
        try await Task.sleep(for: .milliseconds(200))
        
        let count = await counter.getCount()
        // It shouldn't have run 10 times. Maybe 1 or 2.
        #expect(count < 10)
    }
}
