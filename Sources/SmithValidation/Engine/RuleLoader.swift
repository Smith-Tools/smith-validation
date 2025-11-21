// Engine/RuleLoader.swift
// Dynamic rule discovery and loading system

import Foundation
import SmithValidationCore
import SwiftSyntax
import Darwin

/// Discovers and loads validation rules from specified directories
public class RuleLoader {

    /// Configuration for rule loading behavior
    public struct Configuration {
        public let searchPaths: [String]
        public let recursiveSearch: Bool
        public let maxRulesPerDirectory: Int

        public init(
            searchPaths: [String],
            recursiveSearch: Bool = true,
            maxRulesPerDirectory: Int = 50
        ) {
            self.searchPaths = searchPaths
            self.recursiveSearch = recursiveSearch
            self.maxRulesPerDirectory = maxRulesPerDirectory
        }
    }

    private let configuration: Configuration

    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    /// Convenience initializer that builds configuration from a parsed PKL config file.
    /// Only enabled bundles are included.
    convenience init(from config: SmithValidationConfig) {
        let enabledBundles = config.bundles.filter { $0.enabled ?? true }
        let resolvedPaths = enabledBundles.map { bundle in
            // Resolve relative bundle paths against current working directory.
            URL(fileURLWithPath: bundle.path, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)).path
        }

        self.init(configuration: Configuration(searchPaths: resolvedPaths))
    }

    /// Load all discoverable validation rules from configured paths
    /// - Returns: Array of loaded validation rules
    /// - Throws: RuleLoadingError for loading failures
    public func loadRules() throws -> [any ValidatableRule] {
        var loadedRules: [any ValidatableRule] = []

        for searchPath in configuration.searchPaths {
            let directoryURL = URL(fileURLWithPath: searchPath)

            // Find Swift files containing validation rules
            let ruleFiles = try findRuleFiles(in: directoryURL)

            // Load rules from each file
            let directoryRules = try loadRules(from: ruleFiles.map { $0.path })
            loadedRules.append(contentsOf: directoryRules)
        }

        return loadedRules
    }

    /// Load rules from specific file paths
    /// - Parameter filePaths: Array of Swift file paths containing rules
    /// - Returns: Array of loaded validation rules
    /// - Throws: RuleLoadingError for loading failures
    public func loadRules(from filePaths: [String]) throws -> [any ValidatableRule] {
        var rules: [any ValidatableRule] = []

        for filePath in filePaths {
            let fileRules = try loadRules(from: filePath)
            rules.append(contentsOf: fileRules)
        }

        return rules
    }

    // MARK: - Private Methods

    /// Find Swift files that likely contain validation rules
    /// - Parameter directory: Directory to search
    /// - Returns: Array of Swift file URLs
    /// - Throws: File system errors
    private func findRuleFiles(in directory: URL) throws -> [URL] {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: directory.path) else {
            throw RuleLoadingError.directoryNotFound(directory)
        }

        var ruleFiles: [URL] = []
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .nameKey]

        let directoryEnumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        )

        guard let enumerator = directoryEnumerator else {
            return ruleFiles
        }

        var fileCount = 0

        for case let fileURL as URL in enumerator {
            guard fileCount < configuration.maxRulesPerDirectory else {
                break
            }

            guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys)) else {
                continue
            }

            if resourceValues.isDirectory == true && configuration.recursiveSearch {
                // Continue searching subdirectories
                continue
            } else if fileURL.pathExtension == "swift" {
                // Check if this Swift file contains validation rules
                if try containsValidationRules(fileURL) {
                    ruleFiles.append(fileURL)
                    fileCount += 1
                }
            }
        }

        return ruleFiles
    }

    /// Check if a Swift file contains validation rules
    /// - Parameter fileURL: URL of the Swift file to check
    /// - Returns: True if the file appears to contain validation rules
    private func containsValidationRules(_ fileURL: URL) throws -> Bool {
        let content = try String(contentsOf: fileURL)

        // Look for indicators of validation rules
        return content.contains("ValidatableRule") ||
               content.contains("ViolationCollection") ||
               content.contains("ArchitecturalViolation") ||
               content.contains("func validate(context:")
    }

    /// Load rules from a specific Swift file
    /// - Parameter filePath: Path to the Swift file
    /// - Returns: Array of loaded validation rules
    /// - Throws: RuleLoadingError for loading failures
    private func loadRules(from filePath: String) throws -> [any ValidatableRule] {
        let fileURL = URL(fileURLWithPath: filePath)
        return try loadRules(from: fileURL)
    }

    /// Load rules from a specific Swift file URL
    /// - Parameter fileURL: URL of the Swift file
    /// - Returns: Array of loaded validation rules
    /// - Throws: RuleLoadingError for loading failures
    private func loadRules(from fileURL: URL) throws -> [any ValidatableRule] {
        // Fallback to mock rule (legacy path not used in bundle mode)
        let ruleInfo = RuleInfo(
            name: fileURL.deletingPathExtension().lastPathComponent,
            filePath: fileURL.path,
            description: "Stub rule loaded from \(fileURL.lastPathComponent)"
        )
        return [MockRule(info: ruleInfo)]
    }
}

