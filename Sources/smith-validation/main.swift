import Foundation
import SmithValidation
import SmithValidationCore
import MaxwellsTCARules

/// Marker prefix used by rule-pack tests to emit findings.
private let findingMarker = "SMITH_RULE_FINDING:"
private let projectEnvKey = "SMITH_RULES_PROJECT_ROOT"
private let includeEnvKey = "SMITH_RULES_INCLUDE"
private let excludeEnvKey = "SMITH_RULES_EXCLUDE"

@main
struct SmithValidationCLI {
    static func main() {
        let opts = CLIOptions.parse(CommandLine.arguments.dropFirst())

        if opts.showVersion {
            print("smith-validation \(versionString())")
            return
        }

        if let rulesPack = opts.rulesTestsPath {
            guard let target = opts.paths.first else {
                print("❌ Please provide a target project path as the first positional argument when using --rules-tests.")
                exit(1)
            }
            switch runRulesTests(packPath: rulesPack, targetPath: target, include: opts.includeGlobs, exclude: opts.excludeGlobs) {
            case .success(let violations):
                generateArchitecturalReport(
                    violationsCollections: [("Custom Rule Pack", ViolationCollection(violations: violations))],
                    totalFiles: violations.map { _ in 0 }.count,
                    parsedFiles: violations.map { _ in 0 }.count
                )
                exit(violations.isEmpty ? 0 : 2)
            case .failure(let error):
                print("❌ rules-tests failed: \(error.localizedDescription)")
                exit(1)
            }
        }

        // Engine mode is the default when a path is provided
        if !opts.paths.isEmpty || opts.engine {
            runEngineMode(opts: opts)
            return
        }

        // Help
        print("""
        smith-validation \(versionString())
        Usage:
          smith-validation [--engine] <path>                       Run built-in engine with bundled rules
          smith-validation --rules-tests <rule-pack> <path>        Run a Swift Testing rule pack dynamically

        Options:
          --include globs       Comma-separated include globs (default: **/*.swift)
          --exclude globs       Comma-separated exclude globs (default: **/DerivedData/**,**/.build/**,**/Pods/**,**/.swiftpm/**)
          --version, -v         Print version
        """)
    }

    // MARK: - Engine mode
    private static func runEngineMode(opts: CLIOptions) {
        do {
            print("=== smith-validation (engine mode) ===")
            let rules = registerMaxwellsRules()
            print("✅ Engine running \(rules.count) rule(s)")

            var allViolations: [ArchitecturalViolation] = []
            var totalFiles = 0

            let engine = ValidationEngine()
            for path in opts.paths {
                let urls = try FileUtils.findSwiftFiles(
                    in: URL(fileURLWithPath: path),
                    includeGlobs: opts.includeGlobs,
                    excludeGlobs: opts.excludeGlobs
                )
                let filePaths = urls.map { $0.path }
                let violations = try engine.validate(rules: rules, filePaths: filePaths)
                allViolations.append(contentsOf: violations.violations)
                totalFiles += filePaths.count
            }

            let collection = ViolationCollection(violations: allViolations)
            generateArchitecturalReport(
                violationsCollections: [("Maxwells TCA Pack", collection)],
                totalFiles: totalFiles,
                parsedFiles: totalFiles
            )
        } catch {
            print("❌ Engine mode failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Rules test runner
    private static func runRulesTests(
        packPath: String,
        targetPath: String,
        include: [String],
        exclude: [String]
    ) -> Result<[ArchitecturalViolation], Error> {
        var env = ProcessInfo.processInfo.environment
        env[projectEnvKey] = URL(fileURLWithPath: targetPath).path
        env[includeEnvKey] = include.joined(separator: ",")
        env[excludeEnvKey] = exclude.joined(separator: ",")

        let process = Process()
        process.environment = env
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["swift", "test", "-c", "release", "--package-path", packPath, "--disable-sandbox"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do { try process.run() } catch { return .failure(error) }
        process.waitUntilExit()

        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8) ?? ""
        let findings = output
            .split(separator: "\n")
            .compactMap { line -> ArchitecturalViolation? in
                guard line.hasPrefix(findingMarker) else { return nil }
                let jsonPart = line.dropFirst(findingMarker.count)
                guard let data = String(jsonPart).data(using: .utf8) else { return nil }
                do {
                    let finding = try JSONDecoder().decode(TestFinding.self, from: data)
                    return finding.toViolation()
                } catch {
                    return nil
                }
            }

        if process.terminationStatus != 0 && findings.isEmpty {
            let err = NSError(domain: "smith-validation.rules-tests", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: output])
            return .failure(err)
        }
        return .success(findings)
    }

    // MARK: - Helpers

    private static func versionString() -> String { "v1.0.9" }

    private static func loadConfig(at path: String) -> SmithValidationConfig? {
        guard !path.isEmpty else { return nil }
        let fsPath = URL(fileURLWithPath: path, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)).path
        guard FileManager.default.fileExists(atPath: fsPath) else { return nil }
        do { return try ConfigLoader().load(at: fsPath) } catch { return nil }
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
            for (index, collection) in violationsCollections.enumerated() where collection.violations.count > 0 {
                let ruleNumber = index + 1
                let ruleName = collection.rule
                print("\n\(ruleNumber). \(ruleName)")
                print("─" + String(repeating: "─", count: ruleName.count))
                for violation in collection.violations.violations {
                    print("   • \(violation.file):\(violation.line)")
                    print("     \(violation.message)")
                    if let rec = violation.recommendation { print("     💡 \(rec)") }
                }
            }
        }

        print("""
        ────────────────────────────────────────────────────────────────────────────────
        🤖 Generated by smith-validation
        """)
    }
}

// MARK: - CLI options
fileprivate struct CLIOptions {
    var paths: [String] = []
    var engine: Bool = false
    var rulesTestsPath: String?
    var includeGlobs: [String] = ["**/*.swift"]
    var excludeGlobs: [String] = ["**/DerivedData/**", "**/.build/**", "**/Pods/**", "**/.swiftpm/**"]
    var showVersion: Bool = false
    var configPath: String = ProcessInfo.processInfo.environment["SMITH_VALIDATION_CONFIG"] ?? ""

    static func parse(_ args: ArraySlice<String>) -> CLIOptions {
        var opts = CLIOptions()
        var it = args.makeIterator()
        while let arg = it.next() {
            switch arg {
            case "--engine", "-e":
                opts.engine = true
            case "--include":
                if let next = it.next() { opts.includeGlobs = next.split(separator: ",").map(String.init) }
            case "--exclude":
                if let next = it.next() { opts.excludeGlobs = next.split(separator: ",").map(String.init) }
            case "--rules-tests":
                if let next = it.next() { opts.rulesTestsPath = next }
            case "--version", "-v":
                opts.showVersion = true
            default:
                if !arg.hasPrefix("-") {
                    opts.paths.append(arg)
                }
            }
        }
        return opts
    }
}

// MARK: - Test finding model
private struct TestFinding: Codable {
    let rule: String
    let severity: String
    let file: String
    let line: Int
    let message: String
    let recommendation: String?

    func toViolation() -> ArchitecturalViolation {
        let sev = severity.lowercased()
        switch sev {
        case "critical": return .critical(rule: rule, file: file, line: line, message: message, recommendation: recommendation)
        case "high": return .high(rule: rule, file: file, line: line, message: message, recommendation: recommendation)
        case "medium": return .medium(rule: rule, file: file, line: line, message: message, recommendation: recommendation)
        case "low": fallthrough
        default:
            return .low(rule: rule, file: file, line: line, message: message, recommendation: recommendation)
        }
    }
}
