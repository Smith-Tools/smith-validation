import Foundation

/// Utilities for Swift Testing-based rule packs to emit findings in a format
/// that smith-validation can ingest when using `--rules-tests`.
public enum RuleTestEmitter {
    /// Environment key for the project root under validation.
    public static let projectRootEnv = "SMITH_RULES_PROJECT_ROOT"
    public static let includeGlobsEnv = "SMITH_RULES_INCLUDE"
    public static let excludeGlobsEnv = "SMITH_RULES_EXCLUDE"
    public static let marker = "SMITH_RULE_FINDING:"

    public struct Finding: Codable {
        public let rule: String
        public let severity: String   // critical|high|medium|low
        public let file: String
        public let line: Int
        public let message: String
        public let recommendation: String?

        public init(rule: String, severity: String, file: String, line: Int, message: String, recommendation: String? = nil) {
            self.rule = rule
            self.severity = severity
            self.file = file
            self.line = line
            self.message = message
            self.recommendation = recommendation
        }
    }

    /// Emit a finding as a JSON line prefixed with the marker the CLI looks for.
    public static func emit(_ finding: Finding) {
        guard let data = try? JSONEncoder().encode(finding),
              let json = String(data: data, encoding: .utf8) else { return }
        print("\(marker)\(json)")
    }

    /// Resolve the project root passed by the CLI.
    public static var projectRoot: URL? {
        guard let path = ProcessInfo.processInfo.environment[projectRootEnv] else { return nil }
        return URL(fileURLWithPath: path)
    }
}
