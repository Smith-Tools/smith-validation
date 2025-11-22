import Foundation
import SourceKittenFramework

// MARK: - Human-Friendly Rule Builder API

/// A much simpler way to create architectural rules
///
/// Instead of manually constructing ArchitecturalFinding objects with tons of parameters,
/// you can use this fluent API that reads like English:
///
/// rule("Bad naming")
///     .severity(.medium)
///     .condition { code in code.classes.count > 10 }
///     .report { "Too many classes: \($0.classes.count)" }
///     .suggest { "Split into multiple files" }
///
class RuleBuilder {
    private let name: String
    private var severity: ViolationSeverity = .medium
    private var confidence: Double = 0.8
    private var description: String = ""

    init(name: String) {
        self.name = name
    }

    func severity(_ severity: ViolationSeverity) -> RuleBuilder {
        let rule = RuleBuilder(name: name)
        rule.severity = severity
        rule.confidence = confidence
        rule.description = description
        return rule
    }

    func confidence(_ confidence: Double) -> RuleBuilder {
        let rule = RuleBuilder(name: name)
        rule.severity = severity
        rule.confidence = max(0.0, min(1.0, confidence))
        rule.description = description
        return rule
    }

    func description(_ description: String) -> RuleBuilder {
        let rule = RuleBuilder(name: name)
        rule.severity = severity
        rule.confidence = confidence
        rule.description = description
        return rule
    }

    /// Simple boolean condition rule
    func condition(
        _ condition: @escaping (AnalyzedCode) -> Bool,
        report: @escaping (AnalyzedCode) -> String,
        suggest: @escaping (AnalyzedCode) -> String
    ) -> SimpleRule {
        return SimpleRule(
            name: name,
            severity: severity,
            confidence: confidence,
            description: description,
            condition: condition,
            report: report,
            suggest: suggest
        )
    }

    /// Array-based rule for multiple violations
    func findViolations<T>(
        _ find: @escaping (AnalyzedCode) -> [T],
        report: @escaping (T) -> String,
        suggest: @escaping (T) -> String
    ) -> ArrayRule<T> {
        return ArrayRule(
            name: name,
            severity: severity,
            confidence: confidence,
            description: description,
            find: find,
            report: report,
            suggest: suggest
        )
    }
}

/// Simple rule with boolean condition
class SimpleRule {
    let name: String
    let severity: ViolationSeverity
    let confidence: Double
    let description: String
    let condition: (AnalyzedCode) -> Bool
    let report: (AnalyzedCode) -> String
    let suggest: (AnalyzedCode) -> String

    init(
        name: String,
        severity: ViolationSeverity,
        confidence: Double,
        description: String,
        condition: @escaping (AnalyzedCode) -> Bool,
        report: @escaping (AnalyzedCode) -> String,
        suggest: @escaping (AnalyzedCode) -> String
    ) {
        self.name = name
        self.severity = severity
        self.confidence = confidence
        self.description = description
        self.condition = condition
        self.report = report
        self.suggest = suggest
    }

    func apply(to code: AnalyzedCode, fileName: String, filePath: String, lines: Int) -> [ArchitecturalFinding]? {
        if condition(code) {
            return [ArchitecturalFinding(
                fileName: fileName,
                filePath: filePath,
                ruleName: name,
                severity: severity,
                lines: lines,
                actualValue: report(code),
                expectedValue: "No violations should be found",
                hasViolation: true,
                automationConfidence: confidence,
                recommendedAction: suggest(code),
                type: name.lowercased().replacingOccurrences(of: " ", with: "_")
            )]
        }
        return nil
    }
}

/// Rule that finds multiple violations in an array
class ArrayRule<T> {
    let name: String
    let severity: ViolationSeverity
    let confidence: Double
    let description: String
    let find: (AnalyzedCode) -> [T]
    let report: (T) -> String
    let suggest: (T) -> String

