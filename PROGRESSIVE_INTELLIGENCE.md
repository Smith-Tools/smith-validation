# Smith Validation - Progressive Intelligence Architecture

## 🎯 Overview

Smith Validation implements **Progressive Intelligence** - a severity-based analysis approach that optimizes for different use cases, from quick AI agent checks to comprehensive architectural reviews.

## 📊 Analysis Levels

### **Critical Mode** (Default)
**Optimized for AI agents and fast development cycles**

```bash
smith-validation <project-path>
# or explicitly:
smith-validation <project-path> --level=critical
```

**Output Characteristics:**
- **Filter:** Only critical + high severity violations
- **Size:** Minimal JSON (~500 bytes)
- **Focus:** Immediate action items
- **Use Case:** Quick CI/CD checks, automated agent decisions

**Sample Output:**
```json
{
  "analysisLevel": "critical",
  "summary": {
    "violationsCount": 30,
    "healthScore": 0,
    "severityBreakdown": {
      "critical": 0,
      "high": 30,
      "medium": 0,
      "low": 0
    }
  },
  "recommendations": [
    "⚠️ Review 30 high-priority violations",
    "💡 Use --level=standard for complete analysis"
  ],
  "findings": [
    // Only critical + high severity violations
  ]
}
```

### **Standard Mode** (Comprehensive)
**Full architectural analysis for development teams**

```bash
smith-validation <project-path> --level=standard
```

**Output Characteristics:**
- **Filter:** All violations
- **Size:** Complete JSON (~15KB)
- **Focus:** Detailed technical insights
- **Use Case:** Development reviews, pull request validation

**Sample Output:**
```json
{
  "analysisLevel": "standard",
  "summary": {
    "violationsCount": 30,
    "healthScore": 0,
    "severityBreakdown": {
      "critical": 0,
      "high": 30,
      "medium": 0,
      "low": 0
    }
  },
  "recommendations": [
    "⚠️ Review 30 high-priority violations",
    "📊 Consider architectural refactoring",
    "🔧 Address violations systematically"
  ],
  "findings": [
    // All violations with full details
  ]
}
```

### **Comprehensive Mode** (Strategic)
**Deep analysis with strategic insights**

```bash
smith-validation <project-path> --level=comprehensive
```

**Output Characteristics:**
- **Filter:** All violations + pattern analysis
- **Size:** Complete JSON (~16KB)
- **Focus:** Strategic architectural insights
- **Use Case:** Architecture reviews, technical debt assessment

**Sample Output:**
```json
{
  "analysisLevel": "comprehensive",
  "summary": {
    "violationsCount": 30,
    "healthScore": 0
  },
  "recommendations": [
    "⚠️ Review 30 high-priority violations",
    "📊 Consider architectural refactoring",
    "🔧 Address violations systematically",
    "📏 File size is primary concern - consider modularization strategy"
  ],
  "findings": [
    // All violations with enhanced strategic insights
  ]
}
```

## 🤖 AI Agent Integration

### **Optimal Agent Workflow**

1. **Initial Quick Check** (Default)
   ```bash
   smith-validation <project-path>
   ```
   - Fast feedback on critical issues
   - Minimal token cost
   - Immediate go/no-go decisions

2. **Conditional Deep Analysis**
   ```bash
   # If critical issues found, get full context
   smith-validation <project-path> --level=standard
   ```

3. **Strategic Assessment** (Optional)
   ```bash
   # For architectural reviews or technical debt analysis
   smith-validation <project-path> --level=comprehensive
   ```

### **Response Patterns**

**Critical Mode Response:**
```json
{
  "action": "review_high_priority",
  "count": 30,
  "files": ["FileBasedRuleEngine.swift", "main.swift"],
  "next_step": "use_standard_for_details"
}
```

**Standard Mode Response:**
```json
{
  "action": "detailed_review",
  "violations": [...],
  "health_score": 15,
  "recommendations": [...]
}
```

## 📈 Performance Characteristics

| Mode | Output Size | Processing Time | Token Cost | Use Case |
|------|-------------|------------------|------------|----------|
| Critical | ~500 bytes | < 0.1s | Minimal | CI/CD, Agents |
| Standard | ~15KB | ~0.5s | Medium | Development |
| Comprehensive | ~16KB | ~0.6s | Medium+ | Architecture |

## 🔧 Advanced Features

### **TypeScript Rule Engine** (Optional)
For developers who need advanced rule analysis:

```bash
smith-validation <project-path> --typescript --level=standard
```

**Features:**
- 12 complex TypeScript rules
- Domain-specific analysis (TCA, SwiftUI, Performance)
- JavaScriptCore execution
- SQLite analytics integration

### **Rule Reload**
For rule development and testing:

```bash
smith-validation <project-path> --reload
```

## 📋 Usage Examples

### **CI/CD Pipeline Integration**
```yaml
- name: Smith Validation (Critical)
  run: smith-validation . --level=critical

- name: Detailed Analysis (if needed)
  run: smith-validation . --level=standard
  if: failure()
```

### **AI Agent Integration**
```python
def analyze_project(project_path):
    # Quick check first
    result = run_smith_validation(project_path)

    if result['summary']['violationsCount'] > 0:
        # Get detailed analysis
        detailed = run_smith_validation(project_path, level='standard')
        return analyze_findings(detailed)

    return {'status': 'healthy', 'action': 'proceed'}
```

### **Development Workflow**
```bash
# During development - quick feedback
smith-validation .

# Before PR - comprehensive review
smith-validation . --level=standard

# Architecture review - strategic insights
smith-validation . --level=comprehensive
```

## 🎯 Design Principles

### **Progressive Disclosure**
- Start with most important information
- Allow drilling down when needed
- Respect developer attention and time

### **AI-First Design**
- Default mode optimized for agent consumption
- Structured JSON output for programmatic processing
- Clear action items and recommendations

### **Domain Agnostic**
- Works across TCA, SwiftUI, Performance, General rules
- Cross-domain architectural insights
- Scalable from 50 to 5000+ files

### **Performance Optimized**
- Minimal output for quick decisions
- Configurable detail levels
- Efficient processing for large codebases

## 🚀 Getting Started

1. **Basic Usage:**
   ```bash
   smith-validation <project-path>
   ```

2. **Choose Your Level:**
   ```bash
   smith-validation <project-path> --level=standard     # Full analysis
   smith-validation <project-path> --level=comprehensive  # Strategic insights
   ```

3. **Advanced Analysis:**
   ```bash
   smith-validation <project-path> --typescript --level=standard
   ```

The **Progressive Intelligence** architecture ensures Smith Validation is both **fast enough for automated agents** and **detailed enough for human developers**, providing the right level of insight for each use case.