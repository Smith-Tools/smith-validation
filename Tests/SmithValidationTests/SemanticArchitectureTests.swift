// Tests/SmithValidationTests/SemanticArchitectureTests.swift
// Unified Swift Testing + SourceKit Semantic Architecture Validation

import Foundation
import Testing
import SourceKittenFramework

@Suite("Semantic Architecture Tests - Swift Testing + SourceKit")
struct SemanticArchitectureTests {

    /// Test that validates TCA error handling semantics using SourceKit
    @Test("TCA reducers should have error handling semantics")
    func validateTCAErrorHandlingSemantics() async throws {
        // Test expectation: Real TCA reducers should have error handling
        let scrollReducerPath = "/Volumes/Plutonian/_Developer/Scroll/source/Scroll"
        
        // Use SourceKit to find and analyze actual TCA reducers
        let sourceKitAnalysis = await performSourceKitAnalysis(projectPath: scrollReducerPath)
        let tcaReducers = sourceKitAnalysis.filter { $0.hasTCAReducerPattern }
        
        print("🔍 Found \(tcaReducers.count) potential TCA reducers")
        
        for reducer in tcaReducers {
            print("📋 Analyzing: \(reducer.fileName)")
            
            // Test expectation: Valid TCA reducers should have error handling
            #expect(reducer.hasErrorHandling == true, 
                   "TCA reducer '\(reducer.fileName)' should have error handling in Action enum. Found: \(reducer.errorHandlingActions)")
            
            // Test expectation: Valid TCA reducers should have State struct
            #expect(reducer.hasStateStruct == true,
                   "TCA reducer '\(reducer.fileName)' should have State struct")
            
            // Test expectation: State should not be monolithic
            #expect(reducer.statePropertyCount <= 15,
                   "TCA reducer '\(reducer.fileName)' should not have monolithic State with \(reducer.statePropertyCount) properties (threshold: 15)")
        }
    }

    /// Test that validates SwiftUI View complexity semantics
    @Test("SwiftUI Views should have manageable complexity")
    func validateSwiftUIComplexitySemantics() async throws {
        let scrollProjectPath = "/Volumes/Plutonian/_Developer/Scroll/source/Scroll"
        
        let sourceKitAnalysis = await performSourceKitAnalysis(projectPath: scrollProjectPath)
        let swiftUIViews = sourceKitAnalysis.filter { $0.isSwiftUIView }
        
        print("🎨 Found \(swiftUIViews.count) SwiftUI Views")
        
        for view in swiftUIViews {
            print("🖼️  Analyzing View: \(view.fileName)")
            
            // Test expectation: SwiftUI Views should have body property
            #expect(view.hasBodyProperty == true,
                   "SwiftUI View '\(view.fileName)' should have body property")
            
            // Test expectation: Body complexity should be manageable
            #expect(view.bodyComplexityScore <= 100,
                   "SwiftUI View '\(view.fileName)' should have manageable complexity (score: \(view.bodyComplexityScore), threshold: 100)")
        }
    }

    /// Test that validates TCA feature composition semantics
    @Test("TCA features should follow composition patterns") 
    func validateTCACompositionSemantics() async throws {
        let scrollProjectPath = "/Volumes/Plutonian/_Developer/Scroll/source/Scroll"
        
        let sourceKitAnalysis = await performSourceKitAnalysis(projectPath: scrollProjectPath)
        let tcaFiles = sourceKitAnalysis.filter { $0.hasTCAReducerPattern }
        
        // Test expectation: Should find multiple composable TCA features
        #expect(tcaFiles.count >= 5,
               "Scroll project should have multiple composable TCA features (found: \(tcaFiles.count))")
        
        // Test expectation: Each feature should be focused
        let wellSizedFeatures = tcaFiles.filter { $0.statePropertyCount <= 15 }
        let compositionScore = Double(wellSizedFeatures.count) / Double(tcaFiles.count)
        
        #expect(compositionScore >= 0.7,
               "At least 70% of TCA features should be well-sized (actual: \(String(format: "%.1f", compositionScore * 100))%)")
        
        print("📊 TCA Composition Metrics:")
        print("   Total TCA files: \(tcaFiles.count)")
        print("   Well-sized features: \(wellSizedFeatures.count)")
        print("   Composition score: \(String(format: "%.1f", compositionScore * 100))%")
    }

    // MARK: - SourceKit Analysis Engine

    private func performSourceKitAnalysis(projectPath: String) async -> [SourceKitAnalysisResult] {
        var results: [SourceKitAnalysisResult] = []
        
        let swiftFiles = findSwiftFiles(in: URL(fileURLWithPath: projectPath))
        print("🔍 Analyzing \(swiftFiles.count) Swift files with SourceKit...")
        
        for file in swiftFiles {
            if let analysis = await analyzeFileWithSourceKit(file: file) {
                results.append(analysis)
            }
        }
        
        print("✅ SourceKit analysis complete: \(results.count) files analyzed")
        return results
    }

    private func analyzeFileWithSourceKit(file: URL) async -> SourceKitAnalysisResult? {
        do {
            guard let sourceKitFile = File(path: file.path) else { return nil }
            let structure = try Structure(file: sourceKitFile)
            
            return SourceKitAnalysisResult(
                fileName: file.lastPathComponent,
                filePath: file.path,
                structure: structure
            )
        } catch {
            return nil
        }
    }

    private func findSwiftFiles(in directory: URL) -> [URL] {
        var swiftFiles: [URL] = []
        
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return swiftFiles }
        
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "swift" {
                swiftFiles.append(fileURL)
            }
        }
        
        return swiftFiles
    }
}

