# smith-validation

> **TCA** architectural validation engine for Swift projects

[![Release](https://img.shields.io/github/release/Smith-Tools/smith-validation.svg)](https://github.com/Smith-Tools/smith-validation/releases)
[![Swift](https://img.shields.io/badge/swift-5.9%2B-orange.svg)](https://swift.org)
[![TCA](https://img.shields.io/badge/TCA-Compatible-blue.svg)](https://github.com/pointfreeco/swift-composable-architecture)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

smith-validation is a **specialized validation engine** that enforces architectural best practices for projects using **The Composable Architecture (TCA)**. It analyzes your Swift/TCA code, detects anti-patterns, and provides actionable recommendations to improve code quality and maintainability.

> **Note**: This tool is specifically designed for TCA projects and validates against Maxwells TCA architectural rules.

## ✨ Features

- **5 TCA-Specific Rules**: Based on Maxwells TCA architectural patterns
- **AST-Based Analysis**: Deep understanding of your TCA code structure using SwiftSyntax
- **Actionable Recommendations**: Not just problems, but specific TCA solutions
- **Fast Performance**: Optimized for large TCA codebases (validated on 850+ TCA files)
- **Engine Mode**: Advanced validation with dynamic rule loading
- **PKL Configuration**: Customizable rule behavior and thresholds

## 🚀 Quick Start

### Installation

#### Homebrew (Recommended)
```bash
brew tap Smith-Tools/smith
brew install smith-validation
```

#### Build from Source
```bash
git clone https://github.com/Smith-Tools/smith-validation.git
cd smith-validation
swift build -c release
```

### Basic Usage

```bash
# Validate TCA project (engine mode - recommended)
smith-validation --engine /path/to/tca/project

# Legacy demo mode (embedded test code)
smith-validation

# Run with configuration file
smith-validation --engine . --config config.pkl
```

## 📋 TCA Validation Rules

### Rule 1.1: Monolithic Features
Detects overly complex TCA State structs and Action enums that violate single responsibility principle.

**TCA Thresholds:**
- State structs with >15 properties
- Action enums with >40 cases

**TCA Violation Example:**
```swift
@Reducer
struct ReadingLibraryFeature {
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
        public var search: SearchFeature.State
        public var filter: FilterFeature.State
        public var settings: SettingsFeature.State
        public var share: ShareFeature.State
        public var export: ExportFeature.State
        public var sync: SyncFeature.State
        public var debug: DebugFeature.State
        public var performance: PerformanceFeature.State

        // This should be >15 properties (violating Rule 1.1)
    }
}
```

**TCA Recommendation:**
```swift
@Reducer
struct ReadingLibraryFeature {
    public struct State: Equatable {
        // Core navigation and data
        public var primarySelection: ArticleSidebarDestination?
        public var articleSelection: Article.ID?
        public var articles: IdentifiedArrayOf<Article>

        // Extract child features
        @Presents var search: SearchFeature.State?
        @Presents var tags: TagsFeature.State?
        @Presents var reader: ArticleReaderFeature.State?
    }
}
```

### Rule 1.2: Proper Dependency Injection
Ensures TCA dependencies use the `@Dependency` system instead of direct instantiation.

**TCA Violation:**
```swift
@Reducer
struct Feature {
    @Dependency(\.apiClient) var apiClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .loadArticles:
                // Anti-pattern: Direct client usage instead of proper dependency injection
                Task {
                    let articles = try await apiClient.fetchArticles()
                    // Direct state mutation outside of Reduce scope
                    state.articles = IdentifiedArrayOf(uniqueElements: articles)
                }
                return .none
            }
        }
    }
}
```

**TCA Recommendation:**
```swift
@Reducer
struct Feature {
    @Dependency(\.apiClient) var apiClient
    @Dependency(\.database) var database

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .loadArticles:
                return .run { send in
                    let articles = try await apiClient.fetchArticles()
                    await send(.articlesResponse(articles))
                }
            }
        }
    }
}
```

### Rule 1.3: Code Duplication
Identifies duplicated TCA code patterns that should be extracted into shared components.

### Rule 1.4: Unclear Organization
Detects vague naming conventions and poor TCA code organization that reduce maintainability.

### Rule 1.5: Tightly Coupled State
Finds TCA State structs that manage too many unrelated child features or mix different domains.

**TCA Violation:**
```swift
@Reducer
struct ComplexFeature {
    struct State: Equatable {
        // Too many unrelated child features (violates Rule 1.5)
        var search: SearchFeature.State
        var filter: FilterFeature.State
        var tags: TagsFeature.State
        var inspector: InspectorFeature.State
        var importExport: ImportExportFeature.State
        var smartFolders: SmartFolderFeature.State
        var manualFolders: ManualFolderFeature.State
        var settings: SettingsFeature.State
        var share: ShareFeature.State
    }

    enum Action: BindableAction, Equatable {
        case search(SearchFeature.Action)
        case filter(FilterFeature.Action)
        case tags(TagsFeature.Action)
        case inspector(InspectorFeature.Action)
        case importExport(ImportExportFeature.Action)
        case smartFolders(SmartFolderFeature.Action)
        case manualFolders(ManualFolderFeature.Action)
        case settings(SettingsFeature.Action)
        case share(ShareFeature.Action)
        case set(\\BindingStateAction<State>)
    }
}
```

## 📊 Output Example

```bash
$ smith-validation --engine ./MyTCAProject

=== smith-validation (engine mode) ===
⚙️  Loading config from PKL: config.pkl
✅ Engine running 5 rule(s)

🔍 smith-validation - TCA Architectural Validation
📁 Validating Swift files in: ./MyTCAProject

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

   • SearchFeature.swift:42
     TCA-1.5-TightlyCoupledState: Reducer handles too many child features (8 detected)
     💡 Extract child features into separate reducers with proper parent-child communication

   • NetworkManager.swift:15
     TCA-1.2-ClosureInjection: Direct client instantiation detected
     💡 Use @Dependency(\.apiClient) instead

───────────────────────────────────────────────────────────────────────────────
🤖 Generated by smith-validation - TCA Architectural Pattern Detection
📖 Framework: The Composable Architecture (TCA)
🎯 Rules: Monolithic Features, Dependencies, Duplication, Organization, Coupling
```

## ⚙️ Configuration

### PKL Configuration

Create a `config.pkl` file to customize TCA validation behavior:

```pkl
smithValidation {
  bundles {
    maxwellsTCARules {
      enabled = true
      path = "./maxwells-tca-rules"
    }
  }

  thresholds {
    maxStateProperties = 12  // Stricter than default
    maxActionCases = 30
    maxChildFeatures = 4
  }
}
```

### Programmatic Configuration

```swift
import SmithValidation
import MaxwellsTCARules

let engine = ValidationEngine()
let violations = try engine.validate(
    rules: registerMaxwellsRules(),
    directory: "/path/to/tca/project",
    recursive: true
)
```

## 🔧 TCA Integration

### CI/CD Integration

#### GitHub Actions
```yaml
name: TCA Validation
on: [push, pull_request]

jobs:
  validate-tca:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install smith-validation
        run: brew tap Smith-Tools/smith && brew install smith-validation
      - name: Validate TCA Architecture
        run: smith-validation --engine .
```

#### Pre-commit Hook
```bash
#!/bin/sh
# .git/hooks/pre-commit

echo "🔍 Running TCA validation..."
smith-validation --engine .

if [ $? -ne 0 ]; then
    echo "❌ TCA validation failed. Please fix violations before committing."
    exit 1
fi
```

### Swift Package Integration

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/Smith-Tools/smith-validation.git", from: "1.0.0")
]
```

```swift
import SmithValidation
import MaxwellsTCARules

// Run TCA validation programmatically
let engine = ValidationEngine()
let violations = try engine.validate(rules: registerMaxwellsRules(), directory: ".")
```

## 📈 Performance

smith-validation is optimized for TCA projects:

| TCA Project Size | Files | Validation Time | Memory Usage |
|------------------|-------|-----------------|--------------|
| Small            | <50   | <2 seconds      | ~50MB        |
| Medium           | 50-200| <10 seconds     | ~100MB       |
| Large            | 200+  | <60 seconds     | ~200MB       |
| Scroll Project   | 842   | ~90 seconds     | ~180MB       |

*Validated on real TCA project with 850+ TCA files*

## 🏗️ TCA Architecture

```
smith-validation (CLI)
├── SmithValidationCore (Framework)
│   ├── AST parsing for TCA syntax
│   ├── TCA violation reporting
│   └── Configuration management
├── MaxwellsTCARules (TCA-specific validation rules)
│   ├── Rule 1.1: Monolithic Features
│   ├── Rule 1.2: Dependency Injection
│   ├── Rule 1.3: Code Duplication
│   ├── Rule 1.4: Unclear Organization
│   └── Rule 1.5: Tightly Coupled State
├── ValidationEngine (Rule loading & execution)
└── PKL Configuration (Dynamic TCA rule discovery)
```

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

### Adding Custom TCA Rules

```swift
import SmithValidationCore

struct CustomTCARule: ValidatableRule {
    func validate(context: SourceFileContext) -> ViolationCollection {
        // Your TCA-specific validation logic here
        return ViolationCollection(violations: [])
    }
}
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🔗 Links

- [GitHub Repository](https://github.com/Smith-Tools/smith-validation)
- [Issues and Support](https://github.com/Smith-Tools/smith-validation/issues)
- [Smith Tools Organization](https://github.com/Smith-Tools)
- [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture)
- [Homebrew Tap](https://github.com/Smith-Tools/homebrew-smith)

---

**smith-validation** - TCA architectural validation built with ❤️ by the Smith Tools team