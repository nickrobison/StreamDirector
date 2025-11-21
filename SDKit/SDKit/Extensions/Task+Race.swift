//
//  Task+Race.swift
//  SDKit
//
//  Created by Nick Robison on 11/20/25.
//

enum TimeoutError: Error {
    case timeout
}

func withTimeout<T: Sendable>(
    of timeout: Duration,
    _ work: @Sendable @escaping () async throws -> T
) async throws -> T {
    return try await race(
        work,
        {
            try await Task.sleep(until: .now + timeout)
            throw TimeoutError.timeout
        }
    )
}

// TODO: Sending??
func race<T: Sendable>(
    _ lhs: @Sendable @escaping () async throws -> T,
    _ rhs: @Sendable @escaping () async throws -> T
) async throws -> T {
    return try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await lhs() }
        group.addTask { try await rhs() }

        defer { group.cancelAll() }
        return try await group.next()!
    }
}
