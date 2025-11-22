// BasicTests.swift
// Basic Swift Testing tests for smith-validation

import Testing
import Foundation

@testable import smith_validation

struct BasicTests {

    @Test("Package can import smith-validation module")
    func testCanImportSmithValidation() throws {
        // This test verifies that the smith-validation module can be imported
        #expect(Bool(true), "Should be able to import smith-validation module")
    }
}
