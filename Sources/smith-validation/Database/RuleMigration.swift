import Foundation
import SQLite

/// Migration utility to convert existing Swift rules to JavaScript rules
class RuleMigration {
    private let database: RuleDatabase

    init(database: RuleDatabase) {
        self.database = database
    }

    /// Migrate all existing Swift rules to JavaScript rules in the database
    func migrateExistingRules() {
        print("🔄 Starting migration of existing Swift rules to JavaScript...")

        // Clear existing sample rules
        clearSampleRules()

        // Migrate TCA Rules
        migrateTCARules()

        // Migrate SwiftUI Rules
        migrateSwiftUIRules()

        // Migrate General Rules
        migrateGeneralRules()

        // Migrate Performance Rules
        migratePerformanceRules()

        print("✅ Migration completed! All existing rules converted to JavaScript.")
    }

    private func clearSampleRules() {
        print("🗑️ Clearing sample rules...")
        // Deactivate sample rules instead of deleting them
        database.deactivateRule(1) // NamingConvention
        database.deactivateRule(2) // StructSize
        database.deactivateRule(3) // AsyncErrorHandling
    }

    private func migrateTCARules() {
        print("📱 Migrating TCA rules...")

        let tcaRules = [
            // TCA 1.1: Monolithic Features
            DatabaseRule(
                id: Optional<Int64>.none,
                name: "TCA 1.1: Monolithic Features",
                domain: "tca",
                patternPrompt: "Detect monolithic TCA features with too many state properties or action cases",
                templateType: "TCA_MonolithicFeatures",
                jsCode: """
                    // TCA Rule 1.1: Monolithic Features Validator
                    // Detects State structs with >15 properties and Action enums with >40 cases

                    const maxStateProperties = 15;
                    const maxActionCases = 40;

                    const classes = ASTBridge.getClasses().filter(cls => cls.kind.includes('struct'));

                    classes.forEach(cls => {
                        // Check if this could be a TCA State struct
                        if (cls.name === 'State' || cls.name.endsWith('State')) {
                            const propertyCount = ASTBridge.countProperties(cls.name);

                            if (propertyCount > maxStateProperties) {
                                RuleEngine.addViolation({
                                    ruleName: "TCA 1.1: Monolithic Features",
                                    severity: "high",
                                    actualValue: "State struct has " + propertyCount + " properties",
                                    expectedValue: "State structs should have ≤" + maxStateProperties + " properties",
                                    automationConfidence: 0.85,
                                    recommendedAction: "Consider extracting separate features. Large State structs indicate multiple features crammed into one reducer.",
                                    targetName: cls.name
                                });
                            }
                        }

                        // Check if this could be a TCA Action enum
                        if (cls.name === 'Action' || cls.name.endsWith('Action')) {
                            // Count action cases by looking for "case " patterns in the source
                            const sourceContent = ASTBridge.currentSourceCode;
                            const actionPattern = new RegExp('case\\s+\\w+', 'g');
                            const matches = sourceContent.match(actionPattern) || [];

                            if (matches.length > maxActionCases) {
                                RuleEngine.addViolation({
                                    ruleName: "TCA 1.1: Monolithic Features",
                                    severity: "high",
                                    actualValue: "Action enum has " + matches.length + " cases",
                                    expectedValue: "Action enums should have ≤" + maxActionCases + " cases",
                                    automationConfidence: 0.85,
                                    recommendedAction: "Consider splitting into multiple features. Large Action enums suggest too much responsibility.",
                                    targetName: cls.name
                                });
                            }
                        }
                    });
                """,
                version: "1.0",
                createdAt: Date(),
                lastUsed: Optional<Date>.none,
                usageCount: 0,
                autoFixesApplied: 0,
                isActive: true
            ),

            // TCA 2.1: Error Handling
            DatabaseRule(
                id: Optional<Int64>.none,
                name: "TCA 2.1: Error Handling",
                domain: "tca",
                patternPrompt: "Ensure TCA reducers have proper error handling",
                templateType: "TCA_ErrorHandling",
                jsCode: """
                    // TCA Rule 2.1: Error Handling Validator
                    // Ensures async operations in TCA have proper error handling

                    const sourceCode = ASTBridge.currentSourceCode;
                    const hasAsync = sourceCode.includes('await') || sourceCode.includes('async');
                    const hasErrorHandling = sourceCode.includes('catch') ||
                                          sourceCode.includes('throws') ||
                                          sourceCode.includes('Result<') ||
                                          sourceCode.includes('.failure') ||
                                          sourceCode.includes('.success');

                    // Look for TCA reducer patterns
                    const isTCAReducer = sourceCode.includes('func reduce(') &&
                                       (sourceCode.includes('State:') || sourceCode.includes('Action:'));

                    if (hasAsync && isTCAReducer && !hasErrorHandling) {
                        RuleEngine.addViolation({
                            ruleName: "TCA 2.1: Error Handling",
                            severity: "critical",
                            actualValue: "TCA reducer has async operations without error handling",
                            expectedValue: "TCA reducers should handle async errors properly",
                            automationConfidence: 0.9,
                            recommendedAction: "Add proper error handling using Result types or error cases in Action enum",
                            targetName: "tca_error_handling"
                        });
                    }
                """,
                version: "1.0",
                createdAt: Date(),
                lastUsed: Optional<Date>.none,
                usageCount: 0,
                autoFixesApplied: 0,
                isActive: true
            )
        ]

        for rule in tcaRules {
            _ = database.insertRule(rule)
        }
    }

