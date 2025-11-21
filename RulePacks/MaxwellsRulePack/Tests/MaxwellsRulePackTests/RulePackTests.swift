import Foundation
import MaxwellsTCARules
import SmithValidation
import SmithValidationCore
import Testing

@Suite
struct RulePackTests {
    @Test
    func maxwellRulesAgainstProject() throws {
        guard let projectRoot = RuleTestEmitter.projectRoot else {
            // When invoked via plain `swift test`, the CLI env isn't present; treat as a no-op.
            return
        }

        let includeGlobs = (ProcessInfo.processInfo.environment[RuleTestEmitter.includeGlobsEnv] ?? "**/*.swift")
            .components(separatedBy: ",")
        let excludeGlobs = (ProcessInfo.processInfo.environment[RuleTestEmitter.excludeGlobsEnv] ?? "")
            .components(separatedBy: ",")
            .filter { !$0.isEmpty }

        let files = try FileUtils.findSwiftFiles(
            in: projectRoot,
            includeGlobs: includeGlobs,
            excludeGlobs: excludeGlobs
        )
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
