// Config/ConfigModels.swift
// Typed models for smith-validation PKL configuration

import Foundation

/// Root configuration decoded from PKL (via JSON output).
public struct SmithValidationConfig: Decodable {
    public var bundles: [BundleConfig] = []
    public var rule: RuleConfig = RuleConfig()
}

/// Describes a rule bundle (SwiftPM product) that can be loaded by the engine.
public struct BundleConfig: Decodable {
    /// Friendly name for logging.
    public var name: String

    /// Path to the SwiftPM package root containing the bundle product.
    /// Can be absolute or relative to the current working directory.
    public var path: String

    /// SwiftPM product name that builds the bundle dynamic library.
    public var product: String

    /// Whether this bundle should be considered.
    public var enabled: Bool? = true
}

/// Optional rule-level config tweaks.
public struct RuleConfig: Decodable {
    /// Glob patterns to include when scanning source files.
    public var includeGlobs: [String] = ["**/*.swift"]
    /// Glob patterns to exclude.
    public var excludeGlobs: [String] = ["Tests/**"]
}
