import XCTest
import SmithValidationCore
import SmithValidation
import MaxwellsTCARules

final class RulePackTests: XCTestCase {
    func testMaxwellRulesAgainstProject() throws {
        guard let projectRoot = RuleTestEmitter.projectRoot else {
            XCTFail("SMITH_RULES_PROJECT_ROOT not set")
            return
        }

        // Discover Swift files with include/exclude globs passed by smith-validation
        let includeGlobs = (ProcessInfo.processInfo.environment[RuleTestEmitter.includeGlobsEnv] ?? "**/*.swift").components(separatedBy: ",")
        let excludeGlobs = (ProcessInfo.processInfo.environment[RuleTestEmitter.excludeGlobsEnv] ?? "").components(separatedBy: ",").filter { !$0.isEmpty }

        let files = try FileUtils.findSwiftFiles(in: projectRoot, includeGlobs: includeGlobs, excludeGlobs: excludeGlobs)
        let filePaths = files.map { $0.path }

        let rules = registerMaxwellsRules()
        let engine = ValidationEngine()
        let violations = try engine.validate(rules: rules, filePaths: filePaths)

        for v in violations.violations {
            let finding = RuleTestEmitter.Finding(
                rule: v.rule,
                severity: v.severity.rawValue,
                file: v.file,
                line: v.line,
                message: v.message,
                recommendation: v.recommendation
            )
            RuleTestEmitter.emit(finding)
        }
    }
}
