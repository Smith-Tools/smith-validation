/// TCA Rule 2.1: Error Handling Validator
/// Detects proper error handling patterns in TCA reducers

export function validate(context) {
    const astBridge = context.astBridge;
    const ruleEngine = context.ruleEngine;
    const currentSourceCode = astBridge.currentSourceCode;
    
    // Look for TCA reducer patterns
    if (!currentSourceCode.includes('reduce') && !currentSourceCode.includes('Reducer')) {
        return;
    }
    
    // Check for Effect creation with error handling
    const effectPatterns = [
        /Effect\.run\s*\(/,
        /\.eraseToEffect\(\)/,
        /Effect\.none/
    ];
    
    const hasEffects = effectPatterns.some(pattern => pattern.test(currentSourceCode));
    const hasErrorHandling = currentSourceCode.includes('catch') || 
                            currentSourceCode.includes('try') ||
                            currentSourceCode.includes('Result');
    
    if (hasEffects && !hasErrorHandling) {
        ruleEngine.addViolation({
            ruleName: "TCA 2.1: Error Handling",
            severity: "medium",
            actualValue: "Found Effects without proper error handling",
            expectedValue: "Include proper error handling for Effects using Result types or catch blocks",
            automationConfidence: 0.7,
            recommendedAction: "Add proper error handling for asynchronous Effects using Result<_, Error> or try-catch blocks",
            targetName: "Error handling patterns"
        });
    }
}
