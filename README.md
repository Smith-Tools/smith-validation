# smith-validation

> **Swift architectural validation engine**

[![Release](https://img.shields.io/github/release/Smith-Tools/smith-validation.svg)](https://github.com/Smith-Tools/smith-validation/releases)
[![Swift](https://img.shields.io/badge/swift-5.9%2B-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

smith-validation is a **pluggable architectural validation engine** for Swift projects. It uses SwiftSyntax to analyze your code structure, detect architectural violations, and enforce best practices through configurable rule packs.

> **Note**: Comes with Maxwells TCA rules for The Composable Architecture, but can validate any Swift architectural patterns.

## ✨ Features

- **Pluggable Architecture**: Add custom rule packs for any architectural pattern
- **SwiftSyntax-Based**: Deep AST analysis of your Swift code
- **Dynamic Rule Loading**: Load rules from compiled bundles or source code
- **PKL Configuration**: Flexible configuration management
- **Dual Interface**: Both CLI tool and framework integration
- **Performance Optimized**: Efficient parsing and caching

## 🚀 Quick Start

### Installation

#### Homebrew (Recommended, Apple Silicon macOS 14+)
```bash
brew tap Smith-Tools/smith
brew install smith-validation
```
Notes:
- Bottles are arm64-only (Apple Silicon). Intel/macOS <14 will build from source.
- Tested on macOS 14+.

#### Build from Source
```bash
git clone https://github.com/Smith-Tools/smith-validation.git
cd smith-validation
swift build -c release
```

#### Homebrew (for users)
```bash
brew tap Smith-Tools/smith
brew install smith-validation
smith-validation --engine /path/to/project
```

#### Faster local runs (keep `.build` warm)
```bash
cd smith-validation
swift build -c release                      # one-time warm build
./.build/release/smith-validation --engine /path/to/project   # reuse, no rebuild
```
Do not commit or ship `.build/`; it is only for local/CI caching.


### 🚦 CLI Usage (engine mode)

```
smith-validation --engine /path/to/project

Options:
  --include pat1,pat2   Glob(s) to include (default: **/*.swift)
  --exclude pat1,pat2   Glob(s) to exclude (default: **/DerivedData/**,**/.build/**,**/Pods/**,**/.swiftpm/**)
  --version, -v         Print version
```

Notes:
- Supplying a path (or `--engine`) runs the engine; otherwise legacy mode prints demo output.
- Defaults skip common third-party/derived locations to avoid validating vendored/derived code.
- Progress logs show include/exclude globs and file count.

### 🧪 Run Swift Testing rule packs (dynamic)

```
smith-validation --rules-tests /path/to/rule-pack /path/to/project
```

- The rule pack is a SwiftPM package with tests that emit findings via `RuleTestEmitter.emit(...)`.
- smith-validation sets `SMITH_RULES_PROJECT_ROOT`, `SMITH_RULES_INCLUDE`, `SMITH_RULES_EXCLUDE` for the test process.
- Useful when teams maintain custom rules without rebuilding the CLI.

### Basic Usage

```bash
# Validate current directory (engine mode - recommended)
smith-validation --engine .

# Validate specific project
smith-validation --engine /path/to/swift/project

# Run with configuration file
smith-validation --engine . --config config.pkl

# Legacy demo mode (with embedded test code)
smith-validation
```

## 📋 Built-in Rule Packs

### Maxwells TCA Rules (Included)

The engine comes with a TCA-specific rule pack that validates The Composable Architecture patterns:

#### Rule 1.1: Monolithic Features
Detects overly complex State structs and Action enums.

**Example Violation:**
```swift
@Reducer
struct Feature {
    struct State: Equatable {
        var navigation: NavigationState
        var userData: UserData
        var search: SearchState
        var filter: FilterState
        var settings: SettingsState
        var loading: LoadingState
        var error: ErrorState
        var analytics: AnalyticsState
        var cache: CacheState
        var sync: SyncState
        var export: ExportState
        var import: ImportState
        var sharing: SharingState
        var offline: OfflineState
        var performance: PerformanceState
        var debug: DebugState  // 16+ properties
    }
}
```

#### Rule 1.2: Proper Dependency Injection
Ensures dependencies use the `@Dependency` system.

#### Rule 1.3: Code Duplication
Identifies duplicated code patterns.

#### Rule 1.4: Unclear Organization
Detects vague naming and poor organization.

#### Rule 1.5: Tightly Coupled State
Finds State structs managing too many unrelated features.

## 📊 Output Example

```bash
$ smith-validation --engine ./MyProject

=== smith-validation (engine mode) ===
✅ Engine running 5 rule(s)

🔍 smith-validation - Architectural Validation
📁 Validating Swift files in: ./MyProject

📊 Found 850 Swift files, parsed 842 successfully

╔══════════════════════════════════════════════════════════════════════════════╗
║                    🧠 SMITH VALIDATION - ARCHITECTURAL REPORT                 ║
╚══════════════════════════════════════════════════════════════════════════════╝

📊 VALIDATION SUMMARY
   Files Scanned: 842
   Files Parsed: 842
   Health Score: 89%

⚠️  12 VIOLATIONS DETECTED - Review recommended

📋 VIOLATION BREAKDOWN:

TCA Pack (Rules 1.1–1.5)
────────────────────────
   • UserProfileFeature.swift:25
     TCA-1.1-MonolithicFeatures: State struct has >15 properties (found 18)
     💡 Consider splitting into multiple child features

   • NetworkManager.swift:15
     TCA-1.2-ClosureInjection: Direct client instantiation detected
     💡 Use @Dependency(\.apiClient) instead

───────────────────────────────────────────────────────────────────────────────
🤖 Generated by smith-validation - Architectural Pattern Detection
```

## ⚙️ Configuration

### PKL Configuration

Create a `config.pkl` file to configure rule packs:

```pkl
smithValidation {
  bundles {
    tcaRules {
      enabled = true
      path = "./maxwells-tca-rules"
    }

    customRules {
      enabled = true
      path = "./my-custom-rules"
    }
  }

  settings {
    enableCaching = true
    parallelExecution = false
    maxConcurrentValidations = 4
  }
}
```

### Rule Pack Structure

A rule pack is a SwiftPM package that exports validation rules:

```swift
// MyCustomRules.swift
import SmithValidationCore

struct CustomRule1: ValidatableRule {
    func validate(context: SourceFileContext) -> ViolationCollection {
        // Your validation logic here
        return ViolationCollection(violations: [])
    }
}

// Registrar.swift
import Foundation
import SmithValidationCore

@_cdecl("smith_register_rules")
public func smith_register_rules() -> UnsafeMutableRawPointer {
    let rules: [Any] = [CustomRule1(), CustomRule2()]
    return Unmanaged.passRetained(rules as NSArray).toOpaque()
}
```

## 🏗️ Architecture

```
smith-validation (CLI)
├── SmithValidationCore (Framework)
│   ├── SwiftSyntax AST parsing
│   ├── Violation reporting models
│   ├── Configuration management
│   └── Performance optimization
├── MaxwellsTCARules (Sample Rule Pack)
│   └── TCA-specific validation rules
├── ValidationEngine (Rule execution)
├── RuleLoader (Dynamic rule discovery)
└── PKL Configuration (Flexible config)
```

## 🔧 Creating Custom Rules

### Basic Rule

```swift
import SmithValidationCore
import SwiftSyntax

struct MyCustomRule: ValidatableRule {
    func validate(context: SourceFileContext) -> ViolationCollection {
        var violations: [ArchitecturalViolation] = []

        // Walk the AST to find violations
        let visitor = MyRuleVisitor { violation in
            violations.append(violation)
        }
        visitor.walk(context.syntax)

        return ViolationCollection(violations: violations)
    }
}
```

### AST Visitor

```swift
class MyRuleVisitor: SyntaxVisitor {
    private let onViolation: (ArchitecturalViolation) -> Void

    init(onViolation: @escaping (ArchitecturalViolation) -> Void) {
        self.onViolation = onViolation
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        // Check function declarations for violations
        if isTooComplex(node) {
            onViolation(.high(
                rule: "CustomRule-ComplexFunction",
                file: node.location.file,
                line: node.location.line,
                message: "Function is too complex",
                recommendation: "Split into smaller functions"
            ))
        }
        return .skipChildren
    }
}
```

## 🔧 Integration

### Swift Package Integration

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/Smith-Tools/smith-validation.git", from: "1.0.0")
]
```

```swift
import SmithValidation

let engine = ValidationEngine()
let violations = try engine.validate(
    rules: [MyCustomRule(), AnotherRule()],
    directory: "."
)
```

### CI/CD Integration

#### GitHub Actions
```yaml
name: Architecture Validation
on: [push, pull_request]

jobs:
  validate:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install smith-validation
        run: brew tap Smith-Tools/smith && brew install smith-validation
      - name: Validate Architecture
        run: smith-validation --engine .
```

## 📈 Performance

smith-validation is optimized for large codebases:

| Project Size | Files | Validation Time | Memory Usage |
|-------------|-------|-----------------|--------------|
| Small       | <50   | <2 seconds      | ~50MB        |
| Medium      | 50-200| <10 seconds     | ~100MB       |
| Large       | 200+  | <60 seconds     | ~200MB       |
| Very Large  | 842   | ~90 seconds     | ~180MB       |

## 🧪 Development

### Building

```bash
git clone https://github.com/Smith-Tools/smith-validation.git
cd smith-validation
swift build -c release
```

### Testing

```bash
swift test
```

### Creating Rule Packs

1. Create a new SwiftPM package
2. Add SmithValidationCore as a dependency
3. Implement rules conforming to `ValidatableRule`
4. Export rules via `smith_register_rules` function
5. Configure in PKL to load your pack

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🔗 Links

- [GitHub Repository](https://github.com/Smith-Tools/smith-validation)
- [Issues and Support](https://github.com/Smith-Tools/smith-validation/issues)
- [Smith Tools Organization](https://github.com/Smith-Tools)
- [Homebrew Tap](https://github.com/Smith-Tools/homebrew-smith)

---

**smith-validation** - Pluggable architectural validation for Swift, built with ❤️ by the Smith Tools team