/// Information about a discovered validation rule
public struct RuleInfo {
    public let name: String
    public let filePath: String
    public let description: String

    public init(name: String, filePath: String, description: String) {
        self.name = name
        self.filePath = filePath
        self.description = description
    }
}

/// Errors that can occur during rule loading
public enum RuleLoadingError: Error, LocalizedError {
    case directoryNotFound(URL)
    case fileNotFound(URL)
    case compilationFailed(String)
    case instantiationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .directoryNotFound(let url):
            return "Rule directory not found: \(url.path)"
        case .fileNotFound(let url):
            return "Rule file not found: \(url.path)"
        case .compilationFailed(let message):
            return "Rule compilation failed: \(message)"
        case .instantiationFailed(let message):
            return "Rule instantiation failed: \(message)"
        }
    }
}

/// Mock rule for demonstration purposes
private struct MockRule: ValidatableRule {
    let info: RuleInfo

    func validate(context: SourceFileContext) -> ViolationCollection {
        // Simple mock validation - in real implementation this would be the actual rule
        return ViolationCollection(violations: [])
    }
}

// MARK: - Bundle-based loading extension

public extension RuleLoader {

    /// Build and load rule bundles from configured search paths that are SwiftPM packages of rules.
    /// This compiles a temporary dynamic library and calls its exported `smith_register_rules` function.
    func loadBundles() throws -> [any ValidatableRule] {
        var all: [any ValidatableRule] = []
        for path in configuration.searchPaths {
            let bundleURL = URL(fileURLWithPath: path)
            let rules = try buildAndLoadBundle(at: bundleURL)
            all.append(contentsOf: rules)
        }
        return all
    }

    private func buildAndLoadBundle(at bundlePath: URL) throws -> [any ValidatableRule] {
        // Discover rule type names by regex from Swift files
        let swiftFiles = try discoverSwiftFiles(in: bundlePath)
        let ruleFilesWithTypes: [(URL, [String])] = swiftFiles.compactMap { file in
            guard let types = try? extractRuleTypeNames(in: file), !types.isEmpty else { return nil }
            return (file, types)
        }

        let ruleTypeNames = ruleFilesWithTypes.flatMap { $0.1 }.uniqued()

        // If no rules found, nothing to load
        if ruleTypeNames.isEmpty { return [] }

        // Create temp package
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("smith-bundle-\(UUID().uuidString)")
        let sourcesDir = tempDir.appendingPathComponent("Sources/BundleLib")
        try FileManager.default.createDirectory(at: sourcesDir, withIntermediateDirectories: true)

        // Symlink only rule source files into temp package
        for (file, _) in ruleFilesWithTypes {
            let dest = sourcesDir.appendingPathComponent(file.lastPathComponent)
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.createSymbolicLink(at: dest, withDestinationURL: file)
        }

        // Generate registrar source
        let registrar = sourcesDir.appendingPathComponent("Registrar.swift")
        let registrarContents = registrarSource(ruleTypeNames: ruleTypeNames)
        try registrarContents.write(to: registrar, atomically: true, encoding: String.Encoding.utf8)

        // Write Package.swift
        let packageSwift = tempDir.appendingPathComponent("Package.swift")
        try packageManifest().write(to: packageSwift, atomically: true, encoding: .utf8)

        // Build dynamic library
        let buildResult = try runSwiftBuild(at: tempDir)
        guard buildResult == 0 else {
            throw RuleLoadingError.compilationFailed("swift build failed for bundle at \(bundlePath.path)")
        }

        let dylib = try locateDylib(in: tempDir)

        // dlopen and call exported registrar
        guard let handle = dlopen(dylib.path, RTLD_NOW | RTLD_LOCAL) else {
            let err = String(cString: dlerror())
            throw RuleLoadingError.compilationFailed("dlopen failed: \(err)")
        }

        defer { dlclose(handle) }

        typealias RegisterFn = @convention(c) () -> UnsafeMutableRawPointer
        guard let sym = dlsym(handle, "smith_register_rules") else {
            throw RuleLoadingError.instantiationFailed("Missing symbol smith_register_rules")
        }

        let fn = unsafeBitCast(sym, to: RegisterFn.self)
        let ptr = fn()
        let nsArray = Unmanaged<NSArray>.fromOpaque(ptr).takeRetainedValue()
        let rules: [any ValidatableRule] = nsArray.compactMap { $0 as? any ValidatableRule }

        if rules.isEmpty {
            print("⚠️  Loaded bundle at \(bundlePath.path) but found 0 ValidatableRule instances (types discovered: \(ruleTypeNames))")
        }
        return rules
    }