// MARK: - SourceKit Analysis Result

struct SourceKitAnalysisResult {
    let fileName: String
    let filePath: String
    let structure: Structure
    
    // Computed properties for semantic analysis
    var hasTCAReducerPattern: Bool {
        let substructures = getSubstructures(from: structure.dictionary)
        return substructures.contains { substructure in
            let kind = getKind(from: substructure)
            let name = getName(from: substructure)
            
            return kind == "source.lang.swift.decl.struct" && 
                   (hasInheritedType(substructure, type: "Reducer") || name.contains("Reducer"))
        }
    }
    
    var hasErrorHandling: Bool {
        guard let actionEnum = findActionEnum() else { return false }
        let actionSubstructures = getSubstructures(from: actionEnum)
        let enumCases = actionSubstructures.filter { 
            getKind(from: $0) == "source.lang.swift.decl.enumcase" 
        }
        
        return enumCases.contains { enumCase in
            let caseName = getName(from: enumCase)
            return caseName.lowercased().contains("error") ||
                   caseName.lowercased().contains("failure") ||
                   caseName.lowercased().contains("failed")
        }
    }
    
    var hasStateStruct: Bool {
        return findStateStruct() != nil
    }
    
    var statePropertyCount: Int {
        guard let stateStruct = findStateStruct() else { return 0 }
        let stateSubstructures = getSubstructures(from: stateStruct)
        return stateSubstructures.filter { 
            getKind(from: $0) == "source.lang.swift.decl.var.instance" 
        }.count
    }
    
    var isSwiftUIView: Bool {
        let substructures = getSubstructures(from: structure.dictionary)
        return substructures.contains { substructure in
            let kind = getKind(from: substructure)
            return kind == "source.lang.swift.decl.struct" && 
                   (hasInheritedType(substructure, type: "View") || getName(from: substructure).contains("View"))
        }
    }
    
    var hasBodyProperty: Bool {
        guard let viewStruct = findSwiftUIViewStruct() else { return false }
        let viewSubstructures = getSubstructures(from: viewStruct)
        return viewSubstructures.contains { substructure in
            getKind(from: substructure) == "source.lang.swift.decl.var.instance" && 
            getName(from: substructure) == "body"
        }
    }
    
    var bodyComplexityScore: Int {
        guard let viewStruct = findSwiftUIViewStruct() else { return 0 }
        let viewSubstructures = getSubstructures(from: viewStruct)
        guard let bodyVar = viewSubstructures.first(where: {
            getKind(from: $0) == "source.lang.swift.decl.var.instance" && getName(from: $0) == "body"
        }) else { return 0 }
        
        return calculateComplexityScore(bodyVar)
    }
    
    var errorHandlingActions: [String] {
        guard let actionEnum = findActionEnum() else { return [] }
        let actionSubstructures = getSubstructures(from: actionEnum)
        let enumCases = actionSubstructures.filter { 
            getKind(from: $0) == "source.lang.swift.decl.enumcase" 
        }
        
        return enumCases.compactMap { enumCase in
            let caseName = getName(from: enumCase)
            if caseName.lowercased().contains("error") ||
               caseName.lowercased().contains("failure") ||
               caseName.lowercased().contains("failed") {
                return caseName
            }
            return nil
        }
    }

    // MARK: - Helper Methods
    
    private func findActionEnum() -> [String: SourceKitRepresentable]? {
        let substructures = getSubstructures(from: structure.dictionary)
        return substructures.first { substructure in
            getKind(from: substructure) == "source.lang.swift.decl.enum" && 
            getName(from: substructure) == "Action"
        }
    }
    
    private func findStateStruct() -> [String: SourceKitRepresentable]? {
        let substructures = getSubstructures(from: structure.dictionary)
        return substructures.first { substructure in
            getKind(from: substructure) == "source.lang.swift.decl.struct" && 
            getName(from: substructure) == "State"
        }
    }
    
    private func findSwiftUIViewStruct() -> [String: SourceKitRepresentable]? {
        let substructures = getSubstructures(from: structure.dictionary)
        return substructures.first { substructure in
            let kind = getKind(from: substructure)
            return kind == "source.lang.swift.decl.struct" && 
                   (hasInheritedType(substructure, type: "View") || getName(from: substructure).contains("View"))
        }
    }
    
    private func getSubstructures(from dict: [String: SourceKitRepresentable]) -> [[String: SourceKitRepresentable]] {
        return (dict["key.substructure"] as? [[String: SourceKitRepresentable]]) ?? []
    }
    
    private func getKind(from dict: [String: SourceKitRepresentable]) -> String {
        return (dict["key.kind"] as? String) ?? ""
    }
    
    private func getName(from dict: [String: SourceKitRepresentable]) -> String {
        return (dict["key.name"] as? String) ?? ""
    }
    
    private func hasInheritedType(_ dict: [String: SourceKitRepresentable], type: String) -> Bool {
        guard let inheritedTypes = dict["key.inheritedtypes"] as? [String] else {
            return false
        }
        return inheritedTypes.contains(type)
    }
    
    private func calculateComplexityScore(_ bodyVar: [String: SourceKitRepresentable]) -> Int {
        var complexity = 0
        var stack: [[String: SourceKitRepresentable]] = [bodyVar]
        
        while !stack.isEmpty {
            let current = stack.removeLast()
            complexity += 1
            stack.append(contentsOf: getSubstructures(from: current))
        }
        
        return complexity
    }
}
