//
//  State.swift
//  SDKit
//
//  Created by Nick Robison on 11/16/25.
//

import Foundation
import Synchronization

/// A thread-safe wrapper for a value type.
///
/// The `State` class provides a way to manage shared mutable state in a concurrent environment,
/// ensuring that all access to the underlying value is synchronized. It uses a `Mutex` to protect the data.
///
/// This class is compatible with Swift 6 concurrency and is `@unchecked Sendable` because the internal synchronization mechanism ensures safety.
///
/// It uses `@dynamicMemberLookup` to provide direct access to the properties of the wrapped value.
///
/// Example:
/// ```
/// struct MyState: Sendable {
///     var counter = 0
/// }
///
/// let state = State(MyState())
///
/// // Access and modify properties concurrently
/// Task {
///     state.counter += 1
/// }
///
/// Task {
///     state.counter += 1
/// }
///
/// // The final value will be 2
/// ```
@dynamicMemberLookup
public final class State<S: Sendable>: @unchecked Sendable {
    private let _data: Mutex<S>

    var data: S {
        get {
            return self._data.withLock { $0 }
        }
        set {
            self._data.withLock { d in
                d = newValue
            }
        }
    }

    public init(_ initialValue: S) {
        self._data = Mutex(initialValue)
    }
    
    public subscript<T: Sendable>(dynamicMember keyPath: WritableKeyPath<S, T>) -> T {
        get {
            return self._data.withLock { d in
                return d[keyPath: keyPath]
            }
        }
        set
        {
            self._data.withLock { d in
                d[keyPath: keyPath] = newValue
            }
        }
    }

    /// Performs a given closure while holding the lock.
    ///
    /// Use this method to perform a series of operations atomically.
    /// The closure receives a mutable reference to the underlying state.
    ///
    /// - Parameter body: A closure that takes an `inout` reference to the state.
    /// - Returns: The value returned by the closure.
    public func withLock<T>(_ body: (inout S) throws -> T) rethrows -> T {
        return try self._data.withLock(body)
    }

}
