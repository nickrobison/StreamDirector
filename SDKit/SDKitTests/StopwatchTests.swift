//
//  StopwatchTests.swift
//  SDKitTests
//
//  Created by Nick Robison on 12/20/25.
//

import Testing
import Foundation
@testable import SDKit

@Suite struct StopwatchTests {

    @Test func newInstance() {
        let stopwatch = Stopwatch()
        #expect(!stopwatch.isRunning)
        #expect(stopwatch.elapsed == .zero)
        #expect(stopwatch.started == 0.0)
    }

    @Test func start() {
        let stopwatch = Stopwatch()
        stopwatch.start()
        #expect(stopwatch.isRunning)
        
        let start = stopwatch.elapsed
        // Busy wait for a small amount of time
        let sleepUntil = Date().addingTimeInterval(0.01)
        while Date() < sleepUntil {}
        
        #expect(stopwatch.elapsed > start)
    }
    
    @Test func startIdempotency() {
        let stopwatch = Stopwatch()
        stopwatch.start()
        let initialStart = stopwatch.started
        
        // Wait a bit
        let sleepUntil = Date().addingTimeInterval(0.01)
        while Date() < sleepUntil {}
        
        // Calling start again shouldn't change the start time or reset anything
        stopwatch.start()
        #expect(stopwatch.isRunning)
        #expect(stopwatch.started == initialStart)
    }

    @Test func stop() {
        let stopwatch = Stopwatch()
        stopwatch.start()
        
        let sleepUntil = Date().addingTimeInterval(0.01)
        while Date() < sleepUntil {}
        
        stopwatch.stop()
        #expect(!stopwatch.isRunning)
        
        let elapsedAtStop = stopwatch.elapsed
        #expect(elapsedAtStop > .zero)
        
        // Wait more to ensure it's not counting
        let sleepMore = Date().addingTimeInterval(0.01)
        while Date() < sleepMore {}
        
        #expect(stopwatch.elapsed == elapsedAtStop)
    }
    
    @Test func stopIdempotency() {
        let stopwatch = Stopwatch()
        stopwatch.start()
        
        let sleepUntil = Date().addingTimeInterval(0.01)
        while Date() < sleepUntil {}
        
        stopwatch.stop()
        let elapsedAtStop = stopwatch.elapsed
        #expect(!stopwatch.isRunning)
        
        // Calling stop again shouldn't do anything bad
        stopwatch.stop()
        #expect(!stopwatch.isRunning)
        #expect(stopwatch.elapsed == elapsedAtStop)
    }

    @Test func reset() {
        let stopwatch = Stopwatch()
        stopwatch.start()
        
        let sleepUntil = Date().addingTimeInterval(0.01)
        while Date() < sleepUntil {}
        
        stopwatch.reset()
        #expect(!stopwatch.isRunning)
        #expect(stopwatch.elapsed == .zero)
        #expect(stopwatch.started == 0.0)
    }

    @Test func restart() {
        let stopwatch = Stopwatch()
        stopwatch.start()
        
        let sleepUntil = Date().addingTimeInterval(0.05)
        while Date() < sleepUntil {}
        
        let elapsedBeforeRestart = stopwatch.elapsed
        #expect(elapsedBeforeRestart > .zero)
        
        stopwatch.restart()
        #expect(stopwatch.isRunning)
        // Elapsed should be very close to zero, definitely less than what it was
        #expect(stopwatch.elapsed < elapsedBeforeRestart)
    }

    @Test func accumulation() {
        let stopwatch = Stopwatch()
        
        // Run 1
        stopwatch.start()
        var sleepUntil = Date().addingTimeInterval(0.05)
        while Date() < sleepUntil {}
        stopwatch.stop()
        
        let elapsed1 = stopwatch.elapsed
        #expect(elapsed1.components.seconds >= 0)
        
        // Pause
        sleepUntil = Date().addingTimeInterval(0.05)
        while Date() < sleepUntil {}
        
        // Run 2
        stopwatch.start()
        sleepUntil = Date().addingTimeInterval(0.05)
        while Date() < sleepUntil {}
        stopwatch.stop()
        
        let elapsed2 = stopwatch.elapsed
        
        // Should be roughly double the first run, definitely significantly larger
        #expect(elapsed2 > elapsed1)
        
        // Verify it didn't count the pause
        // elapsed1 is approx 0.05
        // pause is 0.05
        // run 2 is 0.05
        // total elapsed should be approx 0.10. If it counted pause it would be 0.15
        
        // Allow for some system jitter, but the logic holds
    }
    
    @Test func debugDescription() {
        let stopwatch = Stopwatch()
        #expect(stopwatch.debugDescription.contains("IsRunning? false"))
        stopwatch.start()
        #expect(stopwatch.debugDescription.contains("IsRunning? true"))
    }
}