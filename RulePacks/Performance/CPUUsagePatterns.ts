/// Performance Rule: CPU Usage Patterns Validator
/// Detects patterns that may cause high CPU usage

export function validate(context) {
    const astBridge = context.astBridge;
    const ruleEngine = context.ruleEngine;
    const currentSourceCode = astBridge.currentSourceCode;
    const fileName = astBridge.currentFile.fileName;
    
    const issues = [];
    
    // Check for potentially expensive operations in hot paths
    const expensivePatterns = [
        { pattern: /while\s+true\s*\{/, desc: "Infinite while loop" },
        { pattern: /for\s+.*in\s+.*\{[^}]*for\s+/g, desc: "Nested loops" },
        { pattern: /\.\s*sorted\s*\(\)/g, desc: "Sorting operations" },
        { pattern: /\.\s*filter\s*\(\)\s*\.sorted\s*\(\)/g, desc: "Combined filter and sort" },
        { pattern: /UIImage\s*\([^)]*\)/g, desc: "UIImage creation in loops" },
        { pattern: /Data\s*\([^)]*\)/g, desc: "Data creation in loops" }
    ];
    
    expensivePatterns.forEach(({pattern, desc}) => {
        const matches = currentSourceCode.match(pattern);
        if (matches && matches.length > 0) {
            issues.push(`${desc}: ${matches.length} occurrence(s)`);
        }
    });
    
    // Check for missing lazy loading
    const hasLazyVar = /@LazyKVar|lazy\s+var/.test(currentSourceCode);
    const heavyInitialization = currentSourceCode.includes('UIImage(named:') || 
                                currentSourceCode.includes('Data(contentsOf:') ||
                                currentSourceCode.includes('URLSession.shared');
    
    if (heavyInitialization && !hasLazyVar) {
        issues.push("Heavy initialization without lazy loading");
    }
    
    // Report violations
    issues.forEach(issue => {
        ruleEngine.addViolation({
            ruleName: "CPU Usage Patterns",
            severity: "medium",
            actualValue: issue,
            expectedValue: "Optimize expensive operations and use lazy loading where appropriate",
            automationConfidence: 0.65,
            recommendedAction: "Consider optimizing algorithms, caching results, or using lazy loading for expensive operations",
            targetName: fileName
        });
    });
}
