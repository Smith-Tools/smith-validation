// Frameworks/TCA/Rule_1_2_ProperDependencyInjection.swift
// TCA Rule 1.2: Proper Dependency Injection validation

import Foundation
import SmithValidationCore
import SwiftSyntax

/// TCA Rule 1.2: Proper Dependency Injection Validator
///
/// Detects real TCA anti-patterns that impact testability:
/// - Direct service creation bypassing dependency system
/// - Missing @Dependency declarations for used services
/// - Hardcoded dependencies that ignore dependency injection
///
/// Rationale:
/// - Direct instantiation prevents mocking in tests
/// - Missing @Dependency breaks TCA's dependency management
/// - Hardcoded values reduce testability and flexibility
public struct TCARule_1_2_ProperDependencyInjection: ValidatableRule {

    public struct Configuration {
        public let severity: ArchitecturalViolation.Severity
        public let detectDirectInstantiation: Bool
        public let detectHardcodedValues: Bool
        public let commonServiceNames: Set<String>

        public init(
            severity: ArchitecturalViolation.Severity = .high,
            detectDirectInstantiation: Bool = true,
            detectHardcodedValues: Bool = true,
            commonServiceNames: Set<String> = [
                "APIClient", "DatabaseClient", "NetworkClient", "HTTPClient",
                "UserDefaults", "FileManager", "URLSession", "CoreDataStack",
                "FirebaseClient", "AnalyticsClient", "CacheClient"
            ]
        ) {
            self.severity = severity
            self.detectDirectInstantiation = detectDirectInstantiation
            self.detectHardcodedValues = detectHardcodedValues
            self.commonServiceNames = commonServiceNames
        }
    }

    private let configuration: Configuration

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    /// Validate a single Swift file context for proper dependency injection violations
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

    /// Validate a single Swift file for proper dependency injection violations
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    public func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        // Create a dummy context for backward compatibility
        let context = SourceFileContext(path: "<unknown>", url: URL(fileURLWithPath: "/unknown"), syntax: sourceFile)
        return validate(context: context)
    }

    /// Validate multiple files for proper dependency injection violations
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

    /// Validate multiple source file contexts for proper dependency injection violations
    /// - Parameter contexts: Array of source file contexts with path information
    /// - Returns: Collection of architectural violations
    public func validate(contexts: [SourceFileContext]) -> ViolationCollection {
        var allViolations: [ArchitecturalViolation] = []

        for context in contexts {
            let violations = validate(context: context)
            allViolations.append(contentsOf: violations.violations)
        }

        return ViolationCollection(violations: allViolations)
    }

    // MARK: - Private Validation Methods

    private func validateReducer(_ reducer: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        // 1. Detect direct service instantiation
        if configuration.detectDirectInstantiation {
            violations.append(contentsOf: detectDirectInstantiation(reducer, in: context))
        }

        // 2. Detect hardcoded values that should use dependencies
        if configuration.detectHardcodedValues {
            violations.append(contentsOf: detectHardcodedDependencies(reducer, in: context))
        }

        // 3. Detect services used without @Dependency declarations
        violations.append(contentsOf: detectMissingDependencies(reducer, in: context))

        return violations
    }

    private func detectDirectInstantiation(_ reducer: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        let analyzer = ServiceInstantiationAnalyzer()
        analyzer.analyze(reducer.syntax)

        for instantiation in analyzer.foundInstantiations {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "TCA 1.2: Direct Service Instantiation",
                context: context,
                line: instantiation.lineNumber,
                message: "Direct instantiation of '\(instantiation.serviceName)' bypasses TCA dependency system",
                recommendation: "Replace direct instantiation with @Dependency(\\.\\(instantiation.serviceName.lowercased())Client) var \\(instantiation.serviceName.lowercased())Client",
                metadata: [
                    "serviceName": instantiation.serviceName,
                    "instantiationType": instantiation.type,
                    "reducerName": reducer.name,
                    "impact": "Prevents mocking in tests"
                ]
            )
            violations.append(violation)
        }

        return violations
    }

    private func detectHardcodedDependencies(_ reducer: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        let analyzer = HardcodedValueAnalyzer()
        analyzer.analyze(reducer.syntax)

        for hardcoded in analyzer.foundHardcodedValues {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "TCA 1.2: Hardcoded Dependency",
                context: context,
                line: hardcoded.lineNumber,
                message: "Hardcoded '\(hardcoded.valueType)' bypasses TCA dependency system",
                recommendation: "Use @Dependency(\\.\\(hardcoded.valueType.lowercased())) var \\(hardcoded.valueType.lowercased()) instead of direct creation",
                metadata: [
                    "valueType": hardcoded.valueType,
                    "hardcodedValue": hardcoded.value,
                    "reducerName": reducer.name,
                    "impact": "Reduces testability and flexibility"
                ]
            )
            violations.append(violation)
        }

        return violations
    }

    private func detectMissingDependencies(_ reducer: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        // Get declared @Dependency properties
        let declaredDependencies = getDeclaredDependencies(reducer.syntax)

        // Get used services in the reducer body
        let usedServices = getUsedServices(reducer.syntax)

        // Find services used but not declared
        let undeclaredServices = usedServices.subtracting(declaredDependencies)

        for service in undeclaredServices {
            let violation = ArchitecturalViolation(
                severity: .medium, // Lower severity as this might be intentional
                rule: "TCA 1.2: Missing Dependency Declaration",
                context: context,
                line: 1, // Would be actual line number in real implementation
                message: "Service '\(service)' is used but not declared with @Dependency",
                recommendation: "Add @Dependency(\\.\\(service.lowercased())) var \\(service.lowercased()) to the reducer",
                metadata: [
                    "serviceName": service,
                    "reducerName": reducer.name,
                    "impact": "Inconsistent dependency management"
                ]
            )
            violations.append(violation)
        }

        return violations
    }

    private func getDeclaredDependencies(_ syntax: StructDeclSyntax) -> Set<String> {
        var dependencies: Set<String> = []

        // Look for @Dependency property declarations
        for member in syntax.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                for attribute in varDecl.attributes {
                    if let attrSyntax = attribute.as(AttributeSyntax.self),
                       attrSyntax.attributeName.description.trimmingCharacters(in: .whitespacesAndNewlines) == "Dependency" {
                        if let binding = varDecl.bindings.first {
                            let name = binding.pattern.description.trimmingCharacters(in: .whitespacesAndNewlines)
                            dependencies.insert(name)
                        }
                    }
                }
            }
        }

        return dependencies
    }

    private func getUsedServices(_ syntax: StructDeclSyntax) -> Set<String> {
        var services: Set<String> = []

        let analyzer = ServiceUsageAnalyzer()
        analyzer.analyze(syntax)
        services = analyzer.usedServices

        return services
    }
}

