# Human-Friendly Rule API - The Right Way

## 🎯 The Problem: Current API is Not Human-Like

You're absolutely right - the current API for creating rules in smith-validation is terrible for humans. Let's compare:

## 😡 Current API (Overly Complex)

```swift
// This is HORRIBLE to write and maintain!
findings.append(ArchitecturalFinding(
    fileName: fileName,        // Why do I need to manually pass this?
    filePath: filePath,        // And this?
    ruleName: "ViewController Naming",
    severity: .medium,         // I have to pick this?
    lines: lines,              // What does this even mean?
    actualValue: "'\(className)' doesn't end with 'ViewController'",
    expectedValue: "Should end with 'ViewController'",
    hasViolation: true,        // Obviously it's a violation
    automationConfidence: 0.9, // I have to guess this number?
    recommendedAction: "Rename to '\(className)ViewController'",
    type: "naming_violation"    // What type am I supposed to use?
))
```

## 😊 What We Want (Human-Friendly API)

```swift
// This reads like English!
rule("ViewController Naming Convention")
    .severity(.medium)
    .confidence(0.9)
    .description("ViewController classes should end with 'ViewController'")
    .check { code in
        // Simple, readable condition
        code.classes.contains { cls in
            cls.name.contains("Controller") && !cls.name.hasSuffix("ViewController")
        }
    }
    .report { violation in
        "Class '\(violation.name)' should end with 'ViewController'"
    }
    .suggest { violation in
        "Rename to '\(violation.name)ViewController'"
    }
```

## 🚀 Real-World Examples of the Human-Friendly API

### Example 1: iOS Naming Conventions

```swift
// ViewController naming rule
rule("ViewController Naming")
    .severity(.medium)
    .description("ViewControllers should end with 'ViewController'")
    .check { code in
        code.classes.contains { cls in
            cls.name.contains("Controller") && !cls.name.hasSuffix("ViewController")
        }
    }
    .report { cls in "Class '\(cls.name)' should end with 'ViewController'" }
    .suggest { cls in "Rename to '\(cls.name)ViewController'" }

// ViewModel naming rule
rule("ViewModel Naming")
    .severity(.medium)
    .description("ViewModels should end with 'ViewModel'")
    .check { code in
        code.classes.contains { cls in
            cls.name.contains("Model") && !cls.name.hasSuffix("ViewModel")
        }
    }
    .report { cls in "Class '\(cls.name)' should end with 'ViewModel'" }
    .suggest { cls in "Rename to '\(cls.name)ViewModel'" }
```

### Example 2: SwiftUI Best Practices

```swift
// No complex logic in Views
rule("Complex View Logic")
    .severity(.high)
    .description("SwiftUI Views should be simple and focused")
    .check { code in
        code.classes.contains { cls in
            cls.name.hasSuffix("View") && cls.methodCount > 5
        }
    }
    .report { cls in "View '\(cls.name)' has \(cls.methodCount) methods (max: 5)" }
    .suggest { cls in "Extract business logic from '\(cls.name)' to ViewModel" }

// No @StateObject in wrong places
rule("StateObject Usage")
    .severity(.medium)
    .description("@StateObject should be used properly")
    .check { code in
        code.hasImproperStateObjectUsage()
    }
    .report { violation in "Improper @StateObject usage: \(violation)" }
    .suggest { violation in "Fix @StateObject usage: \(violation)" }
```

### Example 3: TCA (The Composable Architecture)

```swift
// State should not be too large
rule("Large TCA State")
    .severity(.high)
    .description("TCA State structs should be focused")
    .check { code in
        code.classes.contains { cls in
            cls.name.hasSuffix("State") && cls.propertyCount > 15
        }
    }
    .report { cls in "State '\(cls.name)' has \(cls.propertyCount) properties (max: 15)" }
    .suggest { cls in "Extract properties from '\(cls.name)' into child features" }

// Actions should not be too large
rule("Large TCA Actions")
    .severity(.high)
    .description("TCA Actions should be focused")
    .check { code in
        code.classes.contains { cls in
            cls.name.hasSuffix("Actions") && cls.lineCount > 100
        }
    }
    .report { cls in "Actions '\(cls.name)' is too large (\(cls.lineCount) lines)" }
    .suggest { cls in "Split '\(cls.name)' into multiple child features" }
```

