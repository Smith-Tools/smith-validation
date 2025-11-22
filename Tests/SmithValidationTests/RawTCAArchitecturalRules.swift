// Tests/SmithValidationTests/RawTCAArchitecturalRules.swift
// Raw Swift Testing output for TCA architectural validation

import Foundation
import Testing

@Suite("TCA Architectural Rules - Raw Testing Output")
struct RawTCAArchitecturalRules {

    /// Test that TCA reducers have proper error handling
    @Test("Reducers should have error handling")
    func reducerErrorHandling() async throws {
        let testCases = [
            // Case 1: Missing error handling - should FAIL
            """
            @Reducer
            struct BadFeatureReducer {
                struct State { var items: [String] = [] }
                enum Action {
                    case loadItems
                    case itemsLoaded([String])
                    // Missing error cases
                }
            }
            """,

            // Case 2: Has error handling - should PASS
            """
            @Reducer
            struct GoodFeatureReducer {
                struct State { var items: [String] = [] }
                enum Action {
                    case loadItems
                    case itemsLoaded([String])
                    case loadFailed(Error)
                }
            }
            """
        ]

        for (index, testCase) in testCases.enumerated() {
            let hasErrorHandling = analyzeErrorHandling(in: testCase)

            if index == 0 { // First case should fail
                #expect(hasErrorHandling == false, "Expected missing error handling in reducer \(index + 1)")
                print("✅ Test Case \(index + 1): Correctly identified missing error handling")
            } else { // Second case should pass
                #expect(hasErrorHandling == true, "Expected error handling in reducer \(index + 1)")
                print("✅ Test Case \(index + 1): Correctly found error handling")
            }
        }
    }

    /// Test that TCA features aren't monolithic
    @Test("Features should not be monolithic")
    func featureMonolithicCheck() async throws {
        let testCases = [
            // Case 1: Monolithic State - should FAIL
            """
            @Reducer
            struct MonolithicFeatureReducer {
                struct State {
                    var data1: String
                    var data2: String
                    var data3: String
                    var data4: String
                    var data5: String
                    var data6: String
                    var data7: String
                    var data8: String
                    var data9: String
                    var data10: String
                    var data11: String
                    var data12: String
                    var data13: String
                    var data14: String
                    var data15: String
                    var data16: String  // Over threshold
                }
                enum Action { case doSomething }
            }
            """,

            // Case 2: Proper sized State - should PASS
            """
            @Reducer
            struct ProperFeatureReducer {
                struct State {
                    var data1: String
                    var data2: String
                    var data3: String
                    var data4: String
                    var data5: String
                    var data6: String
                    var data7: String
                    var data8: String
                    var data9: String
                    var data10: String
                    // Under threshold
                }
                enum Action { case doSomething }
            }
            """
        ]

        for (index, testCase) in testCases.enumerated() {
            let propertyCount = countStateProperties(in: testCase)
            let isMonolithic = propertyCount > 15

            if index == 0 { // First case should fail
                #expect(isMonolithic == true, "Expected monolithic State with \(propertyCount) properties")
                print("✅ Test Case \(index + 1): Correctly identified monolithic State (\(propertyCount) properties)")
            } else { // Second case should pass
                #expect(isMonolithic == false, "Expected properly sized State with \(propertyCount) properties")
                print("✅ Test Case \(index + 1): Correctly validated State size (\(propertyCount) properties)")
            }
        }
    }

    @Test("Complex real-world validation")
    func complexRealWorldValidation() async throws {
        // Simulate a complex TCA feature from Scroll project
        let realWorldCode = """
        import Foundation
        import ComposableArchitecture

        @Reducer
        struct ArticleReadingFeature {
            struct State: Equatable {
                var article: Article?
                var isLoading: Bool = false
                var error: String?
                var bookmarks: [Bookmark] = []
                var highlights: [Highlight] = []
                var readingProgress: Double = 0.0
                var fontSize: FontSize = .medium
                var theme: ReadingTheme = .light
                var settings: ReadingSettings
                var analytics: ReadingAnalytics
                var networkStatus: NetworkStatus
                var cacheState: CacheState
                var syncState: SyncState
                var userPreferences: UserPreferences
                var accessibilityOptions: AccessibilityOptions
                var performanceMetrics: PerformanceMetrics
                var debugInfo: DebugInfo
                var metadata: ArticleMetadata
                // This will trigger monolithic warning
            }

            enum Action {
                case loadArticle(String)
                case articleLoaded(Article)
                case loadFailed(String)  // Has error handling
                case bookmarkArticle
                case addHighlight(Highlight)
                case updateReadingProgress(Double)
                case changeFontSize(FontSize)
                case toggleTheme
                case refreshContent
                case clearCache
                case syncData
            }
        }

        struct Article { let id: String; let title: String }
        struct Bookmark { let id: String; let articleId: String }
        struct Highlight { let id: String; let text: String }
        // ... other supporting types
        """

        let hasErrorHandling = analyzeErrorHandling(in: realWorldCode)
        let propertyCount = countStateProperties(in: realWorldCode)
        let isMonolithic = propertyCount > 15

        print("🔍 Real-world Analysis Results:")
        print("   📊 State properties: \(propertyCount)")
        print("   🚫 Monolithic: \(isMonolithic ? "YES" : "NO")")
        print("   ✅ Error handling: \(hasErrorHandling ? "YES" : "NO")")

        // Should have error handling but be monolithic
        #expect(hasErrorHandling == true, "Expected error handling in real-world code")
        #expect(isMonolithic == true, "Expected monolithic State with \(propertyCount) properties")

        print("✅ Real-world validation: Correctly identified both good and bad patterns")
    }

    // MARK: - Analysis Methods

    private func analyzeErrorHandling(in source: String) -> Bool {
        let lines = source.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            if line.contains("enum Action") {
                // Look for error-related cases in the following lines
                let actionBlock = lines.dropFirst(index).prefix(20)
                return actionBlock.contains { actionLine in
                    actionLine.lowercased().contains("error") ||
                    actionLine.lowercased().contains("failure") ||
                    actionLine.lowercased().contains("failed")
                }
            }
        }
        return false
    }

    private func countStateProperties(in source: String) -> Int {
        let lines = source.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            if line.contains("struct State") {
                // Count properties in this struct
                let structBlock = lines.dropFirst(index)
                var propertyCount = 0
                var braceDepth = 0

                for blockLine in structBlock {
                    if blockLine.contains("{") {
                        braceDepth += 1
                    } else if blockLine.contains("}") {
                        braceDepth -= 1
                        if braceDepth == 0 { break }
                    } else if braceDepth == 1 && (blockLine.trimmingCharacters(in: .whitespaces).hasPrefix("var ") || blockLine.trimmingCharacters(in: .whitespaces).hasPrefix("let ")) {
                        propertyCount += 1
                    }
                }
                return propertyCount
            }
        }
        return 0
    }
}
