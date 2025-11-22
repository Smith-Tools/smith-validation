import Foundation

// Test our TypeScript compilation logic
func testCompileTypeScriptToJavaScript(_ sourceCode: String) -> String {
    var jsCode = sourceCode
    
    // Remove interface definitions
    jsCode = jsCode.replacingOccurrences(of: "interface\\s+\\w+\\s*\\{[^}]*\\}", with: "", options: .regularExpression)
    
    // Remove TypeScript type annotations
    jsCode = jsCode.replacingOccurrences(of: ":\\s*\\w+", with: "", options: .regularExpression)
    jsCode = jsCode.replacingOccurrences(of: ":\\s*'.*?'", with: "", options: .regularExpression)
    jsCode = jsCode.replacingOccurrences(of: ":\\s*string", with: "", options: [.regularExpression, .caseInsensitive])
    jsCode = jsCode.replacingOccurrences(of: ":\\s*number", with: "", options: [.regularExpression, .caseInsensitive])
    jsCode = jsCode.replacingOccurrences(of: ":\\s*boolean", with: "", options: [.regularExpression, .caseInsensitive])
    jsCode = jsCode.replacingOccurrences(of: ":\\s*void", with: "", options: [.regularExpression, .caseInsensitive])
    
    return jsCode
}

let tsCode = """
export function validate(context: GeneralRuleContext): void {
  const { currentFile, ruleEngine } = context;
  
  const currentLines = currentFile.lines;
  
  if (currentLines > 150) {
    ruleEngine.addViolation({
      ruleName: 'File Size Management',
      severity: 'high',
      actualValue: `${currentLines} lines in file`,
      expectedValue: `Files should have ≤150 lines`,
      automationConfidence: 0.85,
      recommendedAction: 'Extract smaller components from large file to improve maintainability',
      targetName: currentFile.fileName
    });
  }
}
"""

let jsCode = testCompileTypeScriptToJavaScript(tsCode)
print("=== Generated JavaScript ===")
print(jsCode)
print("=== End JavaScript ===")
