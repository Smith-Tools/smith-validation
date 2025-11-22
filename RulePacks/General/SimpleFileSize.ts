/// Simple File Size Validator
/// Detects files that exceed reasonable size limits

export function validate(context) {
    const currentFile = context.currentFile;
    const ruleEngine = context.ruleEngine;
    const currentLines = currentFile.lines;
    
    if (currentLines > 150) {
        ruleEngine.addViolation({
            ruleName: "File Size Management",
            severity: "high",
            actualValue: currentLines + " lines in file",
            expectedValue: "Files should have 150 lines or less",
            automationConfidence: 0.85,
            recommendedAction: "Extract smaller components from large file to improve maintainability",
            targetName: currentFile.fileName
        });
    }
}
