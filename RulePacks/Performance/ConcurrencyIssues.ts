/// Performance Rule: Concurrency Issues Validator
/// Detects potential concurrency problems

export function validate(context) {
    const astBridge = context.astBridge;
    const ruleEngine = context.ruleEngine;
    const currentSourceCode = astBridge.currentSourceCode;
    const fileName = astBridge.currentFile.fileName;
    
    // Look for potentially unsafe concurrency patterns
    const issues = [];
    
    // Check for non-atomic operations on shared state
    if (currentSourceCode.includes('@Published') && 
        currentSourceCode.includes('DispatchQueue.main.async') &&
        !currentSourceCode.includes('actor')) {
        issues.push('Non-atomic @Published property access across threads');
    }
    
    // Check for missing synchronization when accessing shared resources
    const sharedVarPattern = /var\s+\w+.*=/g;
    const syncPatterns = /DispatchQueue|NSLock|NSRecursiveLock|actor|@MainActor/;
    
    const sharedVars = currentSourceCode.match(sharedVarPattern) || [];
    const hasSync = syncPatterns.test(currentSourceCode);
    
    if (sharedVars.length > 2 && !hasSync) {
        issues.push(`Found ${sharedVars.length} mutable variables without explicit synchronization`);
    }
    
    // Report violations
    issues.forEach(issue => {
        ruleEngine.addViolation({
            ruleName: "Concurrency Issues",
            severity: "high", 
            actualValue: issue,
            expectedValue: "Use proper synchronization mechanisms for concurrent access",
            automationConfidence: 0.7,
            recommendedAction: "Consider using actors, DispatchQueue, or locks to protect shared mutable state",
            targetName: fileName
        });
    });
}