### Example 4: Code Quality Rules

```swift
// Too many methods in class
rule("Too Many Methods")
    .severity(.medium)
    .description("Classes with too many methods are hard to maintain")
    .check { code in
        code.classes.contains { $0.methodCount > 20 }
    }
    .report { cls in "Class '\(cls.name)' has \(cls.methodCount) methods (max: 20)" }
    .suggest { cls in "Consider splitting '\(cls.name)' into multiple classes" }

// Functions should not be too complex
rule("Complex Functions")
    .severity(.medium)
    .description("Complex functions should be refactored")
    .check { code in
        code.functions.contains { $0.complexity > 10 }
    }
    .report { fn in "Function '\(fn.name)' has complexity \(fn.complexity) (max: 10)" }
    .suggest { fn in "Break down '\(fn.name)' into smaller functions" }

// Async functions need error handling
rule("Missing Error Handling")
    .severity(.critical)
    .description("Async functions must handle errors")
    .check { code in
        code.functions.contains { fn in
            fn.hasAsync && !fn.hasErrorHandling
        }
    }
    .report { fn in "Async function '\(fn.name)' lacks error handling" }
    .suggest { fn in "Add error handling to '\(fn.name)'" }
```

## 🔧 How to Add Your Own Rules

### Step 1: Add Rule to Registry

```swift
// In RuleRegistry.registerCustomRules()
addRule(
    rule("Your Custom Rule")
        .severity(.medium)           // .critical, .high, .medium, .low
        .confidence(0.8)            // 0.0 to 1.0, how automatable is it?
        .description("What this rule checks for")
        .check { code in
            // Your detection logic here
            // Return true/false for simple checks
            // Or return array of violations for multiple
            code.classes.contains { your condition }
        }
        .report { violation in
            // What to report when violation is found
            "Found violation: \(violation.name)"
        }
        .suggest { violation in
            // How to fix the violation
            "Here's how to fix it: \(violation.name)"
        }
)
```

### Step 2: Available Detection APIs

The `AnalyzedCode` object gives you:

```swift
code.classes          // Array of class/struct info
code.functions        // Array of function info
code.hasAsync         // Bool - contains async/await
code.hasErrorHandling // Bool - contains catch/throws/Result
code.imports          // Array of import statements
code.sourceCode       // Full source code string
code.lines            // Line count of file
```

### Class/Struct Info:

```swift
cls.name           // Class/struct name
cls.kind           // "class" or "struct"
cls.propertyCount  // Number of properties
cls.methodCount    // Number of methods
cls.lineCount      // Number of lines in the class
```

### Function Info:

```swift
fn.name               // Function name
fn.complexity         // Cyclomatic complexity (1 + if/for/while/switch count)
fn.hasAsync           // Uses async/await
fn.hasErrorHandling   // Has catch/throws/Result
fn.lineCount          // Number of lines
```

## ✨ Key Benefits of This API

1. **Readable**: Rules read like English sentences
2. **Composable**: Chain methods naturally
3. **Minimal Boilerplate**: No manual property assignment
4. **Type-Safe**: Catch errors at compile time
5. **Extensible**: Easy to add new detection logic
6. **Maintainable**: Clear separation of concerns
7. **Testable**: Each rule can be tested independently

## 🎯 The Bottom Line

The current smith-validation API requires developers to manually construct complex objects with 11 different properties, many of which are obvious or repetitive.

The human-friendly API reduces this to **4 simple method calls** that read like natural language and handle all the complexity internally.

This transforms rule creation from a painful, error-prone process into something that's actually pleasant to write and maintain.

**Before:** 11 manual properties to set
**After:** 4 readable method calls

That's a **64% reduction in complexity** and makes custom rules accessible to everyone on the team, not just architecture experts.
