//
//  TaskRaceTests.swift
//  SDKit
//
//  Created by Nick Robison on 12/19/25.
//

import Testing
import Foundation
import Clocks
@testable import SDKit

struct TaskRaceTests {
    
    @Test
    func testRaceLhsWins() async throws {
        let task = Task<String, Error>.racing(
            {
                try await Task.sleep(for: .milliseconds(10))
                return "LHS"
            },
            {
                try await Task.sleep(for: .milliseconds(100))
                return "RHS"
            }
        )
        
        let result = try await task.value
        #expect(result == "LHS")
    }
    
    @Test
    func testRaceRhsWins() async throws {
        let task = Task<String, Error>.racing(
            {
                try await Task.sleep(for: .milliseconds(100))
                return "LHS"
            },
            {
                try await Task.sleep(for: .milliseconds(10))
                return "RHS"
            }
        )
        
        let result = try await task.value
        #expect(result == "RHS")
    }
    
    @Test
    func testRaceLhsThrows() async throws {
        struct TestError: Error {}
        
        let task = Task<String, Error>.racing(
            {
                throw TestError()
            },
            {
                try await Task.sleep(for: .milliseconds(100))
                return "RHS"
            }
        )
        
        do {
            _ = try await task.value
            #expect(Bool(false), "Should have thrown an error")
        } catch {
            #expect(error is TestError)
        }
    }
    
    @Test
    func testWithTimeoutSuccess() async throws {
        let clock = TestClock()
        let task = Task<String, Error>.withTimeout(clock: clock, of: .seconds(5)) {
            return "Success"
        }
        
        let result = try await task.value
        #expect(result == "Success")
    }
    
    @Test
    func testWithTimeoutFails() async throws {
        let clock = TestClock()
        let task = Task<String, Error>.withTimeout(clock: clock, of: .seconds(5)) {
            try await clock.sleep(for: .seconds(10))
            return "Success"
        }
        
        // Advance clock to trigger timeout
        await Task.yield()
        await clock.advance(by: .seconds(5))
        
        do {
            _ = try await task.value
            #expect(Bool(false), "Should have timed out")
        } catch {
            #expect(error is TimeoutError)
        }
    }
    
    @Test
    func testWithTimeoutCancellation() async throws {
        let clock = TestClock()
        let task = Task<String, Error>.withTimeout(clock: clock, of: .seconds(5)) {
            try await clock.sleep(for: .seconds(10))
            return "Success"
        }
        
        task.cancel()
        
        do {
            _ = try await task.value
            #expect(Bool(false), "Should have been cancelled")
        } catch {
            #expect(error is CancellationError)
        }
    }
}
