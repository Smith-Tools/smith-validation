---
name: smith-validation
description: Progressive intelligence architectural validation for Swift. Automatically triggers for:
             Code quality analysis, architectural violations, TCA patterns, design patterns, monolithic features
allowed-tools: [Bash, Read]
executables: ["~/.local/bin/smith-validation", ".build/arm64-apple-macosx/release/smith-validation", "smith-validation"]
---

# Architectural Validation Analysis

Provides progressive intelligence architectural analysis for Swift projects with three analysis levels.

## Automatic Usage

This skill activates when users ask about:
- "Validate my Swift project architecture"
- "Check for TCA violations"
- "Analyze code quality"
- "Find architectural issues"
- "Design pattern analysis"

## Commands

**Critical violations only** (fastest):
```bash
smith-validation . --level=critical
# Returns: Only critical and high-severity violations (quick gate)
```

**Standard analysis** (all violations):
```bash
smith-validation . --level=standard
# Returns: Complete violation set with recommendations
```

**Comprehensive analysis** (with hotspots):
```bash
smith-validation . --level=comprehensive
# Returns: All violations + pattern insights + architectural hotspots
```

**Specific project path**:
```bash
smith-validation ~/Projects/MyApp --level=comprehensive
```

## Analysis Levels

### 🔴 Critical
- Missing error handling in TCA Action enums
- Monolithic State structs (>15 properties)
- High coupling (>15 imports)
- Perfect for CI gates and quick reviews

### 🟠 Standard
- All critical violations
- Medium and low severity issues
- Recommended for regular development

### 🟡 Comprehensive
- Standard analysis plus:
- Architectural hotspots (files with 5+ violations)
- Cross-domain pattern analysis
- Strategic refactoring recommendations

## Built-in Rules

### TCA Missing Error Handling (Critical)
Detects Action enums without error cases:
```swift
enum FeatureAction {
    case load
    case loaded(Data)
    // Missing: case error(Error)
}
```

### Monolithic Features (High)
State structs with >15 properties:
```swift
struct State: Equatable {
    var user: UserState
    var navigation: NavigationState
    // ... 21 total properties
}
```

### High Coupling (Medium)
Files with >15 imports:
```swift
import Foundation
import SwiftUI
// ... 18 total imports
```

## Output Structure

```json
{
  "analysisLevel": "critical",
  "summary": {
    "totalFiles": 25,
    "violationsCount": 2,
    "healthScore": 85,
    "severity": {
      "critical": 1,
      "high": 1
    }
  },
  "findings": [{
    "ruleName": "TCA-Missing-Error-Handling",
    "severity": "critical",
    "fileName": "FeatureReducer.swift",
    "automationConfidence": 0.88,
    "recommendedAction": "Add error-related action cases"
  }],
  "recommendations": [...]
}
```

## Integration with Smith Tools

Works with the Smith Tools ecosystem:

- **smith-sbsift** - Swift build analysis
- **smith-spmsift** - Package dependency analysis
- **smith-xcsift** - Xcode build analysis

## Performance

| Level | Small (<50 files) | Medium (50-200) | Large (200+) |
|-------|-------------------|-----------------|--------------|
| Critical | <1s | <3s | <10s |
| Standard | <2s | <8s | <25s |
| Comprehensive | <3s | <15s | <45s |

## CI/CD Integration

### GitHub Actions
```yaml
- name: Critical Analysis
  run: smith-validation . --level=critical

- name: Comprehensive Analysis
  run: smith-validation . --level=comprehensive > analysis.json
```

### Makefile
```makefile
analyze-critical:
	smith-validation . --level=critical | jq .
```

---

**smith-validation** - Progressive Intelligence architectural analysis for Swift

Last Updated: November 26, 2025
