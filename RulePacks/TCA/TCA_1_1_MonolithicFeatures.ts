/// TCA Rule 1.1: Monolithic Features Validator
///
/// Detects State structs with >15 properties and Action enums with >40 cases
/// Rationale: Large State/Action indicate monolithic features that should be split

interface RuleResult {
  ruleName: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  actualValue: string;
  expectedValue: string;
  automationConfidence: number;
  recommendedAction: string;
  targetName: string;
}

interface TCARuleContext {
  astBridge: {
    getClasses: () => Array<{
      name: string;
      kind: string;
    }>;
    currentSourceCode: string;
  };
  ruleEngine: {
    addViolation: (violation: RuleResult) => void;
  };
}

// Rule configuration
const CONFIG = {
  maxStateProperties: 15,
  maxActionCases: 40,
  maxLines: 40
};

export function validate(context: TCARuleContext): void {
  const { astBridge, ruleEngine } = context;
  
  const classes = astBridge.getClasses().filter(cls => 
    cls.kind.includes('struct')
  );

  classes.forEach(cls => {
    // Check if this could be a TCA State struct
    if (cls.name === 'State' || cls.name.endsWith('State')) {
      const propertyCount = countProperties(cls.name, astBridge.currentSourceCode);

      if (propertyCount > CONFIG.maxStateProperties) {
        ruleEngine.addViolation({
          ruleName: 'TCA 1.1: Monolithic Features',
          severity: 'high',
          actualValue: `State struct has ${propertyCount} properties`,
          expectedValue: `State structs should have ≤${CONFIG.maxStateProperties} properties`,
          automationConfidence: 0.85,
          recommendedAction: 'Consider extracting separate features. Large State structs indicate multiple features crammed into one reducer.',
          targetName: cls.name
        });
      }
    }

    // Check if this could be a TCA Action enum
    if (cls.name === 'Action' || cls.name.endsWith('Action')) {
      const caseCount = countActionCases(cls.name, astBridge.currentSourceCode);

      if (caseCount > CONFIG.maxActionCases) {
        ruleEngine.addViolation({
          ruleName: 'TCA 1.1: Monolithic Features',
          severity: 'high',
          actualValue: `Action enum has ${caseCount} cases`,
          expectedValue: `Action enums should have ≤${CONFIG.maxActionCases} cases`,
          automationConfidence: 0.85,
          recommendedAction: 'Consider splitting into multiple features. Large Action enums suggest too much responsibility.',
          targetName: cls.name
        });
      }
    }
  });
}

// Helper function to count properties in a struct
function countProperties(structName: string, sourceCode: string): number {
  const structPattern = new RegExp(`struct\\s+${structName}\\s*\\{([^}]*)\\}`, 's');
  const structMatch = sourceCode.match(structPattern);
  
  if (!structMatch) return 0;
  
  const structBody = structMatch[1];
  const propertyPattern = /let\s+\w+:\s+[A-Z]/g;
  const matches = structBody.match(propertyPattern) || [];
  
  return matches.length;
}

// Helper function to count cases in an enum
function countActionCases(enumName: string, sourceCode: string): number {
  const enumPattern = new RegExp(`enum\\s+${enumName}\\s*\\{([^}]*)\\}`, 's');
  const enumMatch = sourceCode.match(enumPattern);
  
  if (!enumMatch) return 0;
  
  const enumBody = enumMatch[1];
  const casePattern = /case\s+\w+/g;
  const matches = enumBody.match(casePattern) || [];
  
  return matches.length;
}
