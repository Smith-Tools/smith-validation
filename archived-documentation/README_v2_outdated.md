# smith-validation

> **AI-Optimized Progressive Intelligence Architectural Analysis for Swift**

[![Release](https://img.shields.io/github/release/Smith-Tools/smith-validation.svg)](https://github.com/Smith-Tools/smith-validation/releases)
[![Swift](https://img.shields.io/badge/swift-5.9%2B-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

smith-validation is a **Progressive Intelligence architectural analysis engine** for Swift projects. It provides three levels of analysis depth, from critical violations to comprehensive insights, with AI-optimized JSON output perfect for Claude agents and automated workflows.

## ✨ Progressive Intelligence Features

### 🧠 Three Analysis Levels
- **Critical**: Only critical + high severity violations (fastest)
- **Standard**: All architectural violations with smart filtering
- **Comprehensive**: Standard analysis + pattern insights + architectural hotspots

### 🤖 AI-Optimized JSON Output
- Structured JSON perfect for Claude agents and automation
- Progressive recommendations based on analysis level
- Cross-domain insights for strategic architectural improvements
- Automation confidence scoring for fix prioritization

### 🎯 Enhanced Architectural Rules
- **TCA Missing Error Handling**: Detect Action enums without error cases
- **Monolithic Features**: Identify State structs with >15 properties
- **High Coupling**: Files with excessive imports (>15)
- **Architectural Hotspots**: Pattern-based insights for comprehensive refactoring

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

# Comprehensive analysis with hotspots
smith-validation /path/to/project --level=comprehensive

# Default is critical level
smith-validation /path/to/project
```

### Usage Examples

```bash
# Analyze current directory with critical violations
smith-validation . --level=critical

# Comprehensive analysis of your project
smith-validation ~/Projects/MyApp --level=comprehensive

# Standard analysis for CI/CD pipelines
smith-validation . --level=standard
```

## 📊 AI-Optimized Output

smith-validation produces structured JSON perfect for:

- **Claude Agent Integration**: Direct consumption by AI assistants
- **Automated Workflows**: CI/CD pipeline integration
- **Progressive Filtering**: Different analysis depths for different needs
- **Smart Recommendations**: Context-aware architectural advice

### Example Output (Critical Level)

```json
{
  "analysisType": "smith-validation-progressive-intelligence",
  "analysisLevel": "critical",
  "timestamp": "2025-11-22T17:59:11Z",
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

## 🎯 Progressive Intelligence Analysis Levels

### 🔴 Critical Level
Only shows critical and high-severity violations that need immediate attention:
- Missing error handling in TCA Action enums
- Monolithic State structs (>15 properties)
- Perfect for quick code reviews and CI checks

### 🟠 Standard Level
Shows all violations with complete architectural analysis:
- All critical and high violations
- Medium and low severity issues
- Recommended for regular development workflows

### 🟡 Comprehensive Level
Standard analysis plus advanced pattern insights:
- Architectural hotspots (files with 5+ violations)
- Cross-domain pattern analysis
- Strategic refactoring recommendations
- Ideal for architectural reviews and planning

## 🏗️ Built-in Rules

### TCA-Focused Rules

#### TCA Missing Error Handling (Critical)
Detects Action enums without error handling cases:

```swift
enum FeatureAction {
    case load
    case loaded(UserData)
    case save(UserData)
    // Missing: case error(Error)
    // Missing: case loadFailed(Error)
}
```

#### Monolithic Features (High)
Identifies State structs with excessive complexity:

```swift
@Reducer
struct Feature {
    struct State: Equatable {
        var user: UserState
        var navigation: NavigationState
        var search: SearchState
        var filter: FilterState
        var settings: SettingsState
        var loading: LoadingState
        var error: ErrorState
        var analytics: AnalyticsState
        var cache: CacheState
        var sync: SyncState
        // ... 21 total properties (>15 threshold)
    }
}
```

#### High Coupling (Medium)
Detects files with too many dependencies:

```swift
import Foundation
import SwiftUI
import Combine
import Networking
import Database
import Auth
import Analytics
import Cache
import Settings
import Storage
import Utilities
import Helpers
import Logging
import Monitoring
// ... 18 total imports (>15 threshold)
```

#### Architectural Hotspots (Comprehensive)
Identifies files with multiple violations needing comprehensive refactoring.

## 🔧 Integration Examples

### Claude Agent Integration
```python
import subprocess
import json

def analyze_swift_project(project_path, level="critical"):
    """Analyze Swift project with smith-validation"""
    result = subprocess.run([
        "smith-validation", project_path, f"--level={level}"
    ], capture_output=True, text=True)

    if result.returncode == 0:
        analysis = json.loads(result.stdout)
        return {
            "violations": analysis["findings"],
            "health_score": analysis["summary"]["healthScore"],
            "recommendations": analysis["recommendations"]
        }
    else:
        return {"error": result.stderr}

# Usage
result = analyze_swift_project("./MyApp", level="comprehensive")
print(f"Health Score: {result['health_score']}%")
```

### CI/CD Integration

#### GitHub Actions
```yaml
name: Progressive Intelligence Analysis
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
          smith-validation . --level=critical > critical-analysis.json
          echo "## Critical Violations" >> $GITHUB_STEP_SUMMARY
          cat critical-analysis.json >> $GITHUB_STEP_SUMMARY
      - name: Comprehensive Analysis
        run: |
          smith-validation . --level=comprehensive > comprehensive-analysis.json
```

#### Makefile Integration
```makefile
.PHONY: analyze-critical analyze-standard analyze-comprehensive

analyze-critical:
	smith-validation . --level=critical | jq .

analyze-standard:
	smith-validation . --level=standard | jq .

analyze-comprehensive:
	smith-validation . --level=comprehensive | jq .
```

## 📈 Performance & Scalability

smith-validation is optimized for projects of all sizes:

| Analysis Level | Small (<50 files) | Medium (50-200 files) | Large (200+ files) |
|---------------|------------------|---------------------|-------------------|
| Critical       | <1 second        | <3 seconds          | <10 seconds       |
| Standard       | <2 seconds        | <8 seconds          | <25 seconds       |
| Comprehensive  | <3 seconds        | <15 seconds         | <45 seconds       |

Memory usage scales linearly with project size and analysis depth.

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

### Testing Progressive Intelligence
```bash
# Test different analysis levels
./.build/release/smith-validation /path/to/test/project --level=critical
./.build/release/smith-validation /path/to/test/project --level=standard
./.build/release/smith-validation /path/to/test/project --level=comprehensive
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🔗 Links

- [GitHub Repository](https://github.com/Smith-Tools/smith-validation)
- [v2.0.0 Release](https://github.com/Smith-Tools/smith-validation/releases/tag/v2.0.0)
- [Issues and Support](https://github.com/Smith-Tools/smith-validation/issues)
- [Smith Tools Organization](https://github.com/Smith-Tools)
- [Homebrew Tap](https://github.com/Smith-Tools/homebrew-smith)

---

**smith-validation v2.0.0** - Progressive Intelligence architectural analysis for Swift, built with ❤️ by the Smith Tools team

🚀 **Perfect for**: AI agents, automated code review, architectural debt analysis, and progressive development workflows