    // MARK: helper generation

    private func registrarSource(ruleTypeNames: [String]) -> String {
        var lines: [String] = []
        lines.append("import Foundation")
        lines.append("import SmithValidationCore")
        lines.append("import SwiftSyntax")
        lines.append("")
        lines.append("@_cdecl(\"smith_register_rules\")")
        lines.append("public func smith_register_rules() -> UnsafeMutableRawPointer {")
        lines.append("    let rules: [Any] = [")
        for name in ruleTypeNames {
            lines.append("        \(name)(),")
        }
        lines.append("    ]")
        lines.append("    return Unmanaged.passRetained(rules as NSArray).toOpaque()")
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    private func packageManifest() -> String {
        let cwd = FileManager.default.currentDirectoryPath
        let corePath = URL(fileURLWithPath: cwd)
            .appendingPathComponent("../SmithValidationCore")
            .standardized.path
        return """
        // swift-tools-version: 5.9
        import PackageDescription

        let package = Package(
            name: "SmithBundle",
            platforms: [.macOS(.v13)],
            products: [
                .library(name: "BundleLib", type: .dynamic, targets: ["BundleLib"])
            ],
            dependencies: [
                .package(path: "\(corePath)"),
                .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0")
            ],
            targets: [
                .target(
                    name: "BundleLib",
                    dependencies: [
                        .product(name: "SmithValidationCore", package: "SmithValidationCore"),
                        .product(name: "SwiftSyntax", package: "swift-syntax"),
                        .product(name: "SwiftParser", package: "swift-syntax")
                    ]
                )
            ]
        )
        """
    }

    private func runSwiftBuild(at directory: URL) throws -> Int32 {
        let process = Process()
        process.currentDirectoryURL = directory
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["swift", "build", "-c", "release"]
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }

    /// Locate the built dynamic library (SwiftPM output path can vary by Swift toolchain).
    private func locateDylib(in tempDir: URL) throws -> URL {
        let buildRoot = tempDir.appendingPathComponent(".build")
        let fm = FileManager.default
        guard fm.fileExists(atPath: buildRoot.path) else {
            throw RuleLoadingError.compilationFailed("Build artifacts not found under \(buildRoot.path)")
        }

        let expectedName = "libBundleLib.dylib"
        if let direct = findFirstMatch(root: buildRoot, filename: expectedName) {
            return direct
        }

        // Fallback: any BundleLib*.dylib
        if let any = findFirstMatch(root: buildRoot, suffix: "BundleLib.dylib") {
            return any
        }

        throw RuleLoadingError.compilationFailed("Built library not found at \(buildRoot.path)")
    }

    private func findFirstMatch(root: URL, filename: String? = nil, suffix: String? = nil) -> URL? {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey]) else {
            return nil
        }
        for case let url as URL in enumerator {
            if url.pathComponents.contains(where: { $0.hasSuffix(".dSYM") }) {
                continue // skip debug symbol bundles
            }
            if let filename, url.lastPathComponent == filename {
                return url
            }
            if let suffix, url.lastPathComponent.hasSuffix(suffix) {
                return url
            }
        }
        return nil
    }

    private func extractRuleTypeNames(in fileURL: URL) throws -> [String] {
        let content = try String(contentsOf: fileURL)
        let regex = try NSRegularExpression(pattern: #"struct\s+([A-Za-z0-9_]+)\s*:\s*ValidatableRule"#)
        let nsrange = NSRange(content.startIndex..<content.endIndex, in: content)
        return regex.matches(in: content, options: [], range: nsrange).compactMap { match in
            guard let range = Range(match.range(at: 1), in: content) else { return nil }
            return String(content[range])
        }
    }

    private func discoverSwiftFiles(in directory: URL) throws -> [URL] {
        var files: [URL] = []
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: directory, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return files
        }
        for case let url as URL in enumerator {
            if url.pathExtension == "swift" {
                files.append(url)
            }
        }
        return files
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return self.filter { seen.insert($0).inserted }
    }
}