    init(
        name: String,
        severity: ViolationSeverity,
        confidence: Double,
        description: String,
        find: @escaping (AnalyzedCode) -> [T],
        report: @escaping (T) -> String,
        suggest: @escaping (T) -> String
    ) {
        self.name = name
        self.severity = severity
        self.confidence = confidence
        self.description = description
        self.find = find
        self.report = report
        self.suggest = suggest
    }

    func apply(to code: AnalyzedCode, fileName: String, filePath: String, lines: Int) -> [ArchitecturalFinding]? {
        let violations = find(code)
        if violations.isEmpty {
            return nil
        }

        return violations.map { violation in
            ArchitecturalFinding(
                fileName: fileName,
                filePath: filePath,
                ruleName: name,
                severity: severity,
                lines: lines,
                actualValue: report(violation),
                expectedValue: "No violations should be found",
                hasViolation: true,
                automationConfidence: confidence,
                recommendedAction: suggest(violation),
                type: name.lowercased().replacingOccurrences(of: " ", with: "_")
            )
        }
    }
}

/// Simplified code analysis structure
struct AnalyzedCode {
    let sourceCode: String
    let declarations: [DeclarationInfo]
    let lines: Int

    /// Easy access to common patterns
    var classes: [ClassInfo] {
        return declarations
            .filter { $0.kind.contains("struct") || $0.kind.contains("class") }
            .map { ClassInfo(from: $0, sourceCode: sourceCode) }
    }

    var functions: [FunctionInfo] {
        return declarations
            .filter { $0.kind.contains("function") || $0.kind.contains("method") }
            .map { FunctionInfo(from: $0, sourceCode: sourceCode) }
    }

    var hasAsync: Bool {
        return sourceCode.contains("await") || sourceCode.contains("async")
    }

    var hasErrorHandling: Bool {
        return sourceCode.contains("catch") ||
               sourceCode.contains("throws") ||
               sourceCode.contains("Result<") ||
               sourceCode.contains("?")
    }

    var imports: [String] {
        return sourceCode
            .components(separatedBy: .newlines)
            .filter { $0.trimmingCharacters(in: .whitespaces).hasPrefix("import") }
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }
}

/// Simplified class information
struct ClassInfo {
    let name: String
    let kind: String
    let propertyCount: Int
    let methodCount: Int
    let lineCount: Int

    init(from declaration: DeclarationInfo, sourceCode: String) {
        self.name = declaration.name
        self.kind = declaration.kind

        guard let bodyStart = declaration.bodyOffset,
              let bodyLength = declaration.bodyLength else {
            self.propertyCount = 0
            self.methodCount = 0
            self.lineCount = 0
            return
        }

        let bodyEnd = bodyStart + bodyLength
        let startIndex = sourceCode.index(sourceCode.startIndex, offsetBy: Int(bodyStart))
        let endIndex = sourceCode.index(sourceCode.startIndex, offsetBy: Int(bodyEnd))

        let bodyContent = String(sourceCode[startIndex..<endIndex])
        self.lineCount = bodyContent.components(separatedBy: .newlines).count

        // Simple counting (could be improved)
        self.propertyCount = bodyContent.components(separatedBy: "var ").count - 1
        self.methodCount = bodyContent.components(separatedBy: "func ").count - 1
    }
}

/// Simplified function information
struct FunctionInfo {
    let name: String
    let complexity: Int
    let hasAsync: Bool
    let hasErrorHandling: Bool
    let lineCount: Int

