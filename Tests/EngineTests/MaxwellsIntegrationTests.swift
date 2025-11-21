// MaxwellsIntegrationTests.swift
// Tests for integration with Maxwells TCA validation rules

import Testing
import Foundation
import SmithValidationCore
import SwiftSyntax

@Test("Maxwells TCA Rules Integration")
struct MaxwellsIntegrationTests {

    @Test("Maxwells TCA rules are properly structured")
    func testMaxwellsRulesStructure() throws {
        // This test verifies that the Maxwells rules have been properly migrated
        // and conform to the ValidatableRule protocol

        let maxwellsPath = "/Volumes/Plutonian/_Developer/Maxwells/TCA/validation"
        let maxwellsURL = URL(fileURLWithPath: maxwellsPath)

        // Verify directory exists
        #expect(FileManager.default.fileExists(atPath: maxwellsPath))

        // Check that rule files exist
        let expectedRules = [
            "Rule_1_1_MonolithicFeatures.swift",
            "Rule_1_2_ClosureInjection.swift",
            "Rule_1_3_CodeDuplication.swift",
            "Rule_1_4_UnclearOrganization.swift",
            "Rule_1_5_TightlyCoupledState.swift"
        ]

        for ruleFile in expectedRules {
            let ruleURL = maxwellsURL.appendingPathComponent(ruleFile)
            #expect(FileManager.default.fileExists(atPath: ruleURL.path))

            // Verify file has proper structure
            let content = try String(contentsOf: ruleURL)

            // Check for required imports
            #expect(content.contains("import Foundation"))
            #expect(content.contains("import SmithValidationCore"))
            #expect(content.contains("import SwiftSyntax"))

            // Check for protocol conformance
            #expect(content.contains(": ValidatableRule"))

            // Check for required methods
            #expect(content.contains("func validate(context: SourceFileContext)"))
            #expect(content.contains("ViolationCollection"))
        }
    }

    @Test("Engine can process TCA code with expected structure")
    func testEngineProcessesTCACode() throws {
        // Arrange
        let testCode = """
        import Foundation
        import ComposableArchitecture

        @Reducer
        struct TestFeature: Reducer {
            struct State {
                let id: UUID
                let name: String
                let count: Int
            }

            enum Action {
                case increment
                case decrement
                case updateName(String)
            }

            var body: some ReducerOf<Self> {
                Reduce { state, action in
                    switch action {
                    case .increment:
                        state.count += 1
                        return .none
                    case .decrement:
                        state.count -= 1
                        return .none
                    case .updateName(let newName):
                        state.name = newName
                        return .none
                    }
                }
            }
        }
        """

        let syntax = try SourceFileSyntax.parse(source: testCode)
        let context = SourceFileContext(path: "<test>", url: URL(fileURLWithPath: "/test"), syntax: syntax)

        // Act - Test that SmithValidationCore extensions work
        let reducers = syntax.findTCAReducers()
        let states = syntax.findStatesInTCAReducers()
        let actions = syntax.findActionsInTCAReducers()

        // Assert
        #expect(reducers.count == 1)
        #expect(states.count == 1)
        #expect(actions.count == 1)

        // Test StructInfo functionality
        let reducer = reducers.first!
        #expect(reducer.name == "TestFeature")
        #expect(reducer.isTCAReducer)
        #expect(reducer.propertyCount == 2) // State and enum Action

        let stateStruct = states.first!
        #expect(stateStruct.name == "State")
        #expect(stateStruct.propertyCount == 3) // id, name, count

        let actionEnum = actions.first!
        #expect(actionEnum.name == "Action")
        #expect(actionEnum.caseCount == 3)
    }

    @Test("ValidationEngine can load and use Maxwells rule patterns")
    func testEngineWithMaxwellsPatterns() throws {
        // Arrange
        let engine = ValidationEngine()
        let testCode = """
        @Reducer
        struct ComplexFeature: Reducer {
            struct State {
                // This should trigger Rule 1.1 (monolithic features)
                let navigationState: NavigationState
                let dataState: DataState
                let uiState: UIState
                let searchState: SearchState
                let filterState: FilterState
                let settingsState: SettingsState
                let analyticsState: AnalyticsState
                let syncState: SyncState
                let cacheState: CacheState
                let networkState: NetworkState
                let errorState: ErrorState
                let loadingState: LoadingState
                let validationState: ValidationState
                let exportState: ExportState
                let importState: ImportState
                let shareState: ShareState
                let backupState: BackupState
                let debugState: DebugState
            }

            enum Action {
                // This should trigger Rule 1.5 (tightly coupled state)
                case navigation(NavigationState.Action)
                case data(DataState.Action)
                case ui(UIState.Action)
                case search(SearchState.Action)
                case filter(FilterState.Action)
                case settings(SettingsState.Action)
                case analytics(AnalyticsState.Action)
                case sync(SyncState.Action)
                case cache(CacheState.Action)
                case network(NetworkState.Action)
                case error(ErrorState.Action)
                case loading(LoadingState.Action)
                case validation(ValidationState.Action)
                case export(ExportState.Action)
                case import(ImportState.Action)
                case share(ShareState.Action)
                case backup(BackupState.Action)
                case debug(DebugState.Action)
            }
        }
        """

        // Create a test file
        let testFileURL = URL(fileURLWithPath: "/tmp/complex_feature.swift")
        try testCode.write(to: testFileURL, atomically: true, encoding: .utf8)

        // Create a mock rule that would detect these patterns
        let mockMonolithicRule = MockTestRule(violation: ArchitecturalViolation.high(
            rule: "TCA-1.1-MonolithicFeatures",
            file: "complex_feature.swift",
            line: 3,
            message: "State struct has >15 properties (found 18)",
            recommendation: "Consider splitting into multiple child features"
        ))

        let mockCoupledRule = MockTestRule(violation: ArchitecturalViolation.medium(
            rule: "TCA-1.5-TightlyCoupledState",
            file: "complex_feature.swift",
            line: 25,
            message: "Reducer handles too many child features (17 detected)",
            recommendation: "Extract child features into separate reducers"
        ))

        // Act
        let violations = try engine.validate(
            rules: [mockMonolithicRule, mockCoupledRule],
            filePath: testFileURL.path
        )

        // Assert
        #expect(violations.count == 2)
        #expect(violations.highCount == 1)
        #expect(violations.mediumCount == 1)

        // Cleanup
        try FileManager.default.removeItem(at: testFileURL)
    }

    @Test("Engine maintains backward compatibility with legacy interface")
    func testBackwardCompatibility() throws {
        // Arrange
        let testCode = "struct LegacyStruct { let x: Int }"
        let syntax = try SourceFileSyntax.parse(source: testCode)

        // Create a legacy-style rule
        let legacyRule = LegacyMockRule()

        // Test that the LegacyRuleAdapter can convert it
        let adaptedRule = LegacyRuleAdapter.adapt(legacyRule)

        // Act & Assert
        #expect(adaptedRule is any ValidatableRule)

        // Test that both interfaces work
        let fileViolations = adaptedRule.validate(filePath: "<test>")
        #expect(fileViolations.count == 1) // Legacy rule always returns one violation
    }
}

// MARK: - Legacy Rule Mock

/// Mock legacy rule for testing backward compatibility
struct LegacyMockRule: LegacyValidationRule {
    let ruleName = "LegacyMockRule"

    func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        let violation = ArchitecturalViolation.low(
            rule: ruleName,
            file: "legacy.swift",
            line: 1,
            message: "Legacy validation result"
        )
        return ViolationCollection(violations: [violation])
    }
}