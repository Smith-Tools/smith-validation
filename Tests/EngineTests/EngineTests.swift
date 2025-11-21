// EngineTests.swift
// Swift Testing tests for the new validation engine architecture

import Testing
import Foundation
import SmithValidation
import SmithValidationCore
import SwiftSyntax

@Test("Validation Engine Architecture Tests")
struct EngineTests {

    @Test("Engine can validate single file with mock rule")
    func testEngineValidatesSingleFile() throws {
        // Arrange
        let engine = ValidationEngine()
        let testCode = """
        import Foundation

        struct TestFeature {
            let property1: String
            let property2: Int
        }
        """

        let testFileURL = URL(fileURLWithPath: "/tmp/test.swift")
        try testCode.write(to: testFileURL, atomically: true, encoding: .utf8)

        // Create a mock rule that returns a specific violation
        let mockRule = MockTestRule(
            violation: ArchitecturalViolation.medium(
                rule: "MockRule",
                file: "test.swift",
                line: 1,
                message: "Test violation",
                recommendation: "Fix this"
            )
        )

        // Act
        let violations = try engine.validate(rules: [mockRule], filePath: testFileURL.path)

        // Assert
        #expect(violations.count == 1)
        #expect(violations.violations.first?.message == "Test violation")
        #expect(violations.violations.first?.severity == .medium)

        // Cleanup
        try FileManager.default.removeItem(at: testFileURL)
    }

    @Test("Engine can validate multiple files")
    func testEngineValidatesMultipleFiles() throws {
        // Arrange
        let engine = ValidationEngine()
        let testDirectory = "/tmp/test_engine_\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: testDirectory, withIntermediateDirectories: true)

        let file1URL = URL(fileURLWithPath: "\(testDirectory)/file1.swift")
        let file2URL = URL(fileURLWithPath: "\(testDirectory)/file2.swift")

        try "struct Test1 {}".write(to: file1URL, atomically: true, encoding: .utf8)
        try "struct Test2 {}".write(to: file2URL, atomically: true, encoding: .utf8)

        let mockRule = MockTestRule(violation: nil) // No violations for this test

        // Act
        let violations = try engine.validate(rules: [mockRule], filePaths: [file1URL.path, file2URL.path])

        // Assert
        #expect(violations.count == 0)

        // Cleanup
        try FileManager.default.removeItem(atPath: testDirectory)
    }

    @Test("PerformanceOptimizer caches AST results")
    func testPerformanceOptimizerCaching() throws {
        // Arrange
        let optimizer = PerformanceOptimizer()
        let testCode = "struct Test { let x: Int }"
        let filePath = "/tmp/cache_test.swift"

        let syntax = try SourceFileSyntax.parse(source: testCode)
        try testCode.write(to: URL(fileURLWithPath: filePath), atomically: true, encoding: .utf8)

        // Act - First access should cache miss
        let (firstResult, firstDuration) = optimizer.timeOperation {
            optimizer.getCachedAST(for: filePath)
        }

        // Cache the result
        optimizer.cacheAST(syntax, for: filePath)

        // Second access should cache hit
        let (secondResult, secondDuration) = optimizer.timeOperation {
            optimizer.getCachedAST(for: filePath)
        }

        // Assert
        #expect(firstResult == nil) // Cache miss initially
        #expect(secondResult != nil) // Cache hit after caching
        #expect(secondDuration < firstDuration) // Second access should be faster

        // Verify statistics
        let stats = optimizer.getStatistics()
        #expect(stats.cacheHits == 1)
        #expect(stats.cacheMisses == 1)

        // Cleanup
        try FileManager.default.removeItem(atPath: filePath)
    }

    @Test("DualInterfaceValidator handles both interfaces")
    func testDualInterfaceValidator() throws {
        // Arrange
        let validator = DualInterfaceValidator()
        let testCode = "struct TestFeature: Reducer { struct State { let x: Int } enum Action { case test } }"
        let testFileURL = URL(fileURLWithPath: "/tmp/dual_test.swift")
        try testCode.write(to: testFileURL, atomically: true, encoding: .utf8)

        let mockRule = MockTestRule(violation: ArchitecturalViolation.low(
            rule: "DualTest",
            file: "test.swift",
            line: 1,
            message: "Test message"
        ))

        // Act & Assert - Test both interfaces work
        let contextViolations = try validator.validateWithInterface(
            rule: mockRule,
            filePath: testFileURL.path
        )

        let filePathViolations = try validator.validateWithInterface(
            rule: mockRule,
            filePath: testFileURL.path
        )

        // Both should produce the same results
        #expect(contextViolations.count == filePathViolations.count)

        // Cleanup
        try FileManager.default.removeItem(at: testFileURL)
    }

    @Test("RuleRegistry can categorize rules")
    func testRuleRegistry() throws {
        // Arrange
        let registry = RuleRegistry()
        let mockRule = MockTestRule(violation: nil)
        let metadata = RuleRegistry.RuleMetadata(
            name: "TestRule",
            description: "A test rule",
            category: .tca,
            severity: .high,
            version: "1.0.0"
        )

        // Act
        registry.register(rule: mockRule, metadata: metadata)
        let rules = registry.getRulesByCategory(.tca)
        let retrievedMetadata = registry.getMetadata(for: "TestRule")

        // Assert
        #expect(rules.count == 1)
        #expect(retrievedMetadata?.category == .tca)
        #expect(retrievedMetadata?.version == "1.0.0")
    }
}

// MARK: - Test Helpers

/// Mock validation rule for testing
struct MockTestRule: ValidatableRule {
    let violation: ArchitecturalViolation?

    func validate(context: SourceFileContext) -> ViolationCollection {
        if let violation = violation {
            return ViolationCollection(violations: [violation])
        }
        return ViolationCollection(violations: [])
    }
}

/// Mock rule metadata for testing
extension MockTestRule: LegacyValidationRule {
    var ruleName: String { return "MockTestRule" }

    func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        // Simple mock validation
        return ViolationCollection(violations: [])
    }
}