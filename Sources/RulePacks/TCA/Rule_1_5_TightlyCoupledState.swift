// Frameworks/TCA/Rule_1_5_TightlyCoupledState.swift
// TCA Rule 1.5: Tightly Coupled State validation

import Foundation
import SmithValidationCore
import SwiftSyntax

/// TCA Rule 1.5: Tightly Coupled State Validator
///
/// Detects TCA state coupling issues that indicate poor feature separation:
/// - 5+ child features embedded in one State struct
/// - State structures that combine unrelated domains
/// - Nested feature states that should be separate reducers
/// - State properties that suggest feature responsibility overlap
///
/// Rationale:
/// - Tightly coupled state makes features difficult to test independently
/// - Large State structs indicate multiple responsibilities in one reducer
/// - Child features should be separate reducers with proper parent-child communication
/// - Well-separated State improves modularity and reusability
public struct TCARule_1_5_TightlyCoupledState: ValidatableRule {

    public struct Configuration {
        public let severity: ArchitecturalViolation.Severity
        public let maxChildFeatures: Int
        public let childFeaturePatterns: Set<String>
        public let detectNestedFeatures: Bool
        public let detectDomainMixing: Bool

        public init(
            severity: ArchitecturalViolation.Severity = .medium,
            maxChildFeatures: Int = 5,
            childFeaturePatterns: Set<String> = [
                "Feature", "Feature.State", "State", "Model", "Data"
            ],
            detectNestedFeatures: Bool = true,
            detectDomainMixing: Bool = true
        ) {
            self.severity = severity
            self.maxChildFeatures = maxChildFeatures
            self.childFeaturePatterns = childFeaturePatterns
            self.detectNestedFeatures = detectNestedFeatures
            self.detectDomainMixing = detectDomainMixing
        }
    }

    private let configuration: Configuration

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    /// Validate a single Swift file context for tightly coupled state violations
    /// - Parameter context: The source file context with path information
    /// - Returns: Collection of architectural violations
    public func validate(context: SourceFileContext) -> ViolationCollection {
        var violations: [ArchitecturalViolation] = []

        // Find all TCA reducers in the file
        let reducers = context.syntax.findTCAReducers()

        for reducer in reducers {
            violations.append(contentsOf: validateReducer(reducer, in: context))
        }

        return ViolationCollection(violations: violations)
    }

