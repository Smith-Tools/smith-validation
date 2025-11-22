# Smith Validation - User Guide: Creating Custom Rules

> **Complete guide to extending smith-validation with custom architectural rules**

This guide shows you how to create custom architectural rules for smith-validation using the SourceKit framework. You'll learn how to detect specific architectural patterns, implement validation logic, and integrate your rules into the analysis pipeline.

## 🏗️ Architecture Overview

smith-validation uses a clean, direct SourceKit integration:

```
SourceKitAnalyzer
├── findSwiftFiles() - File discovery
├── analyzeFileWithSourceKit() - Per-file analysis
│   ├── SourceKit semantic parsing
│   ├── Declaration extraction
│   └── Rule application
└── AI-optimized JSON output generation
```

## 📋 Rule Categories

### 1. **File-Level Rules**
- File size analysis
- File naming conventions
- Content pattern detection

### 2. **Structural Rules**
- Declaration complexity
- Property/method counts
- Nested structure depth

### 3. **Pattern-Based Rules**
- Architecture pattern validation (TCA, MVC, etc.)
- Async/await error handling
- Dependency injection patterns

## 🛠️ Creating Your First Rule

### Step 1: Identify the Pattern

Let's create a rule that detects **excessive method complexity** in Swift classes.

**Target Pattern:**
```swift
class ServiceManager {
    func processComplexOperation(data: Data) -> Result<String, Error> {
        // 50+ lines of complex logic
        // Multiple nested conditions
        // Complex error handling
        // Resource management
        // Network calls
        // Data transformation
    }
}
```

### Step 2: Add Rule Logic to SourceKitAnalyzer

Edit `Sources/smith-validation/main.swift` and add your rule in the `analyzeFileWithSourceKit` method:

```swift
// MARK: - Custom Rules

// Add after the existing rules in analyzeFileWithSourceKit

// Rule 5: Excessive Method Complexity
let functions = declarations.filter {
    $0.kind.contains("function") || $0.kind.contains("method")
}

for function in functions {
    let complexity = calculateMethodComplexity(
        function: function,
        sourceCode: sourceCode,
        declarations: declarations
    )

    if complexity > 10 {
        findings.append(ArchitecturalFinding(
            fileName: fileName,
            filePath: filePath,
            ruleName: "Excessive Method Complexity",
            severity: .high,
            lines: lines,
            actualValue: "Method complexity: \(complexity)",
            expectedValue: "Method complexity <= 10",
            hasViolation: true,
            automationConfidence: 0.75,
            recommendedAction: "Extract complex method into smaller, focused functions",
            type: "method_complexity"
        ))
    }
}
```

### Step 3: Implement Helper Methods

Add the helper method outside the `analyzeFileWithSourceKit` method:

```swift
// MARK: - Rule Helper Methods

private func calculateMethodComplexity(
    function: DeclarationInfo,
    sourceCode: String,
    declarations: [DeclarationInfo]
) -> Int {
    guard let functionStart = function.bodyOffset,
          let functionLength = function.bodyLength else { return 0 }

    let functionEnd = functionStart + functionLength
    let startIndex = sourceCode.index(sourceCode.startIndex, offsetBy: Int(functionStart))
    let endIndex = sourceCode.index(sourceCode.startIndex, offsetBy: Int(functionEnd))

    let functionCode = String(sourceCode[startIndex..<endIndex])

    var complexity = 1 // Base complexity

    // Count complexity indicators
    complexity += functionCode.components(separatedBy: "if ").count - 1
    complexity += functionCode.components(separatedBy: "guard ").count - 1
    complexity += functionCode.components(separatedBy: "for ").count - 1
    complexity += functionCode.components(separatedBy: "while ").count - 1
    complexity += functionCode.components(separatedBy: "switch ").count - 1
    complexity += functionCode.components(separatedBy: "??").count - 1
    complexity += functionCode.components(separatedBy: "try").count - 1

    // Count nested declarations (closures, inner functions)
    let nestedDeclarations = declarations.filter {
        $0.offset >= functionStart && $0.offset < functionEnd &&
        ($0.kind.contains("function") || $0.kind.contains("closure"))
    }
    complexity += nestedDeclarations.count

    return complexity
}
```

## 🎯 Advanced Rule Examples

### Example 1: TCA Dependency Validation

