/// Memory Management Patterns Validator
///
/// Detects potential memory leaks and retain cycles in closures
/// Rationale: Retain cycles can cause memory leaks in long-running apps

interface RuleResult {
  ruleName: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  actualValue: string;
  expectedValue: string;
  automationConfidence: number;
  recommendedAction: string;
  targetName: string;
}

interface PerformanceRuleContext {
  currentSourceCode: string;
  ruleEngine: {
    addViolation: (violation: RuleResult) => void;
  };
}

export function validate(context: PerformanceRuleContext): void {
  const { currentSourceCode, ruleEngine } = context;
  
  // Look for closures that capture self without weak/unowned
  const closurePatterns = [
    // Pattern: { ... self. ... }
    /\{[^}]*self\.[^}]*\}/g,
    // Pattern: [weak/unowned self] check for missing
    /\[[^]]*self[^]\]/g
  ];

  // Find closure blocks
  const closurePattern = /\{[^{}]*\{[^{}]*self[^{}]*\}[^{}]*\}/g;
  const closures = currentSourceCode.match(closurePattern) || [];

  closures.forEach(closure => {
    // Check if closure uses self but doesn't use [weak self] or [unowned self]
    const hasSelf = closure.includes('self.');
    const hasWeakSelf = closure.includes('[weak self]') || closure.includes('[unowned self]');
    
    if (hasSelf && !hasWeakSelf) {
      // Additional check: see if there's a missing weak/unowned pattern that should be there
      const missingPattern = /self\./;
      if (missingPattern.test(closure)) {
        ruleEngine.addViolation({
          ruleName: 'Memory Management Patterns',
          severity: 'medium',
          actualValue: 'Closure potentially creating retain cycle',
          expectedValue: 'Use [weak self] or [unowned self] in closures',
          automationConfidence: 0.75,
          recommendedAction: 'Consider using weak or unowned references to prevent retain cycles',
          targetName: 'memory_management'
        });
      }
    }
  });
}
