/// File Size Management Validator
///
/// Detects files that exceed reasonable size limits
/// Rationale: Large files are harder to maintain and should be split

interface RuleResult {
  ruleName: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  actualValue: string;
  expectedValue: string;
  automationConfidence: number;
  recommendedAction: string;
  targetName: string;
}

interface GeneralRuleContext {
  currentFile: {
    lines: number;
    fileName: string;
  };
  ruleEngine: {
    addViolation: (violation: RuleResult) => void;
  };
}

// Rule configuration
const CONFIG = {
  maxLines: 150,
  maxFunctions: 20,
  maxProperties: 10
};

export function validate(context: GeneralRuleContext): void {
  const { currentFile, ruleEngine } = context;
  
  const currentLines = currentFile.lines;
  
  if (currentLines > CONFIG.maxLines) {
    ruleEngine.addViolation({
      ruleName: 'File Size Management',
      severity: 'high',
      actualValue: `${currentLines} lines in file`,
      expectedValue: `Files should have ≤${CONFIG.maxLines} lines`,
      automationConfidence: 0.85,
      recommendedAction: 'Extract smaller components from large file to improve maintainability',
      targetName: currentFile.fileName
    });
  }
}