```swift
// Rule: TCA Proper Dependency Injection
let imports = extractImports(from: sourceCode)
let hasNetworkOperations = sourceCode.lowercased().contains("urlsession") ||
                           sourceCode.lowercased().contains("url") ||
                           sourceCode.lowercased().contains("http")

let hasDependencyInjection = imports.contains { importLine in
    importLine.contains("Dependencies") || importLine.contains("Dependency")
}

if hasNetworkOperations && !hasDependencyInjection {
    findings.append(ArchitecturalFinding(
        fileName: fileName,
        filePath: filePath,
        ruleName: "TCA Missing Dependency Injection",
        severity: .high,
        lines: lines,
        actualValue: "Network operations without @Dependency system",
        expectedValue: "Use @Dependency(\.apiClient) for network operations",
        hasViolation: true,
        automationConfidence: 0.90,
        recommendedAction: "Import Dependencies and use @Dependency for network operations",
        type: "missing_dependency_injection"
    ))
}

// Helper method
private func extractImports(from sourceCode: String) -> [String] {
    let lines = sourceCode.components(separatedBy: .newlines)
    return lines.filter {
        $0.trimmingCharacters(in: .whitespaces).hasPrefix("import")
    }
}
```

### Example 2: SwiftUI Best Practices

```swift
// Rule: SwiftUI @StateObject vs @ObservedObject
let stateObjects = declarations.filter {
    $0.kind.contains("var.instance") &&
    extractPropertyAttributes(from: sourceCode, property: $0).contains("@StateObject")
}

let propertyWrappers = extractPropertyWrappers(from: sourceCode)
let hasStateObjectInWrongContext = propertyWrappers.contains { wrapper in
    wrapper.property.contains("@StateObject") &&
    (wrapper.declaringType.contains("View") && !wrapper.declaringType.contains("struct"))
}

if hasStateObjectInWrongContext {
    findings.append(ArchitecturalFinding(
        fileName: fileName,
        filePath: filePath,
        ruleName: "SwiftUI StateObject Usage",
        severity: .medium,
        lines: lines,
        actualValue: "@StateObject used in inappropriate context",
        expectedValue: "@StateObject only in View structs for instance ownership",
        hasViolation: true,
        automationConfidence: 0.80,
        recommendedAction: "Use @ObservedObject for dependencies, @StateObject for owned objects",
        type: "stateobject_usage"
    ))
}

// Helper methods
private struct PropertyWrapper {
    let property: String
    let declaringType: String
}

private func extractPropertyWrappers(from sourceCode: String) -> [PropertyWrapper] {
    var wrappers: [PropertyWrapper] = []

    // This is a simplified implementation
    // In practice, you'd want more sophisticated parsing
    let lines = sourceCode.components(separatedBy: .newlines)
    var currentType = ""

    for line in lines {
        if line.contains("class ") || line.contains("struct ") {
            currentType = extractTypeName(from: line)
        }

        if line.contains("@StateObject") || line.contains("@ObservedObject") {
            wrappers.append(PropertyWrapper(
                property: line.trimmingCharacters(in: .whitespaces),
                declaringType: currentType
            ))
        }
    }

    return wrappers
}

private func extractTypeName(from declarationLine: String) -> String {
    // Extract type name from "class ClassName" or "struct StructName"
    let components = declarationLine.components(separatedBy: " ")
    if let typeIndex = components.firstIndex(where: {
        $0 == "class" || $0 == "struct"
    }), typeIndex + 1 < components.count {
        return components[typeIndex + 1].trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return ""
}
```

### Example 3: Enhanced Async/Await Error Handling

