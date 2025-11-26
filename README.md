# smith-validation

> **CLI-based Swift architectural analysis tool**

[![Release](https://img.shields.io/github/release/Smith-Tools/smith-validation.svg)](https://github.com/Smith-Tools/smith-validation/releases)
[![Swift](https://img.shields.io/badge/swift-5.9%2B-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

smith-validation is an **AI-optimized Swift architectural analysis tool** that provides progressive intelligence analysis with JSON output perfect for CI/CD pipelines, AI agents, and automated workflows.

> **🤖 AI-Optimized for Anthropic Work**: Enhanced with actionable insights, automation confidence scores, and progressive intelligence levels designed for AI agent consumption.

## ✨ Current Features

### 🎯 AI-Optimized Features
- **Progressive Intelligence**: Three analysis levels optimized for token efficiency
- **Actionable Insights**: AI-ready recommendations with implementation steps
- **Automation Confidence**: Scores for automated fix reliability (0-1.0)
- **JSON Output**: Structured results perfect for AI agents and automation
- **Efficiency Metrics**: Performance scores for analysis optimization

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
# Critical violations only (token-optimized, fastest)
smith-validation /path/to/project --level=critical --format=json

# Standard analysis (all violations, balanced)
smith-validation /path/to/project --level=standard --format=json

# Comprehensive analysis with architectural hotspots (rich details)
smith-validation /path/to/project --level=comprehensive --format=json

# Human-readable summary
smith-validation /path/to/project --level=standard --format=summary

# Default is critical level with JSON output
smith-validation /path/to/project
```

### Example Usage

```bash
# AI-optimized analysis for Claude Code integration
smith-validation . --level=critical --format=json

# Standard analysis for development workflow
smith-validation ~/Projects/MyApp --level=standard --format=json

# Comprehensive analysis for strategic planning
smith-validation ~/Projects/MyApp --level=comprehensive --format=json
```

## 📊 AI-Optimized Output Format

smith-validation produces AI-optimized JSON with actionable insights and progressive intelligence:

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

### 🔴 Critical Level (Token-Optimized)
Only critical violations with maximum token efficiency:
- Perfect for AI agents and CI/CD checks
- Minimal output, fastest execution (<1s for most projects)
- 90%+ automation confidence on violations

### 🟠 Standard Level (Balanced)
All violations with complete architectural analysis:
- Recommended for development workflows
- Medium severity issues included
- 80%+ automation confidence on violations

### 🟡 Comprehensive Level (Rich Details)
Standard analysis plus strategic insights:
- Cross-domain pattern analysis
- Architectural hotspots identification
- Detailed implementation steps
- 70%+ automation confidence on violations

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
- **AI-Optimized CLI Tool**: External analysis with progressive intelligence
- **SwiftSyntax Integration**: AST-based analysis with accurate violation detection
- **JSON Output**: AI-ready results for automation and agents
- **Progressive Intelligence**: Three analysis levels with token optimization
- **Actionable Insights**: Automation confidence scores and implementation steps

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

**smith-validation v2.1.0** - AI-optimized progressive intelligence analysis for Swift, built with ❤️ by the Smith Tools team

🤖 **Perfect for**: AI agents, CI/CD pipelines, automated code review, architectural debt analysis

## 🤖 AI Integration

smith-validation is specifically designed for AI agent integration:

- **Token-Efficient Output**: Progressive levels minimize context usage
- **Structured Data**: Easy parsing and processing by AI agents
- **Actionable Recommendations**: AI can take direct action on violations
- **Confidence Scores**: AI can assess reliability of automated fixes
- **Implementation Steps**: Clear guidance for automated remediation