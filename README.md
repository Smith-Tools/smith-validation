# smith-validation

> **CLI-based Swift architectural analysis tool**

[![Release](https://img.shields.io/github/release/Smith-Tools/smith-validation.svg)](https://github.com/Smith-Tools/smith-validation/releases)
[![Swift](https://img.shields.io/badge/swift-5.9%2B-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

smith-validation is a **CLI-based architectural analysis tool** for Swift projects that provides rapid architectural health assessment with JSON output perfect for CI/CD pipelines and automated workflows.

## ✨ Current Features

### 🎯 CLI-First Analysis
- **Fast Analysis**: External tool with no compile-time dependencies
- **JSON Output**: Structured results perfect for automation
- **Progressive Intelligence**: Three analysis levels (critical, standard, comprehensive)

### 🔍 Built-in Validation Rules

#### Critical Rules
- **TCA Missing Error Handling**: Detects Action enums without error cases

#### High Severity Rules
- **TCA Monolithic State**: Identifies State structs with >15 properties

#### Medium Severity Rules
- **High Coupling**: Files with >15 imports

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

## 🎮 CLI Usage

### Progressive Intelligence Analysis

```bash
# Critical violations only (fastest)
smith-validation /path/to/project --level=critical

# Standard analysis (all violations)
smith-validation /path/to/project --level=standard

# Comprehensive analysis with architectural hotspots
smith-validation /path/to/project --level=comprehensive

# Default is critical level
smith-validation /path/to/project
```

### Example Usage

```bash
# Analyze current directory for critical violations
smith-validation . --level=critical

# Comprehensive analysis of your project
smith-validation ~/Projects/MyApp --level=comprehensive
```

## 📊 Output Format

smith-validation produces structured JSON:

### Example Output
```json
{
  "analysisType": "smith-validation-progressive-intelligence",
  "analysisLevel": "critical",
  "timestamp": "2025-11-26T19:16:00Z",
  "projectPath": "/path/to/project",
  "summary": {
    "totalFiles": 25,
    "violationsCount": 2,
    "healthScore": 85,
    "severityBreakdown": {
      "critical": 1,
      "high": 1,
      "medium": 0,
      "low": 0
    },
    "automation": {
      "automatableFixes": 2,
      "averageConfidence": 0.85
    }
  },
  "findings": [
    {
      "ruleName": "TCA-Missing-Error-Handling",
      "severity": "critical",
      "fileName": "FeatureReducer.swift",
      "filePath": "/path/to/FeatureReducer.swift",
      "hasViolation": true,
      "automationConfidence": 0.88,
      "recommendedAction": "Add error-related action cases like 'errorOccurred(String)' or 'loadFailed(Error)'",
      "type": "missing_error_handling"
    }
  ],
  "recommendations": [
    "🚨 Address 1 critical violations immediately"
  ]
}
```

## 🎯 Analysis Levels

### 🔴 Critical Level (Default)
Only shows critical and high-severity violations that need immediate attention:
- Perfect for quick code reviews and CI checks
- Fastest execution time

### 🟠 Standard Level
Shows all violations with complete architectural analysis:
- Recommended for regular development workflows
- Medium severity issues included

### 🟡 Comprehensive Level
Standard analysis plus architectural insights:
- Cross-domain pattern analysis
- Architectural hotspots identification
- Strategic refactoring recommendations

## 🔧 Integration Examples

### CI/CD Integration

#### GitHub Actions
```yaml
name: Smith Validation
on: [push, pull_request]

jobs:
  analyze:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install smith-validation
        run: brew tap Smith-Tools/smith && brew install smith-validation
      - name: Critical Analysis
        run: |
          smith-validation . --level=critical > smith-results.json
          echo "## Smith Validation Results" >> $GITHUB_STEP_SUMMARY
          cat smith-results.json >> $GITHUB_STEP_SUMMARY
```

#### Makefile Integration
```makefile
.PHONY: smith-critical smith-standard smith-comprehensive

smith-critical:
	smith-validation . --level=critical | jq .

smith-standard:
	smith-validation . --level=standard | jq .

smith-comprehensive:
	smith-validation . --level=comprehensive | jq .
```

## 📈 Performance

| Analysis Level | Small (<50 files) | Medium (50-200 files) | Large (200+ files) |
|---------------|------------------|---------------------|-------------------|
| Critical       | <1 second        | <3 seconds          | <10 seconds       |
| Standard       | <2 seconds        | <8 seconds          | <25 seconds       |
| Comprehensive  | <3 seconds        | <15 seconds         | <45 seconds       |

## 🏗️ Architecture

### Current Implementation
- **CLI Tool**: External analysis with no project dependencies
- **Regex-based**: Fast pattern matching for common violations
- **JSON Output**: Machine-readable results for automation
- **Three-tier Analysis**: Critical/Standard/Comprehensive intelligence levels

### Dependencies
- **Swift 5.9+**: Foundation + Regex only
- **SwiftSyntax**: Via swift-testing transitive dependency
- **Swift Testing**: Advanced testing framework (unused in current CLI)

## 🧪 Development

### Building from Source
```bash
git clone https://github.com/Smith-Tools/smith-validation.git
cd smith-validation
swift build -c release
```

### Running Tests
```bash
swift test
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🔗 Links

- [GitHub Repository](https://github.com/Smith-Tools/smith-validation)
- [Issues and Support](https://github.com/Smith-Tools/smith-validation/issues)
- [Smith Tools Organization](https://github.com/Smith-Tools)
- [Homebrew Tap](https://github.com/Smith-Tools/homebrew-smith)

---

**smith-validation v2.0.0** - Fast CLI architectural analysis for Swift, built with ❤️ by the Smith Tools team

🚀 **Perfect for**: CI/CD pipelines, automated code review, architectural debt analysis