    private func migrateSwiftUIRules() {
        print("🎨 Migrating SwiftUI rules...")

        let swiftuiRules = [
            // SwiftUI View Complexity
            DatabaseRule(
                id: Optional<Int64>.none,
                name: "SwiftUI View Complexity",
                domain: "swiftui",
                patternPrompt: "Detect overly complex SwiftUI views",
                templateType: "SwiftUI_ViewComplexity",
                jsCode: """
                    // SwiftUI View Complexity Validator
                    // Detects views with too many methods or properties

                    const classes = ASTBridge.getClasses().filter(cls =>
                        cls.kind.includes('struct') && cls.name.endsWith('View')
                    );

                    const maxProperties = 10;
                    const maxMethods = 15;

                    classes.forEach(cls => {
                        const propertyCount = ASTBridge.countProperties(cls.name);
                        const methodCount = ASTBridge.getFunctions().filter(fn =>
                            fn.name && fn.name.includes(cls.name + '.')
                        ).length;

                        if (propertyCount > maxProperties || methodCount > maxMethods) {
                            RuleEngine.addViolation({
                                ruleName: "SwiftUI View Complexity",
                                severity: "medium",
                                actualValue: "View " + cls.name + " has " + propertyCount + " properties and " + methodCount + " methods",
                                expectedValue: "Views should have ≤" + maxProperties + " properties and ≤" + maxMethods + " methods",
                                automationConfidence: 0.8,
                                recommendedAction: "Extract complex logic into separate ViewModels or child views",
                                targetName: cls.name
                            });
                        }
                    });
                """,
                version: "1.0",
                createdAt: Date(),
                lastUsed: Optional<Date>.none,
                usageCount: 0,
                autoFixesApplied: 0,
                isActive: true
            )
        ]

        for rule in swiftuiRules {
            _ = database.insertRule(rule)
        }
    }

    private func migrateGeneralRules() {
        print("🔧 Migrating General rules...")

        let generalRules = [
            // File Size Limit
            DatabaseRule(
                id: Optional<Int64>.none,
                name: "File Size Management",
                domain: "general",
                patternPrompt: "Ensure files don't become too large",
                templateType: "File_Size",
                jsCode: """
                    // File Size Management Validator
                    // Ensures files don't exceed reasonable size limits

                    const maxLines = 150;
                    const currentLines = ASTBridge.currentFile.lines;

                    if (currentLines > maxLines) {
                        RuleEngine.addViolation({
                            ruleName: "File Size Management",
                            severity: "high",
                            actualValue: currentLines + " lines in file",
                            expectedValue: "Files should have ≤" + maxLines + " lines",
                            automationConfidence: 0.85,
                            recommendedAction: "Extract smaller components from large file to improve maintainability",
                            targetName: ASTBridge.currentFile.fileName
                        });
                    }
                """,
                version: "1.0",
                createdAt: Date(),
                lastUsed: Optional<Date>.none,
                usageCount: 0,
                autoFixesApplied: 0,
                isActive: true
            )
        ]

        for rule in generalRules {
            _ = database.insertRule(rule)
        }
    }

    private func migratePerformanceRules() {
        print("⚡ Migrating Performance rules...")

        let performanceRules = [
            // Memory Management
            DatabaseRule(
                id: Optional<Int64>.none,
                name: "Memory Management Patterns",
                domain: "performance",
                patternPrompt: "Detect potential memory management issues",
                templateType: "Memory_Management",
                jsCode: """
                    // Memory Management Validator
                    // Detects potential memory leaks and retain cycles

                    const sourceCode = ASTBridge.currentSourceCode;

                    // Look for potential retain cycles in closures
                    const retainCyclePatterns = [
                        /\\[.*self.*\\]/g,  // [weak self]
                        /\\.onReceive.*\\{.*self\\./
                    ];

                    // Check for closures that capture self without weak/unowned
                    const closurePattern = /\\{[^}]*self\\.[^}]*\\}/g;
                    const closures = sourceCode.match(closurePattern) || [];

                    closures.forEach(closure => {
                        if (!closure.includes('[weak self]') && !closure.includes('[unowned self]')) {
                            RuleEngine.addViolation({
                                ruleName: "Memory Management Patterns",
                                severity: "medium",
                                actualValue: "Closure potentially creating retain cycle",
                                expectedValue: "Use [weak self] or [unowned self] in closures",
                                automationConfidence: 0.75,
                                recommendedAction: "Consider using weak or unowned references to prevent retain cycles",
                                targetName: "memory_management"
                            });
                        }
                    });
                """,
                version: "1.0",
                createdAt: Date(),
                lastUsed: Optional<Date>.none,
                usageCount: 0,
                autoFixesApplied: 0,
                isActive: true
            )
        ]

        for rule in performanceRules {
            _ = database.insertRule(rule)
        }
    }
}