```swift
// Enhanced Async Error Handling Rule
let asyncFunctions = declarations.filter {
    $0.name.contains("async") ||
    extractFunctionAttributes(from: sourceCode, function: $0).contains("async")
}

for asyncFunc in asyncFunctions {
    guard let funcStart = asyncFunc.bodyOffset,
          let funcLength = asyncFunc.bodyLength else { continue }

    let funcEnd = funcStart + funcLength
    let startIndex = sourceCode.index(sourceCode.startIndex, offsetBy: Int(funcStart))
    let endIndex = sourceCode.index(sourceCode.startIndex, offsetBy: Int(funcEnd))

    let functionCode = String(sourceCode[startIndex..<endIndex])

    let hasErrorHandling = functionCode.contains("catch") ||
                           functionCode.contains("throws") ||
                           functionCode.contains("Result<") ||
                           functionCode.contains("?")

    let hasAwaitCalls = functionCode.contains("await")

    if hasAwaitCalls && !hasErrorHandling {
        findings.append(ArchitecturalFinding(
            fileName: fileName,
            filePath: filePath,
            ruleName: "Async Function Error Handling",
            severity: .critical,
            lines: lines,
            actualValue: "Async function '\(asyncFunc.name)' without proper error handling",
            expectedValue: "Async functions should handle errors with catch/throws or Result types",
            hasViolation: true,
            automationConfidence: 0.95,
            recommendedAction: "Add proper error handling for async operations in \(asyncFunc.name)",
            type: "async_error_handling"
        ))
    }
}

private func extractFunctionAttributes(from sourceCode: String, function: DeclarationInfo) -> [String] {
    // Extract attributes like @async, @MainActor, etc.
    guard let funcStart = function.offset else { return [] }

    let startIndex = sourceCode.index(sourceCode.startIndex, offsetBy: Int(funcStart))
    let endIndex = sourceCode.index(startIndex, offsetBy: 100) // Look ahead 100 chars

    let codeRange = startIndex..<endIndex
    let code = String(sourceCode[codeRange])

    // Extract attributes before function declaration
    let lines = code.components(separatedBy: .newlines)
    var attributes: [String] = []

    for line in lines {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        if trimmedLine.hasPrefix("@") {
            attributes.append(trimmedLine)
        } else if trimmedLine.contains("func ") || trimmedLine.contains("var ") {
            break // Stop at function declaration
        }
    }

    return attributes
}
```

## 🔧 Rule Development Best Practices

### 1. **Performance Optimization**

```swift
// ✅ Good: Efficient string operations
let hasAsyncOperation = sourceCode.contains("await") || sourceCode.contains("async")

// ❌ Bad: Complex regex operations
let asyncRegex = try NSRegularExpression(pattern: "await|async")
let hasAsyncOperation = asyncRegex.firstMatch(in: sourceCode, options: [], range: fullRange) != nil
```

### 2. **Accurate Violation Detection**

```swift
// ✅ Good: Specific violation details
findings.append(ArchitecturalFinding(
    fileName: fileName,
    filePath: filePath,
    ruleName: "TCA State Property Count",
    severity: .high,
    lines: lines,
    actualValue: "\(propertyCount) properties in \(structName)",
    expectedValue: "State structs should have <= 15 properties",
    hasViolation: true,
    automationConfidence: 0.90,
    recommendedAction: "Extract related properties into child features",
    type: "monolithic_state"
))
```

### 3. **Proper Severity Assignment**

```swift
// Use severity guidelines:
private func assignSeverity(for violationType: String, context: [String: Any]) -> ViolationSeverity {
    switch violationType {
    case "async_error_handling", "memory_leaks", "crash_risks":
        return .critical  // Immediate action required
    case "monolithic_state", "missing_dependency_injection":
        return .high       // Architectural issues
    case "naming_conventions", "code_duplication":
        return .medium     // Quality improvements
    case "documentation", "minor_style_issues":
        return .low        // Nice to have
    default:
        return .medium
    }
}
```

### 4. **Automation Confidence Scoring**

```swift
// Assign confidence based on fixability:
private func calculateAutomationConfidence(for ruleType: String) -> Double {
    switch ruleType {
    case "async_error_handling": return 0.95  // Very automatable
    case "file_size_management": return 0.85  // Extractable
    case "monolithic_state": return 0.90      // Refactorable
    case "naming_conventions": return 0.75     // Mostly automatable
    case "architecture_patterns": return 0.60  // Requires design decisions
    default: return 0.70
    }
}
```

## 🧪 Testing Your Rules

### 1. **Create Test Files**

```swift
// TestFile.swift - Contains various violations
import Foundation

class ServiceManager {
    func complexFunction() -> String {
        var result = ""
        if true {
            for i in 0..<10 {
                guard i < 5 else { continue }
                switch i {
                case 0:
                    result += "zero"
                default:
                    result += "other"
                }
            }
        }
        return result
    }

    func asyncOperation() {
        Task {
            let data = await fetchFromNetwork() // No error handling
            processData(data)
        }
    }
}
```

### 2. **Run Analysis**

```bash
# Build and test
swift build -c release
./.build/release/smith-validation /path/to/test/files
```

### 3. **Validate Output**

```bash
# Check specific violations in output
./.build/release/smith-validation /path/to/test/files | jq '.findings[] | select(.ruleName == "Excessive Method Complexity")'
```