    /// Validate a single Swift file for tightly coupled state violations
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    public func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        // Create a dummy context for backward compatibility
        let context = SourceFileContext(path: "<unknown>", url: URL(fileURLWithPath: "/unknown"), syntax: sourceFile)
        return validate(context: context)
    }

    /// Validate multiple files for tightly coupled state violations
    /// - Parameter sourceFiles: Array of Swift files to validate
    /// - Returns: Collection of architectural violations
    public func validate(sourceFiles: [SourceFileSyntax]) -> ViolationCollection {
        var allViolations: [ArchitecturalViolation] = []

        for sourceFile in sourceFiles {
            let violations = validate(sourceFile: sourceFile)
            allViolations.append(contentsOf: violations.violations)
        }

        return ViolationCollection(violations: allViolations)
    }

    // MARK: - Private Validation Methods

    private func validateReducer(_ reducer: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        // Analyze the State struct for coupling issues
        if let stateStruct = reducer.findNestedStruct(named: "State") {
            violations.append(contentsOf: analyzeStateStruct(stateStruct, reducer: reducer, in: context))
        }

        return violations
    }

    private func analyzeStateStruct(_ stateStruct: StructInfo, reducer: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        // 1. Detect child feature patterns
        if configuration.detectNestedFeatures {
            let childFeatures = findChildFeatures(stateStruct.syntax)
            if childFeatures.count >= configuration.maxChildFeatures {
                let violation = ArchitecturalViolation(
                    severity: configuration.severity,
                    rule: "TCA 1.5: Tightly Coupled State (Child Features)",
                    context: context,
                    line: stateStruct.lineNumber,
                    message: "State struct contains \(childFeatures.count) child feature properties (threshold: \(configuration.maxChildFeatures))",
                    recommendation: "Extract child features into separate reducers with proper parent-child communication using @Presents or @Shared.",
                    metadata: [
                        "childFeatureCount": "\(childFeatures.count)",
                        "threshold": "\(configuration.maxChildFeatures)",
                        "childFeatures": childFeatures.joined(separator: ", "),
                        "reducerName": reducer.name,
                        "impact": "Tightly coupled features reduce modularity and testability"
                    ]
                )
                violations.append(violation)
            }
        }

        // 2. Detect domain mixing
        if configuration.detectDomainMixing {
            let domainMixing = detectDomainMixing(stateStruct.syntax)
            if domainMixing.isMixed {
                let violation = ArchitecturalViolation(
                    severity: .low, // Lower severity for domain mixing
                    rule: "TCA 1.5: Tightly Coupled State (Domain Mixing)",
                    context: context,
                    line: stateStruct.lineNumber,
                    message: "State struct mixes multiple unrelated domains: \(domainMixing.domains.joined(separator: ", "))",
                    recommendation: "Consider splitting the reducer into domain-specific features or using @Shared for cross-cutting state.",
                    metadata: [
                        "mixedDomains": domainMixing.domains.joined(separator: ", "),
                        "domainCount": "\(domainMixing.domains.count)",
                        "reducerName": reducer.name,
                        "impact": "Domain mixing violates single responsibility principle"
                    ]
                )
                violations.append(violation)
            }
        }

        return violations
    }

    private func findChildFeatures(_ stateStruct: StructDeclSyntax) -> [String] {
        var childFeatures: [String] = []

        for member in stateStruct.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }

            for binding in varDecl.bindings {
                let propertyName = binding.pattern.description.trimmingCharacters(in: .whitespacesAndNewlines)
                let propertyType = binding.typeAnnotation?.type.description.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                // Check if property type indicates a child feature
                if isChildFeatureType(propertyType, propertyName: propertyName) {
                    childFeatures.append(propertyName)
                }
            }
        }

        return childFeatures
    }

    private func isChildFeatureType(_ type: String, propertyName: String) -> Bool {
        let lowercasedType = type.lowercased()
        let lowercasedName = propertyName.lowercased()

        // Check for Feature-like type patterns
        for pattern in configuration.childFeaturePatterns {
            if lowercasedType.contains(pattern.lowercased()) {
                return true
            }
        }

        // Check for common child feature indicators
        if lowercasedType.contains("feature.state") ||
           lowercasedType.contains("feature") ||
           lowercasedType.contains("state") && lowercasedName.contains("feature") ||
           lowercasedType.contains("model") && lowercasedName.contains("feature") ||
           lowercasedType.contains("data") && lowercasedName.contains("feature") {
            return true
        }

        // Check for @Presents properties (definitely child features)
        if lowercasedType.contains("@presents") ||
           lowercasedType.contains("presented") ||
           lowercasedType.contains("presentationstate") {
            return true
        }

        return false
    }

    private func detectDomainMixing(_ stateStruct: StructDeclSyntax) -> DomainMixingAnalysis {
        var domains: Set<String> = []

        for member in stateStruct.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }

            for binding in varDecl.bindings {
                let propertyName = binding.pattern.description.trimmingCharacters(in: .whitespacesAndNewlines)
                let propertyType = binding.typeAnnotation?.type.description.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                let domain = inferDomain(from: propertyName, type: propertyType)
                if !domain.isEmpty {
                    domains.insert(domain)
                }
            }
        }

        return DomainMixingAnalysis(
            domains: Array(domains).sorted(),
            isMixed: domains.count > 2 // More than 2 domains suggests mixing
        )
    }

    private func inferDomain(from propertyName: String, type: String) -> String {
        let lowercasedName = propertyName.lowercased()
        let lowercasedType = type.lowercased()

        // Domain inference based on property names and types
        if lowercasedName.contains("user") || lowercasedType.contains("user") {
            return "User"
        }
        if lowercasedName.contains("article") || lowercasedType.contains("article") {
            return "Article"
        }
        if lowercasedName.contains("search") || lowercasedType.contains("search") {
            return "Search"
        }
        if lowercasedName.contains("filter") || lowercasedType.contains("filter") {
            return "Filter"
        }
        if lowercasedName.contains("folder") || lowercasedType.contains("folder") {
            return "Folder"
        }
        if lowercasedName.contains("tag") || lowercasedType.contains("tag") {
            return "Tag"
        }
        if lowercasedName.contains("share") || lowercasedType.contains("share") {
            return "Share"
        }
        if lowercasedName.contains("import") || lowercasedType.contains("import") {
            return "Import"
        }
        if lowercasedName.contains("export") || lowercasedType.contains("export") {
            return "Export"
        }
        if lowercasedName.contains("insight") || lowercasedType.contains("insight") {
            return "Insight"
        }
        if lowercasedName.contains("analytic") || lowercasedType.contains("analytic") {
            return "Analytics"
        }
        if lowercasedName.contains("setting") || lowercasedType.contains("setting") {
            return "Settings"
        }
        if lowercasedName.contains("cache") || lowercasedType.contains("cache") {
            return "Cache"
        }
        if lowercasedName.contains("network") || lowercasedType.contains("network") {
            return "Network"
        }
        if lowercasedName.contains("sync") || lowercasedType.contains("sync") {
            return "Sync"
        }
        if lowercasedName.contains("auth") || lowercasedType.contains("auth") {
            return "Authentication"
        }
        if lowercasedName.contains("theme") || lowercasedType.contains("theme") {
            return "Theme"
        }
        if lowercasedName.contains("ui") || lowercasedType.contains("view") {
            return "UI"
        }
        if lowercasedName.contains("loading") || lowercasedType.contains("loading") {
            return "Loading"
        }
        if lowercasedName.contains("error") || lowercasedType.contains("error") {
            return "Error"
        }

        return ""
    }
}

// MARK: - Helper Structures

private struct DomainMixingAnalysis {
    let domains: [String]
    let isMixed: Bool
}

// MARK: - Convenience Methods

public extension TCARule_1_5_TightlyCoupledState {

    /// Quick validation using default configuration
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        let validator = TCARule_1_5_TightlyCoupledState()
        return validator.validate(sourceFile: sourceFile)
    }

    /// Quick validation using default configuration for multiple files
    /// - Parameter sourceFiles: Array of Swift files to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFiles: [SourceFileSyntax]) -> ViolationCollection {
        let validator = TCARule_1_5_TightlyCoupledState()
        return validator.validate(sourceFiles: sourceFiles)
    }

    /// Validate a project directory
    /// - Parameter directoryURL: Directory URL containing Swift files
    /// - Returns: Collection of architectural violations
    /// - Throws: File system errors
    static func validate(directory: URL) throws -> ViolationCollection {
        let swiftFiles = try FileUtils.findSwiftFiles(in: directory)
        let parsedFiles = try swiftFiles.compactMap { try? SourceFileSyntax.parse(from: $0) }
        return validate(sourceFiles: parsedFiles)
    }
}