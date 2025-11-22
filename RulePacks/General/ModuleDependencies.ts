/// General Rule: Module Dependencies Validator
/// Detects problematic module dependency patterns

export function validate(context) {
    const astBridge = context.astBridge;
    const ruleEngine = context.ruleEngine;
    const currentSourceCode = astBridge.currentSourceCode;
    const fileName = astBridge.currentFile.fileName;
    
    // Count import statements
    const importMatches = currentSourceCode.match(/import\s+[A-Za-z0-9_.]+/g) || [];
    const importCount = importMatches.length;
    
    // Count framework imports
    const frameworkImports = importMatches.filter(imp => 
        imp.includes('Foundation') || 
        imp.includes('SwiftUI') || 
        imp.includes('Combine') ||
        imp.includes('CoreData') ||
        imp.includes('AVFoundation') ||
        imp.includes('CoreLocation')
    );
    
    // Check for tight coupling indicators
    const couplingIndicators = [
        /UIApplication\.shared/,
        /UserDefaults\.standard/,
        /NotificationCenter\.default/,
        /URLSession\.shared/
    ];
    
    let couplingCount = 0;
    couplingIndicators.forEach(pattern => {
        const matches = currentSourceCode.match(pattern);
        if (matches) couplingCount += matches.length;
    });
    
    // Flag too many imports
    if (importCount > 15) {
        ruleEngine.addViolation({
            ruleName: "Module Dependencies",
            severity: "low",
            actualValue: `Found ${importCount} imports (too many dependencies)`,
            expectedValue: "Keep imports <= 15 per file to maintain loose coupling",
            automationConfidence: 0.7,
            recommendedAction: "Consider breaking up this file or reducing dependencies through better architecture",
            targetName: fileName
        });
    }
    
    // Flag excessive framework coupling
    if (couplingCount > 5) {
        ruleEngine.addViolation({
            ruleName: "Module Dependencies", 
            severity: "medium",
            actualValue: `Found ${couplingCount} tightly coupled framework dependencies`,
            expectedValue: "Reduce tight coupling to shared singletons",
            automationConfidence: 0.8,
            recommendedAction: "Use dependency injection to reduce tight coupling to framework singletons",
            targetName: fileName
        });
    }
}
