//
//  StateTests.swift
//  SDKitTests
//
//  Created by Nick Robison on 11/16/25.
//

import Testing
@testable import SDKit

struct StateTests {
    
    @Test
    func simpleGetSet() throws {
        let state = State(100)
        #expect(state.data == 100)
        state.data = 42
        #expect(state.data == 42)
    }
}
