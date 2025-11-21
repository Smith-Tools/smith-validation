// Models/StructInfo.swift
// High-level semantic model for Swift structs

import SwiftSyntax

/// High-level semantic model for Swift structs that hides AST complexity
public struct StructInfo {
    public let name: String
    public let propertyCount: Int
    public let methodCount: Int
    public let conformingProtocols: [String]
    public let lineNumber: Int
    public let syntax: StructDeclSyntax

    /// Create a StructInfo from a SwiftSyntax StructDeclSyntax
    public init(from syntax: StructDeclSyntax) {
        self.syntax = syntax
        self.name = syntax.name.description.trimmingCharacters(in: .whitespacesAndNewlines)

        // Use local variables to compute values before assignment
        let lineNumber = Self.getLineNumber(from: syntax)
        let propertyCount = Self.countProperties(in: syntax)
        let methodCount = Self.countMethods(in: syntax)
        let conformingProtocols = Self.extractConformingProtocols(from: syntax)

        self.lineNumber = lineNumber
        self.propertyCount = propertyCount
        self.methodCount = methodCount
        self.conformingProtocols = conformingProtocols
    }

    /// Check if this struct conforms to a specific protocol
    public func conformsTo(_ protocolName: String) -> Bool {
        return conformingProtocols.contains(protocolName)
    }

    /// Check if this struct is a TCA Reducer
    public var isTCAReducer: Bool {
        return conformsTo("Reducer") || hasReducerAttribute
    }

    /// Check if this struct has the @Reducer attribute
    private var hasReducerAttribute: Bool {
        return syntax.attributes.containsAttribute { attribute in
            attribute.attributeName.description == "Reducer"
        }
    }

    /// Get nested structs within this struct
    public func findNestedStructs() -> [StructInfo] {
        var nestedStructs: [StructInfo] = []

        for member in syntax.memberBlock.members {
            if let structDecl = member.decl.as(StructDeclSyntax.self) {
                nestedStructs.append(StructInfo(from: structDecl))
            }
        }

        return nestedStructs
    }

    /// Find a specific nested struct by name
    public func findNestedStruct(named name: String) -> StructInfo? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return findNestedStructs().first { $0.name == trimmedName }
    }

    /// Get nested enums within this struct
    public func findNestedEnums() -> [EnumInfo] {
        var nestedEnums: [EnumInfo] = []

        for member in syntax.memberBlock.members {
            if let enumDecl = member.decl.as(EnumDeclSyntax.self) {
                nestedEnums.append(EnumInfo(from: enumDecl))
            }
        }

        return nestedEnums
    }

    /// Find a specific nested enum by name
    public func findNestedEnum(named name: String) -> EnumInfo? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return findNestedEnums().first { $0.name == trimmedName }
    }
}

// MARK: - Private Helper Functions

private extension StructInfo {
    static func countProperties(in syntax: StructDeclSyntax) -> Int {
        return syntax.memberBlock.members.compactMap { member in
            member.decl.as(VariableDeclSyntax.self)
        }.count
    }

    static func countMethods(in syntax: StructDeclSyntax) -> Int {
        return syntax.memberBlock.members.compactMap { member in
            member.decl.as(FunctionDeclSyntax.self)
        }.count
    }

    static func extractConformingProtocols(from syntax: StructDeclSyntax) -> [String] {
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