// MARK: - Convenience Methods

public extension TCARule_1_2_ProperDependencyInjection {

    /// Quick validation using default configuration
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        let validator = TCARule_1_2_ProperDependencyInjection()
        return validator.validate(sourceFile: sourceFile)
    }

    /// Quick validation using default configuration for multiple files
    /// - Parameter sourceFiles: Array of Swift files to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFiles: [SourceFileSyntax]) -> ViolationCollection {
        let validator = TCARule_1_2_ProperDependencyInjection()
        return validator.validate(sourceFiles: sourceFiles)
    }

    /// Validate multiple source file contexts
    /// - Parameter contexts: Array of source file contexts with path information
    /// - Returns: Collection of architectural violations
    static func validate(contexts: [SourceFileContext]) -> ViolationCollection {
        let validator = TCARule_1_2_ProperDependencyInjection()
        return validator.validate(contexts: contexts)
    }

    /// Validate a project directory
    /// - Parameter directoryURL: Directory URL containing Swift files
    /// - Returns: Collection of architectural violations
    /// - Throws: File system errors
    static func validate(directory: URL) throws -> ViolationCollection {
        let swiftFiles = try findSwiftFiles(in: directory)
        let parsedFiles = try swiftFiles.compactMap { try? SourceFileSyntax.parse(from: $0) }
        return validate(sourceFiles: parsedFiles)
    }

    /// Find all Swift files in a directory recursively
    /// - Parameter directory: Directory URL to search
    /// - Returns: Array of Swift file URLs
    /// - Throws: File system errors
    private static func findSwiftFiles(in directory: URL) throws -> [URL] {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: directory.path) else {
            throw ValidationError.directoryNotFound(directory)
        }

        var swiftFiles: [URL] = []

        let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .nameKey]
        let directoryEnumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        )

        for case let fileURL as URL in directoryEnumerator! {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys)) else {
                continue
            }

            if resourceValues.isDirectory == true {
                // Recursively search subdirectories
                swiftFiles.append(contentsOf: try findSwiftFiles(in: fileURL))
            } else if fileURL.pathExtension == "swift" {
                swiftFiles.append(fileURL)
            }
        }

        return swiftFiles
    }
}

// MARK: - Analysis Helper Classes

/// Analyzes Swift code for direct service instantiation patterns
private class ServiceInstantiationAnalyzer {
    struct ServiceInstantiation {
        let serviceName: String
        let type: String
        let lineNumber: Int
    }

    var foundInstantiations: [ServiceInstantiation] = []

    func analyze(_ syntax: StructDeclSyntax) {
        let visitor = ServiceInstantiationVisitor(viewMode: .sourceAccurate)
        visitor.walk(syntax)
        foundInstantiations = visitor.instantiations
    }
}

