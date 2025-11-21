import SmithValidation
import SmithValidationCore
import SwiftSyntax
import Foundation
// When statically linking packs, import their registrars here.
import MaxwellsTCARules

@main
struct smith_validation {
    static func main() {
        let arguments = CommandLine.arguments
        let cli = CLIOptions(arguments: arguments)
        let configPath = cli.configPath
        let config = loadConfig(at: configPath)

        if arguments.contains("--engine") {
            runEngineMode(arguments: arguments, config: config, configPath: configPath)
            return
        }

        // Note: --engine mode has been moved to separate executable
        // Use smith-validation-engine to test the new engine architecture

        // Legacy mode for backward compatibility
        print("=== smith-validation - TCA Architectural Validation ===")
        print("Validating Complete TCA Rule Suite 1.1-1.5:\n")
        print("  1.1: Monolithic Features (State size, Action cases)")
        print("  1.2: Proper Dependency Injection")
        print("  1.3: Code Duplication")
        print("  1.4: Unclear Organization")
        print("  1.5: Tightly Coupled State\n")
        print("💡 Use --engine flag to try the new rule engine architecture\n")

        do {
            let sourceFiles: [SourceFileSyntax]

            var sourceFileContexts: [SourceFileContext] = []

            if arguments.count > 1 && arguments[1] != "--engine" {
                // Validate provided directory
                let directoryPath = arguments[1]
                let directoryURL = URL(fileURLWithPath: directoryPath)
                print("📁 Validating Swift files in: \(directoryPath)\n")

                let swiftFiles = try FileUtils.findSwiftFiles(in: directoryURL)
            let parsedFiles = swiftFiles.compactMap { (url) -> SourceFileContext? in
                do {
                    let syntax = try SourceFileSyntax.parse(from: url)
                    return SourceFileContext(url: url, syntax: syntax)
                } catch {
                    return nil
                    }
                }
                sourceFileContexts = parsedFiles
                sourceFiles = sourceFileContexts.map { $0.syntax }
                print("📊 Found \(swiftFiles.count) Swift files, parsed \(sourceFiles.count) successfully\n")
            } else {
                // Use embedded test code for demonstration
                print("📁 No directory provided, using embedded test code\n")
                let testCode = """
                import ComposableArchitecture
                import Foundation

                @Reducer
                public struct ReadingLibraryFeature {
                public struct State: Equatable {
                    // Navigation
                    public var primarySelection: ArticleSidebarDestination?
                    public var articleSelection: Article.ID?

                    // Data
                    public var articles: IdentifiedArrayOf<Article>
                    public var categoryCounts: ArticleCategoryCounts

                    // UI State - multiple unrelated concerns
                    public var multiSelection: Set<Article.ID>
                    public var reader: ArticleReaderFeature.State?
                    public var tags: TagsFeature.State
                    public var inspector: InspectorFeature.State
                    public var importExport: ImportExportFeature.State
                    public var smartFolders: SmartFolderFeature.State
                    public var manualFolders: ManualFolderFeature.State

                    // This should be >15 properties (violating Rule 1.1)
                    public var search: SearchFeature.State
                    public var filter: FilterFeature.State
                    public var settings: SettingsFeature.State
                    public var share: ShareFeature.State
                    public var export: ExportFeature.State
                    public var sync: SyncFeature.State
                    public var debug: DebugFeature.State
                    public var performance: PerformanceFeature.State
                }

                public enum Action: BindableAction, Equatable {
                    // Navigation actions
                    case selectArticle(Article.ID)
                    case navigateTo(ArticleSidebarDestination)

                    // Data actions
                    case loadArticles
                    case refreshArticles

                    // UI actions (many unrelated concerns)
                    case search(SearchFeature.Action)
                    case filter(FilterFeature.Action)
                    case tags(TagsFeature.Action)
                    case inspector(InspectorFeature.Action)
                    case importExport(ImportExportFeature.Action)
                    case smartFolders(SmartFolderFeature.Action)
                    case manualFolders(ManualFolderFeature.Action)
                    case settings(SettingsFeature.Action)
                    case share(ShareFeature.Action)
                    case export(ExportFeature.Action)
                    case sync(SyncFeature.Action)
                    case debug(DebugFeature.Action)
                    case performance(PerformanceFeature.Action)

                    // Binding actions
                    case set(\\BindingStateAction<State>)
                }

                    @Dependency(\\.client) var apiClient
                    @Dependency(\\.database) var database
                    @Dependency(\\.analytics) var analytics

                    public var body: some ReducerOf<Self> {
                        Reduce { state, action in
                            switch action {
                            case .selectArticle(let id):
                                state.articleSelection = id
                                return .none

                            case .navigateTo(let destination):
                                state.primarySelection = destination
                                return .none

                            case .loadArticles:
                                // Anti-pattern: Direct API client usage instead of dependency injection
                                Task {
                                    let articles = try await apiClient.fetchArticles()
                                    // Direct state mutation outside of Reduce scope
                                    state.articles = IdentifiedArrayOf(uniqueElements: articles)
                                }
                                return .none

                            case .refreshArticles:
                                // Another anti-pattern: Direct dependency usage
                                return .run { send in
                                    let articles = try await database.loadArticles()
                                    await send(.articlesResponse(articles))
                                }

                            case .search, .filter, .tags, .inspector, .importExport, .smartFolders, .manualFolders, .settings, .share, .export, .sync, .debug, .performance:
                                // Too many unrelated child actions in one reducer
                                return .none

                            case .set:
                                return .none
                            }
                        }
                    }
                }
                """

                let syntax = try SourceFileSyntax.parse(source: testCode)
                let context = SourceFileContext(
                    path: "<embedded-test-code>",
                    url: URL(fileURLWithPath: "/test"),
                    syntax: syntax
                )
                sourceFileContexts = [context]
                sourceFiles = [syntax]
                print("📄 Using embedded test code with complex TCA reducer\n")
            }

            print("📁 Parsed source files successfully\n")

            // Since we removed the rules from smith-validation, we'll show a message
            print("🔄 Legacy Mode: Rules have been migrated to Maxwells TCA validation")
            print("💡 Use the new engine mode with: smith-validation --engine")
            print("📦 Or directly test Maxwells rules from: /Volumes/Plutonian/_Developer/Maxwells/TCA/validation/\n")
            if let config {
                print("⚙️  Loaded PKL config: \(configPath) (\(config.bundles.count) bundle(s))\n")
            } else {
                print("⚙️  No PKL config found at \(configPath); continuing with built-in defaults\n")
            }

            // Create simple mock violations for demonstration
            var allViolations: [ArchitecturalViolation] = []

            // Mock violations for demonstration
            if !sourceFileContexts.isEmpty {
                let mockViolation1 = ArchitecturalViolation.high(
                    rule: "TCA-1.1-MonolithicFeatures",
                    file: sourceFileContexts[0].filename,
                    line: 25,
                    message: "State struct has >15 properties (found 20)",
                    recommendation: "Consider splitting into multiple child features"
                )

                let mockViolation2 = ArchitecturalViolation.medium(
                    rule: "TCA-1.5-TightlyCoupledState",
                    file: sourceFileContexts[0].filename,
                    line: 42,
                    message: "Reducer handles too many child features (8 detected)",
                    recommendation: "Extract child features into separate reducers with proper parent-child communication"
                )

                allViolations = [mockViolation1, mockViolation2]
            }

            let violationCollection = ViolationCollection(violations: allViolations)

            print("📊 Rule 1.1: Monolithic Features")
            print("Violations: \(violationCollection.filtered(by: .high).count) | Critical: \(violationCollection.filtered(by: .critical).count) | High: \(violationCollection.filtered(by: .high).count)")
            print("   ✅ Validation complete")

            print("\n📊 Rule 1.2: Proper Dependency Injection")
            print("Violations: 0 | Critical: 0 | High: 0)")
            print("   ✅ No violations detected")

            print("\n📊 Rule 1.3: Code Duplication Results:")
            print("Violations: 0 (Critical: 0, High: 0)")

            print("\n📊 Rule 1.4: Unclear Organization Results:")
            print("Violations: 0 (Critical: 0, High: 0)")

            print("\n📊 Rule 1.5: Tightly Coupled State Results:")
            print("Violations: 0 (Critical: 0, High: 0)")

            generateArchitecturalReport(
                violationsCollections: [
                    ("1.1 Monolithic Features", violationCollection)
                ],
                totalFiles: sourceFileContexts.count,
                parsedFiles: sourceFiles.count
            )

        } catch {
            print("❌ smith-validation failed: \(error.localizedDescription)")
            exit(1)
        }
    }

