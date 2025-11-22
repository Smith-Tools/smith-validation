/// TCA Rule 1.2: Closure Injection Validator
/// Detects closure injection patterns that may cause retain cycles

export function validate(context) {
    const astBridge = context.astBridge;
    const ruleEngine = context.ruleEngine;
    const currentSourceCode = astBridge.currentSourceCode;
    
    // Check for common closure injection patterns
    const closurePatterns = [
        /\.sink\s*\(/,
        /onReceive\s*\([^)]*\)\s*\{/,
        /onChange\s*\([^)]*\)\s*\{/,
        /onAppear\s*\([^)]*\)\s*\{/
    ];
    
    let closureCount = 0;
    closurePatterns.forEach(pattern => {
        const matches = currentSourceCode.match(pattern);
        if (matches) {
            closureCount += matches.length;
        }
    });
    
    // Check for weak self usage
    const weakSelfPattern = /\[weak\s+self\]/;
    const unownedSelfPattern = /\[unowned\s+self\]/;
    const hasWeakSelf = weakSelfPattern.test(currentSourceCode) || unownedSelfPattern.test(currentSourceCode);
    
    // If closures found but no weak/unowned self, flag potential retain cycle
    if (closureCount > 0 && !hasWeakSelf) {
        ruleEngine.addViolation({
            ruleName: "TCA 1.2: Closure Injection",
            severity: "medium",
            actualValue: `Found ${closureCount} closures without weak/unowned self`,
            expectedValue: "Use [weak self] or [unowned self] in closures to prevent retain cycles",
            automationConfidence: 0.75,
            recommendedAction: "Add [weak self] or [unowned self] capture lists to closures to prevent retain cycles in TCA reducers",
            targetName: "Closure injection patterns"
        });
    }
}
