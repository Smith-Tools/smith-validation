/// Simple TCA Validation
/// Basic checks for TCA architectural patterns

export function validate(context) {
    const astBridge = context.astBridge;
    const ruleEngine = context.ruleEngine;
    const classes = astBridge.getClasses();
    
    classes.forEach(cls => {
        if (cls.name.includes("State")) {
            // Simple check for very large state files
            const lines = context.currentFile.lines;
            if (lines > 200) {
                ruleEngine.addViolation({
                    ruleName: "TCA State Size",
                    severity: "medium",
                    actualValue: "State file with " + lines + " lines",
                    expectedValue: "State files should be smaller and more focused",
                    automationConfidence: 0.7,
                    recommendedAction: "Consider splitting large state into smaller focused features",
                    targetName: cls.name
                });
            }
        }
    });
}