/// Syntax visitor to detect service instantiation patterns
private class ServiceInstantiationVisitor: SyntaxVisitor {
    var instantiations: [ServiceInstantiationAnalyzer.ServiceInstantiation] = []

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        // Look for patterns like: APIClient(), DatabaseClient(), etc.
        if let calledExpression = node.calledExpression.as(IdentifierTypeSyntax.self) {
            let serviceName = calledExpression.name.description.trimmingCharacters(in: .whitespacesAndNewlines)

            // Check if this looks like a service/client instantiation
            if isServiceName(serviceName) {
                let instantiation = ServiceInstantiationAnalyzer.ServiceInstantiation(
                    serviceName: serviceName,
                    type: "Direct instantiation",
                    lineNumber: getLineNumber(from: node)
                )
                instantiations.append(instantiation)
            }
        }
        return .visitChildren
    }

    private func isServiceName(_ name: String) -> Bool {
        return name.contains("Client") ||
               name.contains("Service") ||
               name.contains("Manager") ||
               name.contains("Repository") ||
               name.contains("API") ||
               name.contains("Database")
    }

    private func getLineNumber(from node: some SyntaxProtocol) -> Int {
        let source = node.root.description
        let position = node.position.utf8Offset
        let substring = String(source.prefix(position))
        return substring.components(separatedBy: .newlines).count
    }
}

/// Analyzes Swift code for hardcoded values that should use dependencies
private class HardcodedValueAnalyzer {
    struct HardcodedValue {
        let valueType: String
        let value: String
        let lineNumber: Int
    }

    var foundHardcodedValues: [HardcodedValue] = []

    func analyze(_ syntax: StructDeclSyntax) {
        let visitor = HardcodedValueVisitor(viewMode: .sourceAccurate)
        visitor.walk(syntax)
        foundHardcodedValues = visitor.hardcodedValues
    }
}

/// Syntax visitor to detect hardcoded values
private class HardcodedValueVisitor: SyntaxVisitor {
    var hardcodedValues: [HardcodedValueAnalyzer.HardcodedValue] = []

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        // Look for hardcoded values like: let apiClient = APIClient()
        for binding in node.bindings {
            if let initializer = binding.initializer?.value.as(FunctionCallExprSyntax.self),
               let calledExpression = initializer.calledExpression.as(IdentifierTypeSyntax.self) {
                let serviceName = calledExpression.name.description.trimmingCharacters(in: .whitespacesAndNewlines)

                if isCommonService(serviceName) {
                    let hardcoded = HardcodedValueAnalyzer.HardcodedValue(
                        valueType: serviceName,
                        value: initializer.description.trimmingCharacters(in: .whitespacesAndNewlines),
                        lineNumber: getLineNumber(from: node)
                    )
                    hardcodedValues.append(hardcoded)
                }
            }
        }
        return .visitChildren
    }

    private func isCommonService(_ name: String) -> Bool {
        return name == "URLSession" ||
               name == "UserDefaults" ||
               name == "FileManager" ||
               name == "Date" ||
               name.contains("Client") ||
               name.contains("Service")
    }

    private func getLineNumber(from node: some SyntaxProtocol) -> Int {
        let source = node.root.description
        let position = node.position.utf8Offset
        let substring = String(source.prefix(position))
        return substring.components(separatedBy: .newlines).count
    }
}

/// Analyzes Swift code for service usage patterns
private class ServiceUsageAnalyzer {
    var usedServices: Set<String> = []

    func analyze(_ syntax: StructDeclSyntax) {
        let visitor = ServiceUsageVisitor(viewMode: .sourceAccurate)
        visitor.walk(syntax)
        usedServices = visitor.usedServices
    }
}

/// Syntax visitor to detect service usage
private class ServiceUsageVisitor: SyntaxVisitor {
    var usedServices: Set<String> = []

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        // Look for patterns like: apiClient.fetch(), database.save(), etc.
        if let baseIdentifier = node.base?.as(IdentifierExprSyntax.self) {
            let baseName = baseIdentifier.identifier.text.trimmingCharacters(in: .whitespacesAndNewlines)

            // Only consider it a service if it's a simple identifier (not complex expressions)
            if isServiceName(baseName) {
                usedServices.insert(baseName)
            }
        }
        return .visitChildren
    }

    private func isServiceName(_ name: String) -> Bool {
        // More specific criteria to avoid false positives
        let servicePatterns = ["Client", "Service", "Manager", "Repository"]
        let hasServiceSuffix = servicePatterns.contains { name.hasSuffix($0) }
        let hasCommonServicePrefix = name.hasPrefix("api") ||
                                   name.hasPrefix("database") ||
                                   name.hasPrefix("network") ||
                                   name.hasPrefix("cache")

        // Exclude common variable names that aren't services
        let excludedNames = ["state", "action", "self", "super", "reduce", "send", "run"]

        return (hasServiceSuffix || hasCommonServicePrefix) &&
               !excludedNames.contains(name.lowercased()) &&
               name.count > 2 // Avoid very short identifiers
    }
}