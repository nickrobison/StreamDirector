//
//  State.swift
//  SDKit
//
//  Created by Nick Robison on 11/16/25.
//

import Foundation
import Synchronization

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

}
