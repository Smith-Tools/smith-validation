# Real-World Rule Examples - Human-Friendly API

## 🎯 The Problem with the Old API

Before: 😫 Complex and manual
```swift
// Ugh! This is terrible to write and maintain
findings.append(ArchitecturalFinding(
    fileName: fileName,        // Why do I need to specify this?
    filePath: filePath,        // And this?
    ruleName: "ViewController Naming",  // OK
    severity: .medium,         // I have to pick this?
    lines: lines,              // What does this even mean?
    actualValue: "'\(className)' doesn't end with 'ViewController'",  // So verbose
    expectedValue: "Should end with 'ViewController'",  // Repetitive
    hasViolation: true,        // Obviously it's a violation
    automationConfidence: 0.9, // I have to guess this number?
    recommendedAction: "Rename to '\(className)ViewController'",  // Obvious
    type: "naming_violation"    // What type am I supposed to use?
))
```

## ✅ The New Human-Friendly API

Now: 😊 Simple and readable
```swift
// This reads like English!
rule("ViewController Naming Convention")
    .severity(.medium)
    .confidence(0.9)
    .description("ViewController classes should end with 'ViewController'")
    .find { code in
        code.classes.filter { cls in
            cls.name.contains("Controller") && !cls.name.hasSuffix("ViewController")
        }
    }
    .report { cls in "Class '\(cls.name)' should end with 'ViewController'" }
    .suggest { cls in "Rename to '\(cls.name)ViewController'" }
```

## 🚀 Real-World Use Cases

### Use Case 1: iOS App Architecture Rules

**Problem**: Your iOS team has specific naming conventions and architectural patterns you want to enforce.

```swift
// Add this to RuleRegistry.registerCustomRules()

// Rule 1: ViewControllers must end with "ViewController"
addRule(
    rule("ViewController Naming Convention")
        .severity(.medium)
        .confidence(0.9)
        .find { code in
            code.classes.filter { cls in
                cls.name.contains("Controller") && !cls.name.hasSuffix("ViewController")
            }
        }
        .report { cls in "Class '\(cls.name)' should end with 'ViewController'" }
        .suggest { cls in "Rename to '\(cls.name)ViewController'" }
)

// Rule 2: ViewModels must end with "ViewModel"
addRule(
    rule("ViewModel Naming Convention")
        .severity(.medium)
        .confidence(0.9)
        .find { code in
            code.classes.filter { cls in
                cls.name.contains("Model") && !cls.name.hasSuffix("ViewModel")
            }
        }
        .report { cls in "Class '\(cls.name)' should end with 'ViewModel'" }
        .suggest { cls in "Rename to '\(cls.name)ViewModel'" }
)

// Rule 3: No networking in ViewControllers
addRule(
    rule("Networking in ViewControllers")
        .severity(.high)
        .confidence(0.95)
        .description("ViewControllers should not directly handle networking")
        .find { code in
            code.classes.filter { cls in
                cls.name.hasSuffix("ViewController") && 
                (code.sourceCode.lowercased().contains("urlsession") ||
                 code.sourceCode.lowercased().contains("alamofire"))
            }
        }
        .report { cls in "ViewController '\(cls.name)' contains networking code" }
        .suggest { cls in "Move networking logic to a separate service layer" }
)
```

### Use Case 2: SwiftUI Best Practices

**Problem**: Your team is adopting SwiftUI and wants to enforce best practices.

```swift
// Rule 1: @StateObject only for owned objects
addRule(
    rule("StateObject Usage")
        .severity(.medium)
        .confidence(0.8)
        .description("@StateObject should only be used for objects the view owns")
        .find { code in
            // Look for @StateObject in wrong contexts
            let lines = code.sourceCode.components(separatedBy: .newlines)
            var violations: [String] = []
            
            for (index, line) in lines.enumerated() {
                if line.contains("@StateObject") && 
                   line.contains("let") &&
                   !line.contains("private") {
                    violations.add("Line \(index + 1): \(line.trimmingCharacters(in: .whitespaces))")
                }
            }
            return violations
        }
        .report { violation in "@StateObject should be private: \(violation)" }
        .suggest { _ in "Make @StateObject properties private" }
)

// Rule 2: No complex business logic in Views
addRule(
    rule("Complex View Logic")
        .severity(.high)
        .confidence(0.85)
        .description("SwiftUI Views should not contain complex business logic")
        .find { code in
            code.classes.filter { cls in
                cls.name.hasSuffix("View") && cls.methodCount > 5
            }
        }
        .report { cls in "View '\(cls.name)' has \(cls.methodCount) methods (max: 5)" }
        .suggest { cls in "Extract business logic from '\(cls.name)' to ViewModel or service" }
)
```

### Use Case 3: TCA (The Composable Architecture) Rules

**Problem**: Enforcing TCA best practices and preventing common mistakes.

```swift
// Rule 1: State structs shouldn't be too large
addRule(
    rule("Large TCA State")
        .severity(.high)
        .confidence(0.9)
        .description("TCA State structs with too many properties are hard to manage")
        .find { code in
            code.classes.filter { cls in
                cls.name.hasSuffix("State") && cls.propertyCount > 15
            }
        }
        .report { cls in "State '\(cls.name)' has \(cls.propertyCount) properties (max: 15)" }
        .suggest { cls in "Extract related properties from '\(cls.name)' into child features" }
)

// Rule 2: Action enums shouldn't be too large
addRule(
    rule("Large TCA Actions")
        .severity(.high)
        .confidence(0.85)
        .description("TCA Action enums with too many cases indicate feature is too large")
        .find { code in
            // This is simplified - you'd need to parse enum cases properly
            code.classes.filter { cls in
                cls.name.hasSuffix("Actions") && cls.lineCount > 100
            }
        }
        .report { cls in "Actions '\(cls.name)' is too large (\(cls.lineCount) lines)" }
        .suggest { cls in "Split '\(cls.name)' into multiple child features" }
)
```

