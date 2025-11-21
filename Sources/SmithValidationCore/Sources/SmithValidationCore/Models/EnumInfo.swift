// Models/EnumInfo.swift
// High-level semantic model for Swift enums that hides AST complexity

import SwiftSyntax

/// High-level semantic model for Swift enums that hides AST complexity
public struct EnumInfo {
    public let name: String
    public let caseCount: Int
    public let conformingProtocols: [String]
    public let lineNumber: Int
    public let syntax: EnumDeclSyntax
    public let caseNames: [String]

    /// Create an EnumInfo from a SwiftSyntax EnumDeclSyntax
    public init(from syntax: EnumDeclSyntax) {
        self.syntax = syntax
        self.name = syntax.name.description.trimmingCharacters(in: .whitespacesAndNewlines)

        // Use local variables to compute values before assignment
        let lineNumber = Self.getLineNumber(from: syntax)
        let caseCount = Self.countCases(in: syntax)
        let caseNames = Self.extractCaseNames(from: syntax)
        let conformingProtocols = Self.extractConformingProtocols(from: syntax)

        self.lineNumber = lineNumber
        self.caseCount = caseCount
        self.caseNames = caseNames
        self.conformingProtocols = conformingProtocols
    }

    /// Check if this enum conforms to a specific protocol
    public func conformsTo(_ protocolName: String) -> Bool {
        return conformingProtocols.contains(protocolName)
    }

    /// Check if this enum has a specific case
    public func hasCase(_ name: String) -> Bool {
        return caseNames.contains(name)
    }

    /// Find duplicate case names
    public func findDuplicateCases() -> [String] {
        let duplicates = Dictionary(grouping: caseNames) { $0 }
            .filter { $1.count > 1 }
            .keys
        return Array(duplicates)
    }

    /// Check if this enum is a simple enum (no associated values)
    public var isSimpleEnum: Bool {
        return syntax.memberBlock.members.compactMap { member in
            member.decl.as(EnumCaseDeclSyntax.self)
        }.allSatisfy { $0.elements.allSatisfy { $0.parameterClause == nil } }
    }
}

// MARK: - Private Helper Functions

private extension EnumInfo {
    static func countCases(in syntax: EnumDeclSyntax) -> Int {
        return syntax.memberBlock.members.compactMap { member in
            member.decl.as(EnumCaseDeclSyntax.self)
        }.flatMap { $0.elements }.count
    }

    static func extractCaseNames(from syntax: EnumDeclSyntax) -> [String] {
        return syntax.memberBlock.members.compactMap { member in
            member.decl.as(EnumCaseDeclSyntax.self)
        }.flatMap { $0.elements }.map { $0.name.description }
    }

    static func extractConformingProtocols(from syntax: EnumDeclSyntax) -> [String] {
        guard let inheritanceClause = syntax.inheritanceClause else { return [] }

        return inheritanceClause.inheritedTypes.compactMap { element in
            element.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    static func getLineNumber(from node: some SyntaxProtocol) -> Int {
        let source = node.root.description
        let position = node.position.utf8Offset
        let substring = String(source.prefix(position))
        return substring.components(separatedBy: .newlines).count
    }
}