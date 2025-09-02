//
//  StaticStringMacroTests.swift
//  SDMacros
//
//  Created by Nick Robison on 9/1/25.
//
//#if canImport(SDMacrosMacros)
//import SDMacrosMacros

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(SDMacrosMacros)
    import SDMacrosMacros

    let testMacross: [String: Macro.Type] = [
        "staticURL": StaticURLMacro.self
    ]
#endif

final class StaticStringMacroTests: XCTestCase {
    func testMacro() throws {
        #if canImport(SDMacrosMacros)
            assertMacroExpansion(
                """
                #staticURL("ws://localhost")
                """,
                expandedSource: """
                    Foundation.URL(string: "ws://localhost")!
                    """,
                macros: testMacross
            )
        #else
            throw XCTSkip(noImportError)
        #endif
    }

    func testMacroRejectsInvalidURL() throws {
        #if canImport(SDMacrosMacros)
            assertMacroExpansion(
                """
                #staticURL("https:// nota  valid url1")
                """,
                expandedSource: """
                    #staticURL("https:// nota  valid url1")
                    """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "Argument is not a valid URL",
                        line: 1,
                        column: 1
                    )
                ],
                macros: testMacross
            )
        #else
            throw XCTSkip(noImportError)
        #endif
    }

    func testMacroRejectsNonStringLiteral() throws {
        #if canImport(SDMacrosMacros)
            assertMacroExpansion(
                """
                #staticURL(1234)
                """,
                expandedSource: """
                    #staticURL(1234)
                    """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "Argument is not a string literal",
                        line: 1,
                        column: 1
                    )
                ],
                macros: testMacross
            )
        #else
            throw XCTSkip(noImportError)
        #endif
    }
}