### Use Case 4: API Design Rules

**Problem**: Enforce consistent API design across your project.

```swift
// Rule 1: API methods should have proper error handling
addRule(
    rule("API Error Handling")
        .severity(.critical)
        .confidence(0.95)
        .description("API methods must have proper error handling")
        .find { code in
            code.functions.filter { fn in
                fn.hasAsync && !fn.hasErrorHandling && fn.name.contains("fetch")
            }
        }
        .report { fn in "API method '\(fn.name)' lacks error handling" }
        .suggest { fn in "Add proper error handling to '\(fn.name)'" }
)

// Rule 2: No force unwrapping in production code
addRule(
    rule("Force Unwrapping")
        .severity(.high)
        .confidence(0.9)
        .description("Avoid force unwrapping in production code")
        .find { code in
            let forceUnwraps = code.sourceCode.components(separatedBy: "!").count - 1
            return forceUnwraps > 0 ? ["Found \(forceUnwraps) force unwraps"] : []
        }
        .report { violation in violation }
        .suggest { _ in "Replace force unwrapping with optional binding or guard" }
)
```

## 🔧 How to Add Your Own Rules

### Step 1: Add Rule to Registry

Edit `Sources/smith-validation/RuleBuilder.swift` and add your rule in the `registerCustomRules()` method:

```swift
private func registerCustomRules() {
    // Existing rules...
    
    // Your custom rule here!
    addRule(
        rule("Your Custom Rule")
            .severity(.medium)  // .critical, .high, .medium, .low
            .confidence(0.8)   // 0.0 to 1.0
            .description("What this rule checks for")
            .find { code in
                // Your detection logic here
                // Return: Bool, [Violations], or single object
                code.classes.filter { /* your condition */ }
            }
            .report { violation in
                // What to report when violation is found
                "Found violation: \(violation)"
            }
            .suggest { violation in
                // How to fix the violation
                "Here's how to fix it: \(violation)"
            }
    )
}
```

### Step 2: Test Your Rule

```bash
# Build with new rule
swift build -c release

# Test on your project
./.build/release/smith-validation /path/to/your/project

# Check for your specific violations
./.build/release/smith-validation /path/to/your/project | jq '.findings[] | select(.ruleName == "Your Custom Rule")'
```

### Step 3: Available Detection APIs

The `AnalyzedCode` object gives you easy access to:

```swift
code.classes          // Array of ClassInfo
code.functions        // Array of FunctionInfo
code.hasAsync         // Bool - contains async/await
code.hasErrorHandling // Bool - contains catch/throws/Result
code.imports          // Array of import statements
code.sourceCode       // Full source code string
code.declarations     // Raw SourceKit declarations
code.lines            // Line count
```

### ClassInfo Properties:
```swift
cls.name           // Class name
cls.kind           // "class" or "struct"
cls.propertyCount  // Number of properties
cls.methodCount    // Number of methods
cls.lineCount      // Number of lines in class
```

### FunctionInfo Properties:
```swift
fn.name               // Function name
fn.complexity         // Cyclomatic complexity
fn.hasAsync           // Uses async/await
fn.hasErrorHandling   // Has error handling
fn.lineCount          // Number of lines
```

## 🎯 Examples: Common Patterns

### Pattern 1: Count-Based Rules
```swift
rule("Too Many Methods")
    .find { code in code.classes.filter { $0.methodCount > 20 } }
    .report { cls in "Class '\(cls.name)' has too many methods (\(cls.methodCount))" }
    .suggest { cls in "Consider splitting '\(cls.name)' into multiple classes" }
```

### Pattern 2: Naming Convention Rules
```swift
rule("Protocol Naming")
    .find { code in
        code.classes.filter { cls in
            cls.kind.contains("protocol") && !cls.name.hasSuffix("Protocol")
        }
    }
    .report { cls in "Protocol '\(cls.name)' should end with 'Protocol'" }
    .suggest { cls in "Rename to '\(cls.name)Protocol'" }
```

### Pattern 3: Content-Based Rules
```swift
rule("TODO Comments")
    .severity(.low)
    .find { code in
        let todoCount = code.sourceCode.components(separatedBy: "TODO:").count - 1
        return todoCount > 0 ? ["Found \(todoCount) TODO comments"] : []
    }
    .report { violation in violation }
    .suggest { _ in "Address TODO comments or create issues" }
```

### Pattern 4: Boolean Condition Rules
```swift
rule("File Too Long")
    .severity(.medium)
    .find { code in code.lines > 300 }
    .report { code in "File has \(code.lines) lines (max: 300)" }
    .suggest { code in "Split file into multiple smaller files" }
```

## ✨ Key Benefits of the New API

1. **Readable**: Rules read like English sentences
2. **Composable**: Chain methods naturally
3. **Type-Safe**: Catch errors at compile time
4. **Extensible**: Easy to add new detection logic
5. **Maintainable**: Clear separation of concerns
6. **Testable**: Each rule can be tested independently

The new API transforms rule creation from a complex, error-prone process into a simple, expressive one that reads like natural language!