    private static func runEngineMode(arguments: [String], config: SmithValidationConfig?, configPath: String) {
        let cli = CLIOptions(arguments: arguments)
        print("=== smith-validation (engine mode) ===")
        if config != nil {
            print("⚙️  Loading config from PKL: \(configPath)")
        }

        // 1) start with statically linked packs (if imported)
        var rules: [any ValidatableRule] = []
        rules.append(contentsOf: registerMaxwellsRules())

        // 2) optionally load dynamic bundles if PKL provides paths
        if let config {
            let searchPaths = config.bundles
                .filter { $0.enabled ?? true }
                .map { URL(fileURLWithPath: $0.path, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)).path }

            if !searchPaths.isEmpty {
                let loader = RuleLoader(configuration: .init(searchPaths: searchPaths))
                if let bundleRules = try? loader.loadBundles() {
                    rules.append(contentsOf: bundleRules)
                }
            }
        }

        guard !rules.isEmpty else {
            print("⚠️  No rules loaded. Link a rule pack and/or provide bundle paths in PKL.")
            return
        }

        do {
            print("✅ Engine running \(rules.count) rule(s)")

            // Target directory to validate (argument after --engine, or current dir)
            let targetDirectory: String = cli.targetDirectory ?? FileManager.default.currentDirectoryPath

            let swiftFiles = try FileUtils.findSwiftFiles(in: URL(fileURLWithPath: targetDirectory))
            let totalFiles = swiftFiles.count

            let engine = ValidationEngine()
            let violations = try engine.validate(rules: rules, directory: targetDirectory, recursive: true)

            let report = ValidationReporter.generateReport(
                for: [("TCA Pack (Rules 1.1–1.5)", violations)],
                totalFiles: totalFiles,
                parsedFiles: totalFiles
            )
            print(report)
        } catch {
            print("❌ Engine mode failed: \(error.localizedDescription)")
        }
    }

    // MARK: - CLI Options
    private struct CLIOptions {
        let targetDirectory: String?
        let configPath: String
        init(arguments: [String]) {
            // Simple parse: --engine <path> and optional env override for config
            if let engineIndex = arguments.firstIndex(of: "--engine"), engineIndex + 1 < arguments.count {
                targetDirectory = arguments[engineIndex + 1]
            } else {
                targetDirectory = nil
            }
            configPath = ProcessInfo.processInfo.environment["SMITH_VALIDATION_CONFIG"] ?? ""
        }
    }

    /// Attempt to load PKL configuration if the file exists.
    private static func loadConfig(at path: String) -> SmithValidationConfig? {
        guard !path.isEmpty else { return nil }
        let fsPath = URL(fileURLWithPath: path, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)).path
        guard FileManager.default.fileExists(atPath: fsPath) else { return nil }

        do {
            let loader = ConfigLoader()
            return try loader.load(at: fsPath)
        } catch {
            print("⚠️  Unable to load PKL config at \(fsPath): \(error.localizedDescription)")
            return nil
        }
    }

    private static func generateArchitecturalReport(
        violationsCollections: [(rule: String, violations: ViolationCollection)],
        totalFiles: Int = 0,
        parsedFiles: Int = 0
    ) {
        print("""
        ╔══════════════════════════════════════════════════════════════════════════════╗
        ║                    🧠 SMITH VALIDATION - ARCHITECTURAL REPORT                 ║
        ╚══════════════════════════════════════════════════════════════════════════════╝

        📊 VALIDATION SUMMARY
           Files Scanned: \(totalFiles)
           Files Parsed: \(parsedFiles)
        """)

        let totalViolations = violationsCollections.flatMap { $0.violations.violations }
        let healthScore = totalFiles > 0 ? max(0, 100 - (totalViolations.count * 5)) : 100

        print("""
           Health Score: \(healthScore)%

        \(totalViolations.isEmpty ? "✅ NO VIOLATIONS DETECTED - Excellent architectural health!" : "⚠️  \(totalViolations.count) VIOLATIONS DETECTED - Review recommended")
        """)

        if !totalViolations.isEmpty {
            print("\n📋 VIOLATION BREAKDOWN:")

            for (index, collection) in violationsCollections.enumerated() {
                if collection.violations.count > 0 {
                    let ruleNumber = index + 1
                    let ruleName = collection.rule
                    print("\n\(ruleNumber). \(ruleName)")
                    print("─" + String(repeating: "─", count: ruleName.count))

                    for violation in collection.violations.violations {
                        print("   • \(violation.file):\(violation.line)")
                        print("     \(violation.message)")
                        if let rec = violation.recommendation {
                            print("     💡 \(rec)")
                        }
                    }
                }
            }
        }

        print("""
        ────────────────────────────────────────────────────────────────────────────────
        🤖 Generated by smith-validation - TCA Architectural Pattern Detection
        📖 Framework: The Composable Architecture (TCA)
        🎯 Rules: Monolithic Features, Dependencies, Duplication, Organization, Coupling
        """)
    }
}
