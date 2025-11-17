//
//  StateTests.swift
//  SDKitTests
//
//  Created by Nick Robison on 11/16/25.
//

import Testing
@testable import SDKit

struct StateTests {

    private struct TestState: Sendable {
        var value1: Int
        var value2: String
    }
    
    @Test
    func simpleGetSet() throws {
        let state = State(100)
        #expect(state.data == 100)
        state.data = 42
        #expect(state.data == 42)
    }

    @Test
    func dynamicMemberGetSet() throws {
        let state = State(TestState(value1: 24, value2: "test"))
        #expect(state.value1 == 24)
        #expect(state.value2 == "test")

        state.value1 = 42
        state.value2 = "hello"

        #expect(state.value1 == 42)
        #expect(state.value2 == "hello")
    }

    @Test
    func concurrentDynamicMemberUpdates() async throws {
        let state = State(TestState(value1: 0, value2: "base"))

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    state.withLock { state in
                        state.value1 += 1
                    }
                }
            }
        }

        #expect(state.value1 == 100)
    }
}
