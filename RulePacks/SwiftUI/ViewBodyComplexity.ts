/// SwiftUI Rule: View Body Complexity Validator
/// Detects overly complex SwiftUI view bodies

export function validate(context) {
    const astBridge = context.astBridge;
    const ruleEngine = context.ruleEngine;
    const currentSourceCode = astBridge.currentSourceCode;
    const fileName = astBridge.currentFile.fileName;
    
    // Only analyze SwiftUI View files
    if (!currentSourceCode.includes('var body: some View')) {
        return;
    }
    
    // Count complexity indicators
    const bodyMatch = currentSourceCode.match(/var body:\s*some\s*View\s*\{([\s\S]*?)\}/);
    if (!bodyMatch) return;
    
    const bodyContent = bodyMatch[1];
    
    // Count complexity metrics
    const viewCount = (bodyContent.match(/\b(View|Text|Button|Image|HStack|VStack|ZStack|Spacer|Rectangle|Circle|ScrollView|List|NavigationView|TabView)\b/g) || []).length;
    const conditionalCount = (bodyContent.match(/\b(if|switch|guard)\b/g) || []).length;
    const closureCount = (bodyContent.match(/\{[^}]*=>/g) || []).length + (bodyContent.match(/\.\s*\w+\s*\{/g) || []).length;
    
    // Calculate complexity score
    const complexityScore = viewCount + (conditionalCount * 2) + (closureCount * 1.5);
    
    if (complexityScore > 15) {
        ruleEngine.addViolation({
            ruleName: "View Body Complexity",
            severity: "medium",
            actualValue: `Complexity score: ${complexityScore} (${viewCount} views, ${conditionalCount} conditionals, ${closureCount} closures)`,
            expectedValue: "Complexity score should be <= 15. Extract complex parts into separate views",
            automationConfidence: 0.8,
            recommendedAction: "Break down complex view body into smaller, reusable view components",
            targetName: fileName
        });
    }
}
