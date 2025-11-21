//
//  ObservedState.swift
//  SDKit
//
//  Created by Nick Robison on 11/20/25.
//

import Observation

@propertyWrapper
public struct ObservedState<T: Observable, Value, S: Sendable> {
    
    public static subscript(
        _enclosingInstance instance: T,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<T, Self>
    ) -> Value {
        get {
            let skp = instance[keyPath: storageKeyPath].stateKeyPath
            let vkp = instance[keyPath: storageKeyPath].valueKeyPath
            let state = instance[keyPath: skp]
            return state.data[keyPath: vkp]
        }
        set {
            let skp = instance[keyPath: storageKeyPath].stateKeyPath
            let vkp = instance[keyPath: storageKeyPath].valueKeyPath
            instance[keyPath: skp].data[keyPath: vkp] = newValue
        }
    }
    
    @available(
        *,
        unavailable,
        message: "@ObservedState Can only be applied to classes"
    )
    public var wrappedValue: Value {
        get { fatalError() }
        set { fatalError() }
    }
    
    private let stateKeyPath: KeyPath<T, State<S>>
    private let valueKeyPath: WritableKeyPath<S, Value>
    
    public init(stateKeyPath: KeyPath<T, State<S>>, valueKeyPath: WritableKeyPath<S, Value>) {
        self.stateKeyPath = stateKeyPath
        self.valueKeyPath = valueKeyPath
    }
}
