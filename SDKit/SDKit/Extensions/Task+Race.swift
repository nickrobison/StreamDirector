//
//  Task+Race.swift
//  SDKit
//
//  Created by Nick Robison on 11/20/25.
//
import Foundation
import Clocks
import OSLog

enum TimeoutError: Error {
    case timeout
}

extension Task where Failure == Error {
    
    /// Races two asynchronous operations and returns the result of the one that finishes first.
    ///
    /// The other operation is cancelled immediately after the first one completes.
    ///
    /// Example:
    /// ```swift
    /// let task = Task.racing(
    ///     { try await fastOperation() },
    ///     { try await slowOperation() }
    /// )
    /// let result = try await task.value
    /// ```
    ///
    /// - Parameters:
    ///   - priority: The priority of the task. Defaults to `nil`.
    ///   - lhs: The first asynchronous operation.
    ///   - rhs: The second asynchronous operation.
    /// - Returns: A Task that produces the result of the first operation to finish or throws the first error encountered.
    public static func racing(
        priority: TaskPriority? = nil,
        _ lhs: @Sendable @escaping () async throws -> Success,
        _ rhs: @Sendable @escaping () async throws -> Success
    ) -> Task {
        return Task {
            try await withThrowingTaskGroup(of: Success.self) { group in
                group.addTask(priority: priority) { try await lhs()}
                group.addTask(priority: priority) {
                    try await rhs()
                }
                defer { group.cancelAll()}
                return try await group.next()!
                
            }
        }
    }
    
    /// Executes an asynchronous operation with a timeout.
    ///
    /// If the operation does not complete within the specified duration, it throws `TimeoutError.timeout`.
    ///
    /// Example:
    /// ```swift
    /// let task = Task.withTimeout(of: .seconds(2)) {
    ///     try await someLongRunningOperation()
    /// }
    /// do {
    ///     let result = try await task.value
    /// } catch is TimeoutError {
    ///     print("Operation timed out")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - clock: The clock to use for the timeout. Defaults to `.suspending`.
    ///   - priority: The priority of the task. Defaults to `nil`.
    ///   - logger: An optional logger to use for tracing. Defaults to `nil`.
    ///   - timeout: The maximum duration to allow for the operation.
    ///   - operation: The asynchronous operation to perform.
    /// - Returns: A Task that produces the result of the operation or throws `TimeoutError.timeout` if it exceeds the duration.
 public static func withTimeout(
    clock: any Clock<Duration> = .suspending,
    priority: TaskPriority? = nil,
    logger: Logger? = nil,
    of timeout: Duration,
    operation: @Sendable @escaping () async throws -> Success
 ) -> Task {
     return racing(priority: priority, operation, {
         try await clock.sleep(for: timeout)
         throw TimeoutError.timeout
     })
 }
}