## 📊 Rule Metrics and Reporting

### 1. **Track Rule Effectiveness**

```swift
// Add rule metadata to findings
struct RuleMetrics {
    let ruleName: String
    let violationsDetected: Int
    let averageConfidence: Double
    let severity: ViolationSeverity
    let filesAnalyzed: Int
}
```

### 2. **Generate Rule Performance Reports**

```swift
private func generateRuleReport(findings: [ArchitecturalFinding]) -> [String: Any] {
    let groupedFindings = Dictionary(grouping: findings) { $0.ruleName }

    var ruleMetrics: [String: RuleMetrics] = [:]

    for (ruleName, ruleFindings) in groupedFindings {
        let metrics = RuleMetrics(
            ruleName: ruleName,
            violationsDetected: ruleFindings.count,
            averageConfidence: ruleFindings.reduce(0) { $0 + $1.automationConfidence } / Double(ruleFindings.count),
            severity: ruleFindings.first?.severity ?? .medium,
            filesAnalyzed: Set(ruleFindings.map { $0.fileName }).count
        )
        ruleMetrics[ruleName] = metrics
    }

    return ruleMetrics.mapValues { [
        "violations": $0.violationsDetected,
        "avgConfidence": $0.averageConfidence,
        "severity": $0.severity.rawValue,
        "uniqueFiles": $0.filesAnalyzed
    ]}
}
```

## 🚀 Deploying Custom Rules

### 1. **Version Your Rules**

```swift
// Add versioning to your custom rules
struct CustomRules {
    static let version = "1.0.0"
    static let supportedSwiftVersions = ["5.7", "5.8", "5.9"]

    // Your custom rules here
}
```

### 2. **Documentation**

```swift
// Document each rule clearly
/// Rule: Detect excessive method complexity
///
/// Complexity is calculated based on:
/// - Conditional statements (if, guard, switch)
/// - Loop constructs (for, while)
/// - Nested declarations
/// - Error handling operators (try, ??)
///
/// Threshold: > 10 complexity points
/// Severity: High
/// Automation Confidence: 0.75
```

### 3. **Continuous Integration**

```yaml
# .github/workflows/architecture-validation.yml
name: Custom Architecture Rules
on: [push, pull_request]

jobs:
  validate:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build smith-validation with custom rules
        run: |
          swift build -c release
      - name: Run custom rule analysis
        run: |
          ./.build/release/smith-validation . > validation.json
      - name: Check for new violations
        run: |
          VIOLATIONS=$(jq '.summary.violationsCount' validation.json)
          if [ $VIOLATIONS -gt 10 ]; then
            echo "Too many violations: $VIOLATIONS"
            exit 1
          fi
```

## 🎓 Advanced Techniques

### 1. **Cross-File Analysis**

```swift
// Analyze relationships between files
private func analyzeFileRelationships(
    files: [URL],
    declarations: [String: [DeclarationInfo]]
) -> [ArchitecturalFinding] {
    var findings: [ArchitecturalFinding] = []

    // Detect circular dependencies
    // Analyze import relationships
    // Check for architectural layer violations

    return findings
}
```

### 2. **Machine Learning Integration**

```swift
// Use ML models for pattern recognition
private func detectArchitecturalPatterns(
    sourceCode: String,
    mlModel: ArchitecturePatternModel
) -> [PatternPrediction] {
    // Convert source code to features
    let features = extractFeatures(from: sourceCode)

    // Get predictions from ML model
    let predictions = mlModel.predict(features: features)

    return predictions.filter { $0.confidence > 0.8 }
}
```

### 3. **Dynamic Rule Configuration**

```swift
// Configure rules via external configuration
struct RuleConfiguration: Codable {
    let methodComplexityThreshold: Int
    let maxStateProperties: Int
    let requiredErrorHandling: [String]
    let enabledRules: [String]
}

private func loadConfiguration() -> RuleConfiguration {
    // Load from config file or environment variables
}
```

## 🔗 Resources

- [SourceKit Framework Documentation](https://github.com/jpsim/SourceKitten)
- [Swift Language Guide](https://docs.swift.org/swift-book/)
- [Architecture Pattern References](https://github.com/pointfreeco/swift-composable-architecture)

---

**smith-validation** - Extensible architectural validation for Swift projects

For questions and support, please open an issue on the [GitHub repository](https://github.com/Smith-Tools/smith-validation).
