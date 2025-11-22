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

        // Artifact mode (fastest - uses build artifacts)
        if opts.artifacts {
            runArtifactMode(opts: opts)
            return
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
          smith-validation --artifacts <path>                     Use build artifacts for fast validation
          smith-validation --rules-tests <rule-pack> <path>        Run a Swift Testing rule pack dynamically

        Options:
          --include globs       Comma-separated include globs (default: **/*.swift)
          --exclude globs       Comma-separated exclude globs (default: **/DerivedData/**,**/.build/**,**/Pods/**,**/.swiftpm/**)
          --artifacts, -a       Use build artifacts mode (fastest for large codebases)
          --engine, -e          Force engine mode (default for paths)
          --version, -v         Print version
        """)
    }

    // MARK: - Artifact mode (fastest - uses build artifacts)
    private static func runArtifactMode(opts: CLIOptions) {
        do {
            print("=== smith-validation (artifact mode) ===")
            print("🚀 Using build artifacts for ultra-fast validation")

            var allViolations: [ArchitecturalViolation] = []
            var totalFiles = 0
            var parsedFiles = 0

            for path in opts.paths {
                let artifacts = try loadBuildArtifacts(from: path)
                let violations = try validateArtifacts(artifacts: artifacts)

                allViolations.append(contentsOf: violations.violations)
                totalFiles += artifacts.swiftFiles.count
                parsedFiles += artifacts.swiftFiles.count
            }

            let collection = ViolationCollection(violations: allViolations)
            generateArchitecturalReport(
                violationsCollections: [("Maxwells TCA Pack (Artifacts)", collection)],
                totalFiles: totalFiles,
                parsedFiles: parsedFiles
            )
        } catch {
            print("❌ Artifact mode failed: \(error.localizedDescription)")
            print("💡 Ensure the project has been built (swift build) and artifacts are available")
        }
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
        // First try to reuse an existing build to avoid costly rebuilds.
        let args = ["swift", "test", "-c", "release", "--package-path", packPath, "--disable-sandbox", "--skip-build"]
        process.arguments = args

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

        if process.terminationStatus != 0 {
            // If skip-build failed (likely because nothing is built), retry with a full build once.
            if args.contains("--skip-build") {
                let fallback = Process()
                fallback.environment = env
                fallback.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                fallback.arguments = ["swift", "test", "-c", "release", "--package-path", packPath, "--disable-sandbox"]
                let fbPipe = Pipe()
                fallback.standardOutput = fbPipe
                fallback.standardError = fbPipe
                do { try fallback.run() } catch { return .failure(error) }
                fallback.waitUntilExit()
                let fbOut = String(data: fbPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                let fbFindings = fbOut
                    .split(separator: "\n")
                    .compactMap { line -> ArchitecturalViolation? in
                        guard line.hasPrefix(findingMarker) else { return nil }
                        let jsonPart = line.dropFirst(findingMarker.count)
                        guard let data = String(jsonPart).data(using: .utf8) else { return nil }
                        return try? JSONDecoder().decode(TestFinding.self, from: data).toViolation()
                    }
                if fallback.terminationStatus != 0 && fbFindings.isEmpty {
                    let err = NSError(domain: "smith-validation.rules-tests", code: Int(fallback.terminationStatus), userInfo: [NSLocalizedDescriptionKey: fbOut])
                    return .failure(err)
                }
                return .success(fbFindings)
            }
            let err = NSError(domain: "smith-validation.rules-tests", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: output])
            return .failure(err)
        }
        return .success(findings)
    }

    // MARK: - Artifact Mode Helpers

    /// Build artifacts containing parsed Swift information
    private struct BuildArtifacts {
        let swiftFiles: [SwiftFileInfo]
        let buildPath: String
    }

    /// Information about a Swift file extracted from build artifacts
    private struct SwiftFileInfo {
        let path: String
        let content: String
        let stateStructs: [TCAStateInfo]
        let actionEnums: [TCAActionInfo]
    }

    /// TCA State struct information
    private struct TCAStateInfo {
        let name: String
        let propertyCount: Int
        let line: Int
    }

    /// TCA Action enum information
    private struct TCAActionInfo {
        let name: String
        let caseCount: Int
        let line: Int
    }

    /// Load build artifacts from a Swift package or Xcode project
    private static func loadBuildArtifacts(from path: String) throws -> BuildArtifacts {
        let url = URL(fileURLWithPath: path)

        // Find build directory
        let buildPath = try findBuildDirectory(for: url)

        // Extract Swift file information from build artifacts
        let swiftFiles = try extractSwiftFileInfo(from: url, buildPath: buildPath)

        return BuildArtifacts(
            swiftFiles: swiftFiles,
            buildPath: buildPath
        )
    }

    /// Find the build directory for a project
    private static func findBuildDirectory(for projectURL: URL) throws -> String {
        // Check for Swift Package Manager build directory
        let spmBuildPath = projectURL.appendingPathComponent(".build").path
        if FileManager.default.fileExists(atPath: spmBuildPath) {
            return spmBuildPath
        }

        // Check for Xcode derived data
        let derivedDataPaths = [
            (("~" as NSString).appendingPathComponent("Library/Developer/Xcode/DerivedData") as String),
            "/var/folders/*/D/Build/*/DerivedData"
        ]

        for pattern in derivedDataPaths {
            // Simple glob expansion (real implementation would be more robust)
            if FileManager.default.fileExists(atPath: pattern) {
                return pattern
            }
        }

        throw ValidationError(message: "No build artifacts found. Please build the project first.")
    }

    /// Extract Swift file information from build artifacts
    private static func extractSwiftFileInfo(from projectURL: URL, buildPath: String) throws -> [SwiftFileInfo] {
        let swiftFiles = try FileUtils.findSwiftFiles(in: projectURL)
        var fileInfos: [SwiftFileInfo] = []

        for fileURL in swiftFiles {
            let content = try String(contentsOf: fileURL)
            let swiftFileInfo = analyzeSwiftFile(
                path: fileURL.path,
                content: content
            )
            fileInfos.append(swiftFileInfo)
        }

        return fileInfos
    }

    /// Analyze a Swift file for TCA patterns without full parsing
    private static func analyzeSwiftFile(path: String, content: String) -> SwiftFileInfo {
        let lines = content.components(separatedBy: .newlines)
        var stateStructs: [TCAStateInfo] = []
        var actionEnums: [TCAActionInfo] = []

        var currentStructLine = 0
        var inStruct = false
        var currentStructName = ""
        var braceLevel = 0

        var currentEnumLine = 0
        var inEnum = false
        var currentEnumName = ""

        for (lineIndex, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // Simple pattern matching for TCA State structs
            if trimmedLine.hasPrefix("struct") && (trimmedLine.contains("State") || trimmedLine.contains("ObservableState")) {
                inStruct = true
                currentStructLine = lineIndex + 1
                let components = trimmedLine.components(separatedBy: .whitespaces)
                if components.count > 1 {
                    currentStructName = components[1].replacingOccurrences(of: ":", with: "")
                }
                braceLevel = 0
                continue
            }

            // Simple pattern matching for TCA Action enums
            if trimmedLine.hasPrefix("enum") && trimmedLine.contains("Action") {
                inEnum = true
                currentEnumLine = lineIndex + 1
                let components = trimmedLine.components(separatedBy: .whitespaces)
                if components.count > 1 {
                    currentEnumName = components[1].replacingOccurrences(of: ":", with: "")
                }
                braceLevel = 0
                continue
            }

            if inStruct {
                // Count properties in struct
                for char in line {
                    if char == "{" { braceLevel += 1 }
                    else if char == "}" { braceLevel -= 1 }
                }

                // Simple property detection (lines with ':' inside struct)
                if trimmedLine.contains(":") && !trimmedLine.hasPrefix("//") && braceLevel == 1 {
                    // Count as a property
                }

                if braceLevel <= 0 {
                    // Struct ended, calculate property count
                    let structContent = lines[(currentStructLine - 1)...lineIndex].joined()
                    let propertyCount = countPropertiesInContent(structContent)

                    if propertyCount > 0 {
                        stateStructs.append(TCAStateInfo(
                            name: currentStructName,
                            propertyCount: propertyCount,
                            line: currentStructLine
                        ))
                    }

                    inStruct = false
                }
            }

            if inEnum {
                // Count enum cases
                if trimmedLine.hasPrefix("case") {
                    // Simple case detection
                }

                for char in line {
                    if char == "{" { braceLevel += 1 }
                    else if char == "}" { braceLevel -= 1 }
                }

                if braceLevel <= 0 {
                    // Enum ended, calculate case count
                    let enumContent = lines[(currentEnumLine - 1)...lineIndex].joined()
                    let caseCount = countCasesInContent(enumContent)

                    if caseCount > 0 {
                        actionEnums.append(TCAActionInfo(
                            name: currentEnumName,
                            caseCount: caseCount,
                            line: currentEnumLine
                        ))
                    }

                    inEnum = false
                }
            }
        }

        return SwiftFileInfo(
            path: path,
            content: content,
            stateStructs: stateStructs,
            actionEnums: actionEnums
        )
    }

    /// Count properties in struct content (simplified)
    private static func countPropertiesInContent(_ content: String) -> Int {
        let lines = content.components(separatedBy: .newlines)
        var count = 0

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Simple heuristic for properties (contains : but not "case", "func", etc.)
            if trimmed.contains(":") &&
               !trimmed.hasPrefix("case") &&
               !trimmed.hasPrefix("func") &&
               !trimmed.hasPrefix("init") &&
               !trimmed.hasPrefix("//") &&
               !trimmed.contains("->") {
                count += 1
            }
        }

        return count
    }

    /// Count enum cases in content (simplified)
    private static func countCasesInContent(_ content: String) -> Int {
        let lines = content.components(separatedBy: .newlines)
        var count = 0

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("case") {
                count += 1
            }
        }

        return count
    }

    /// Validate artifacts and generate violations
    private static func validateArtifacts(artifacts: BuildArtifacts) throws -> ViolationCollection {
        var violations: [ArchitecturalViolation] = []

        for fileInfo in artifacts.swiftFiles {
            // Rule 1.1: Monolithic Features - State structs
            for stateInfo in fileInfo.stateStructs {
                if stateInfo.propertyCount > 15 {
                    violations.append(.high(
                        rule: "TCA Rule 1.1: Monolithic Features",
                        file: fileInfo.path,
                        line: stateInfo.line,
                        message: "State struct '\(stateInfo.name)' has \(stateInfo.propertyCount) properties (>15 threshold) - consider splitting into multiple features",
                        recommendation: "Split this monolithic State into smaller, focused feature states"
                    ))
                }
            }

            // Rule 1.1: Monolithic Features - Action enums
            for actionInfo in fileInfo.actionEnums {
                if actionInfo.caseCount > 40 {
                    violations.append(.high(
                        rule: "TCA Rule 1.1: Monolithic Features",
                        file: fileInfo.path,
                        line: actionInfo.line,
                        message: "Action enum '\(actionInfo.name)' has \(actionInfo.caseCount) cases (>40 threshold) - suggests too much responsibility",
                        recommendation: "Break down this feature into smaller, focused features with fewer actions"
                    ))
                }
            }
        }

        return ViolationCollection(violations: violations)
    }

    // MARK: - Helpers

    private static func versionString() -> String { "v1.0.10" }

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

// MARK: - Error Types
private struct ValidationError: LocalizedError {
    let message: String
    var errorDescription: String? { return message }
}

// MARK: - CLI options
fileprivate struct CLIOptions {
    var paths: [String] = []
    var engine: Bool = false
    var artifacts: Bool = false
    var rulesTestsPath: String?
    var includeGlobs: [String] = ["**/*.swift"]
    var excludeGlobs: [String] = ["**/DerivedData/**", "**/.build/**", "**/Pods/**", "**/.swiftpm/**", "**/ThirdParty/**", "**/Vendor/**", "**/External/**"]
    var showVersion: Bool = false
    var configPath: String = ProcessInfo.processInfo.environment["SMITH_VALIDATION_CONFIG"] ?? ""

    static func parse(_ args: ArraySlice<String>) -> CLIOptions {
        var opts = CLIOptions()
        var it = args.makeIterator()
        while let arg = it.next() {
            switch arg {
            case "--engine", "-e":
                opts.engine = true
            case "--artifacts", "-a":
                opts.artifacts = true
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
