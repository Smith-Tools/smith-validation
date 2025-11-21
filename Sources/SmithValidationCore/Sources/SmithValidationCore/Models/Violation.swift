// Models/Violation.swift
// Represents architectural rule violations

import Foundation

/// Represents an architectural rule violation detected by smith-validation
public struct ArchitecturalViolation: Sendable, CustomStringConvertible {
    public let severity: Severity
    public let rule: String
    public let file: String
    public let line: Int
    public let message: String
    public let recommendation: String?
    public let metadata: [String: String]

    public enum Severity: String, CaseIterable, Sendable {
        case critical = "🔴 CRITICAL"
        case high = "🔴 HIGH"
        case medium = "🟠 MEDIUM"
        case low = "🟡 LOW"
        case info = "🔵 INFO"

        public var priority: Int {
            switch self {
            case .critical: return 5
            case .high: return 4
            case .medium: return 3
            case .low: return 2
            case .info: return 1
            }
        }

        public var emoji: String {
            switch self {
            case .critical: return "🚨"
            case .high: return "🔴"
            case .medium: return "🟠"
            case .low: return "🟡"
            case .info: return "🔵"
            }
        }
    }

    public init(
        severity: Severity,
        rule: String,
        file: String,
        line: Int,
        message: String,
        recommendation: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.severity = severity
        self.rule = rule
        self.file = file
        self.line = line
        self.message = message
        self.recommendation = recommendation
        self.metadata = metadata
    }

    /// Convenience initializer with SourceFileContext
    public init(
        severity: Severity,
        rule: String,
        context: SourceFileContext,
        line: Int,
        message: String,
        recommendation: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.severity = severity
        self.rule = rule
        self.file = context.relativePath.isEmpty ? context.filename : context.relativePath
        self.line = line
        self.message = message
        self.recommendation = recommendation
        self.metadata = metadata
    }

    public var description: String {
        var result = [
            "\(severity.rawValue): \(file)",
            "Rule: \(rule)",
            "Line: \(line)",
            "Message: \(message)"
        ]

        if let recommendation = recommendation {
            result.append("Recommendation: \(recommendation)")
        }

        if !metadata.isEmpty {
            result.append("Details: \(metadata)")
        }

        return result.joined(separator: "\n")
    }

    /// Create a high-priority violation
    public static func high(
        rule: String,
        file: String,
        line: Int,
        message: String,
        recommendation: String? = nil
    ) -> ArchitecturalViolation {
        return ArchitecturalViolation(
            severity: .high,
            rule: rule,
            file: file,
            line: line,
            message: message,
            recommendation: recommendation
        )
    }

    /// Create a critical violation
    public static func critical(
        rule: String,
        file: String,
        line: Int,
        message: String,
        recommendation: String? = nil
    ) -> ArchitecturalViolation {
        return ArchitecturalViolation(
            severity: .critical,
            rule: rule,
            file: file,
            line: line,
            message: message,
            recommendation: recommendation
        )
    }

    /// Create a medium priority violation
    public static func medium(
        rule: String,
        file: String,
        line: Int,
        message: String,
        recommendation: String? = nil
    ) -> ArchitecturalViolation {
        return ArchitecturalViolation(
            severity: .medium,
            rule: rule,
            file: file,
            line: line,
            message: message,
            recommendation: recommendation
        )
    }

    /// Create a low priority violation
    public static func low(
        rule: String,
        file: String,
        line: Int,
        message: String,
        recommendation: String? = nil
    ) -> ArchitecturalViolation {
        return ArchitecturalViolation(
            severity: .low,
            rule: rule,
            file: file,
            line: line,
            message: message,
            recommendation: recommendation
        )
    }
}

/// Collection of violations with convenient helper methods
public struct ViolationCollection: Sendable, CustomStringConvertible {
    public let violations: [ArchitecturalViolation]

    public init(violations: [ArchitecturalViolation]) {
        self.violations = violations.sorted { $0.severity.priority > $1.severity.priority }
    }

    public var description: String {
        return violations.isEmpty ? "No violations found" : violations.map(\.description).joined(separator: "\n\n")
    }

    public var count: Int {
        return violations.count
    }

    public var criticalCount: Int {
        return violations.filter { $0.severity == .critical }.count
    }

    public var highCount: Int {
        return violations.filter { $0.severity == .high }.count
    }

    public var mediumCount: Int {
        return violations.filter { $0.severity == .medium }.count
    }

    public var lowCount: Int {
        return violations.filter { $0.severity == .low }.count
    }

    public var hasCriticalViolations: Bool {
        return !violations.filter { $0.severity == .critical }.isEmpty
    }

    public var hasHighViolations: Bool {
        return !violations.filter { $0.severity == .high }.isEmpty
    }

    /// Filter violations by severity
    public func filtered(by severity: ArchitecturalViolation.Severity) -> ViolationCollection {
        return ViolationCollection(violations: violations.filter { $0.severity == severity })
    }

    /// Filter violations by rule pattern
    public func filtered(by rulePattern: String) -> ViolationCollection {
        return ViolationCollection(violations: violations.filter { $0.rule.contains(rulePattern) })
    }

    /// Get violations by severity (for reporting)
    public func bySeverity() -> [ArchitecturalViolation.Severity: [ArchitecturalViolation]] {
        var grouped: [ArchitecturalViolation.Severity: [ArchitecturalViolation]] = [:]

        for severity in ArchitecturalViolation.Severity.allCases {
            grouped[severity] = violations.filter { $0.severity == severity }
        }

        return grouped
    }
}