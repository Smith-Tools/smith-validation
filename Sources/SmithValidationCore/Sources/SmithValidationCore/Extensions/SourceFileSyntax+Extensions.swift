// Extensions/SourceFileSyntax+Extensions.swift
// High-level extensions for SwiftSourceFileSyntax that hide AST complexity

import SwiftSyntax
import SwiftParser
import Foundation

/// High-level extensions for SwiftSourceFileSyntax that provide semantic operations
public extension SourceFileSyntax {

    /// Find all TCA reducers in this file
    /// - Returns: Array of StructInfo for structs conforming to Reducer or with @Reducer attribute
    public func findTCAReducers() -> [StructInfo] {
        var reducers: [StructInfo] = []

        let visitor = TCAReducerVisitor(viewMode: .sourceAccurate)
        visitor.walk(self)
        reducers = visitor.reducers

        return reducers
    }

    /// Find State structs within TCA reducers
    /// - Returns: Array of StateStructInfo for State structs found in TCA reducers
    public func findStatesInTCAReducers() -> [StructInfo] {
        let reducers = findTCAReducers()
        return reducers.compactMap { reducer in
            reducer.findNestedStruct(named: "State")
        }
    }

    /// Find Action enums within TCA reducers
    /// - Returns: Array of EnumInfo for Action enums found in TCA reducers
    public func findActionsInTCAReducers() -> [EnumInfo] {
        let reducers = findTCAReducers()
        return reducers.compactMap { reducer in
            reducer.findNestedEnum(named: "Action")
        }
    }

    /// Parse Swift code from a string
    /// - Parameter source: Swift source code string
    /// - Returns: Parsed SourceFileSyntax
    public static func parse(source: String) throws -> SourceFileSyntax {
        return Parser.parse(source: source)
    }

    /// Parse Swift code from a file URL
    /// - Parameter url: URL of Swift file to parse
    /// - Returns: Parsed SourceFileSyntax
    public static func parse(from url: URL) throws -> SourceFileSyntax {
        let source = try String(contentsOf: url)
        return try parse(source: source)
    }

    /// Find all SwiftUI Views in this file
    /// - Returns: Array of StructInfo for structs conforming to View or with View naming patterns
    public func findSwiftUIViews() -> [StructInfo] {
        var views: [StructInfo] = []

        let visitor = SwiftUIViewVisitor(viewMode: .sourceAccurate)
        visitor.walk(self)
        views = visitor.views

        return views
    }
}

// MARK: - Syntax Visitor for TCA Reducer Detection

private class TCAReducerVisitor: SyntaxVisitor {
    var reducers: [StructInfo] = []

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        // Check if struct has @Reducer attribute or conforms to Reducer protocol
        let hasReducerAttribute = node.attributes.containsAttribute { attribute in
            attribute.attributeName.description == "Reducer"
        }

        let conformsToReducer = node.inheritanceClause?.inheritedTypes.contains { element in
            element.type.description.trimmingCharacters(in: .whitespacesAndNewlines) == "Reducer"
        } ?? false

        if hasReducerAttribute || conformsToReducer {
            reducers.append(StructInfo(from: node))
        }

        return .skipChildren
    }
}

// MARK: - Syntax Visitor for SwiftUI View Detection

private class SwiftUIViewVisitor: SyntaxVisitor {
    var views: [StructInfo] = []

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        // Check if struct conforms to View protocol or has View naming patterns
        let conformsToView = node.inheritanceClause?.inheritedTypes.contains { element in
            element.type.description.trimmingCharacters(in: .whitespacesAndNewlines) == "View"
        } ?? false

        // Check for common SwiftUI View naming patterns
        let viewNamingPatterns = ["View", "View_", "ContentView", "DetailView", "ListView"]
        let hasViewNamingPattern = viewNamingPatterns.contains { pattern in
            node.identifier.text.contains(pattern)
        }

        // Check if struct has a body method (common for SwiftUI Views)
        let hasBodyMethod = node.memberBlock.members.contains { member in
            if let function = member.decl.as(FunctionDeclSyntax.self) {
                return function.identifier.text == "body"
            }
            return false
        }

        // More accurate SwiftUI View detection
        let isSwiftUIView = conformsToView || (
            node.identifier.text.hasSuffix("View") &&
            hasBodyMethod &&
            !isRuleOrTestClass(node.identifier.text)
        )

        if isSwiftUIView {
            views.append(StructInfo(from: node))
        }

        return .skipChildren
    }

    private func isRuleOrTestClass(_ name: String) -> Bool {
        // Exclude rule implementations and test files from SwiftUI detection
        let excludedPatterns = ["Rule", "Test", "Mock", "Fake", "Validator", "Registrar"]
        return excludedPatterns.contains { pattern in
            name.contains(pattern)
        }
    }
}

// MARK: - Helper Extensions

extension AttributeListSyntax {
    /// Check if any attribute in the list satisfies the predicate
    /// - Parameter predicate: A closure that takes an AttributeSyntax and returns Bool
    /// - Returns: True if any attribute satisfies the predicate
    func containsAttribute(where predicate: (AttributeSyntax) -> Bool) -> Bool {
        return self.contains { attribute in
            if let attr = attribute.as(AttributeSyntax.self) {
                return predicate(attr)
            }
            return false
        }
    }
}