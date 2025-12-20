//
//  Stopwatch.swift
//  SDKit
//
//  Created by Nick Robison on 12/20/25.
//

import Foundation

public final class Stopwatch {
    
    public private(set) var isRunning: Bool = false
    public private(set) var started: TimeInterval = 0.0
    private var elapsedTime: TimeInterval = 0.0
    
    private let processInfo: ProcessInfo = ProcessInfo()
    
    public func start() {
        if (!isRunning) {
            started = processInfo.systemUptime
            isRunning = true
        }
    }
    
    public func stop() {
        if (isRunning) {
            elapsedTime += processInfo.systemUptime - started
            isRunning = false
            
        }
    }
    
    public func reset() {
        isRunning = false
        started = 0.0
        elapsedTime = 0.0
    }
    
    public func restart() {
        started = processInfo.systemUptime
        elapsedTime = 0.0
        isRunning = true
    }
    
    public var elapsed: Duration {
        get {
            var currentElapsed = elapsedTime
            if (isRunning) {
                currentElapsed += processInfo.systemUptime - started
            }
            return .seconds(currentElapsed)
        }
    }
}

extension Stopwatch: CustomDebugStringConvertible {
    public var debugDescription: String {
        "\(elapsed). IsRunning? \(isRunning)"
    }
}
