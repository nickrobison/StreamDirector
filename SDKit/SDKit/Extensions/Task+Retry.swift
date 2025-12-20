//
//  Task+Retry.swift
//  SDKit
//
//  Created by Nick Robison on 12/18/25.
//
import Foundation
import Clocks
import OSLog

fileprivate func calculateDelay(minDelay: Duration, maxDelay: Duration, jitter: Double, attempt: Int) -> Duration {
    let rnd = 1.0 + Double.random(in: 0..<1) * jitter
    let newDelay = minDelay * pow(2.0, Double(attempt)) * rnd
    return min(newDelay, maxDelay)
}

extension Task where Failure == Error {
    
    /// Creates a new Task that retries the given operation upon failure.
    ///
    /// This method attempts to execute the `operation` up to `maxRetryCount` times.
    /// If the operation fails, it waits for a calculated delay before retrying.
    /// The delay increases exponentially with each attempt, modulated by a jitter factor.
    ///
    /// Example:
    /// ```swift
    /// let task = Task.retrying(times: 3) {
    ///     try await someFlakyOperation()
    /// }
    /// let result = try await task.value
    /// ```
    ///
    /// - Parameters:
    ///   - clock: The clock to use for sleeping between retries. Defaults to `.continuous`.
    ///   - priority: The priority of the task. Defaults to `nil`.
    ///   - maxRetryCount: The maximum number of times to attempt the operation. Defaults to 5. Must be greater than 0.
    ///   - minDelay: The base delay before the first retry. Defaults to 500 milliseconds.
    ///   - maxDelay: The maximum duration to wait between retries. Defaults to 30 seconds.
    ///   - jitter: A randomization factor for the delay. Defaults to 0.2.
    ///   - operation: The asynchronous operation to perform.
    /// - Returns: A Task that produces the result of the operation or throws the last error encountered.
    public static func retrying(
        clock: any Clock<Duration> = .suspending,
        priority: TaskPriority? = nil,
        times maxRetryCount: Int = 5,
        minDelay: Duration = .milliseconds(500),
        maxDelay: Duration = .seconds(30),
        jitter: Double = 0.2,
        logger: Logger? = nil,
        operation: sending @escaping () async throws -> Success
    ) -> Task {
        Task(priority: priority) {
            let attempts = max(1, maxRetryCount)
            let sw = Stopwatch()
            logger?.debug("Retrying with attempts: \(attempts). minDelay: \(minDelay), maxDelay: \(maxDelay) and jiter: \(jitter)")
            for attempt in 0..<attempts {
                do {
                    logger?.debug("Performing operation attempt: \(attempt)/\(maxRetryCount)")
                    sw.restart()
                    let res = try await operation()
                    logger?.debug("Operation attempt \(attempt) took \(sw.elapsed)")
                    return res
                } catch {
                    // If this was the last attempt, rethrow the error
                    if attempt == attempts - 1 {
                        throw error
                    }
                    logger?.error("Attempt: \(attempt) failed with error: \(error)")
                    let delay = calculateDelay(minDelay: minDelay, maxDelay: maxDelay, jitter: jitter, attempt: attempt)
                    logger?.debug("Sleeping for \(delay)")
                    try await clock.sleep(for: delay)
                }
            }
            // This path should technically be unreachable due to the loop logic and throw,
            // but is required for compilation if the compiler can't verify exhaustiveness.
            fatalError()
        }
    }
}