    init(from declaration: DeclarationInfo, sourceCode: String) {
        self.name = declaration.name

        guard let bodyStart = declaration.bodyOffset,
              let bodyLength = declaration.bodyLength else {
            self.complexity = 1
            self.hasAsync = false
            self.hasErrorHandling = false
            self.lineCount = 0
            return
        }

        let bodyEnd = bodyStart + bodyLength
        let startIndex = sourceCode.index(sourceCode.startIndex, offsetBy: Int(bodyStart))
        let endIndex = sourceCode.index(sourceCode.startIndex, offsetBy: Int(bodyEnd))

        let functionCode = String(sourceCode[startIndex..<endIndex])

        // Calculate complexity
        self.complexity = 1 +
            functionCode.components(separatedBy: "if ").count - 1 +
            functionCode.components(separatedBy: "guard ").count - 1 +
            functionCode.components(separatedBy: "for ").count - 1 +
            functionCode.components(separatedBy: "while ").count - 1 +
            functionCode.components(separatedBy: "switch ").count - 1

        self.hasAsync = functionCode.contains("await")
        self.hasErrorHandling = functionCode.contains("catch") ||
                               functionCode.contains("throws") ||
                               functionCode.contains("Result<")

        self.lineCount = functionCode.components(separatedBy: .newlines).count
    }
}

// MARK: - Global Rule Builder Function

/// Create a new rule with a human-friendly API
func rule(_ name: String) -> RuleBuilder {
    return RuleBuilder(name: name)
}

// MARK: - Rule Registry

/// All custom rules should be registered here
class RuleRegistry {
    static let shared = RuleRegistry()

    private var rules: [Any] = []

    private init() {
        // Register all custom rules here
        registerCustomRules()
    }

    private func registerCustomRules() {
        // Example rules - users can add their own here
        
        // Rule 1: ViewController Naming Convention
        rules.append(
            rule("ViewController Naming Convention")
                .severity(.medium)
                .confidence(0.9)
                .description("ViewController classes should end with 'ViewController'")
                .findViolations({ (code: AnalyzedCode) -> [ClassInfo] in
                    code.classes.filter { cls in
                        cls.name.contains("Controller") && !cls.name.hasSuffix("ViewController")
                    }
                })
                .report { (cls: ClassInfo) -> String in
                    "Class '\(cls.name)' should end with 'ViewController'"
                }
                .suggest { (cls: ClassInfo) -> String in
                    "Rename to '\(cls.name)ViewController'"
                }
        )

        // Rule 2: Too Many Properties
        rules.append(
            rule("Too Many Properties")
                .severity(.high)
                .confidence(0.8)
                .description("Classes with too many properties are hard to maintain")
                .findViolations({ (code: AnalyzedCode) -> [ClassInfo] in
                    code.classes.filter { $0.propertyCount > 15 }
                })
                .report { (cls: ClassInfo) -> String in
                    "Class '\(cls.name)' has \(cls.propertyCount) properties (max: 15)"
                }
                .suggest { (cls: ClassInfo) -> String in
                    "Extract related properties into separate structs or child classes"
                }
        )

        // Rule 3: Complex Functions
        rules.append(
            rule("Complex Functions")
                .severity(.medium)
                .confidence(0.7)
                .description("Functions with high complexity should be refactored")
                .findViolations({ (code: AnalyzedCode) -> [FunctionInfo] in
                    code.functions.filter { $0.complexity > 10 }
                })
                .report { (fn: FunctionInfo) -> String in
                    "Function '\(fn.name)' has complexity \(fn.complexity) (max: 10)"
                }
                .suggest { (fn: FunctionInfo) -> String in
                    "Break down '\(fn.name)' into smaller, focused functions"
                }
        )

        // Rule 4: Missing Error Handling
        rules.append(
            rule("Missing Error Handling")
                .severity(.critical)
                .confidence(0.95)
                .description("Async functions should have proper error handling")
                .findViolations({ (code: AnalyzedCode) -> [FunctionInfo] in
                    code.functions.filter { $0.hasAsync && !$0.hasErrorHandling }
                })
                .report { (fn: FunctionInfo) -> String in
                    "Async function '\(fn.name)' lacks error handling"
                }
                .suggest { (fn: FunctionInfo) -> String in
                    "Add proper error handling to '\(fn.name)' using catch/throws or Result types"
                }
        )
    }

    func addRule(_ rule: SimpleRule) {
        rules.append(rule)
    }

    func addRule<T>(_ rule: ArrayRule<T>) {
        rules.append(rule)
    }

    func getAllRules() -> [Any] {
        return rules
    }
}
