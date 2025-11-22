/// General Rule: Circular Dependencies Validator
/// Detects potential circular dependencies in Swift code

export function validate(context) {
    const astBridge = context.astBridge;
    const ruleEngine = context.ruleEngine;
    const currentSourceCode = astBridge.currentSourceCode;
    const fileName = astBridge.currentFile.fileName;
    
    // Look for import statements and class declarations
    const importPattern = /import\s+([A-Za-z0-9_]+)/g;
    const classPattern = /class\s+([A-Za-z0-9_]+)/g;
    const structPattern = /struct\s+([A-Za-z0-9_]+)/g;
    
    const imports = [...currentSourceCode.matchAll(importPattern)].map(m => m[1]);
    const classes = [...currentSourceCode.matchAll(classPattern)].map(m => m[1]);
    const structs = [...currentSourceCode.matchAll(structPattern)].map(m => m[1]);
    
    // Simple heuristic: if a file imports a module that might contain types that import back
    const suspiciousPatterns = [
        /import.*Foundation/,
        /import.*SwiftUI/,
        /import.*Combine/
    ];
    
    let potentialIssues = 0;
    suspiciousPatterns.forEach(pattern => {
        if (pattern.test(currentSourceCode)) {
            potentialIssues++;
        }
    });
    
    // Check for overly complex dependency patterns
    const nestedPropertyPattern = /\w+\.\w+\.\w+/g;
    const nestedMatches = currentSourceCode.match(nestedPropertyPattern);
    
    if (nestedMatches && nestedMatches.length > 10) {
        ruleEngine.addViolation({
            ruleName: "Circular Dependencies",
            severity: "low",
            actualValue: `Found ${nestedMatches.length} deeply nested property accesses`,
            expectedValue: "Reduce deep nesting to avoid potential circular dependencies",
            automationConfidence: 0.6,
            recommendedAction: "Consider flattening dependencies or using dependency injection to reduce coupling",
            targetName: fileName
        });
    }
}
