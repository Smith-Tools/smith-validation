// Models/SourceFileContext.swift
// File context for tracking source file information during validation

import Foundation
import SwiftSyntax

/// Context for a source file being validated
public struct SourceFileContext {
    public let path: String
    public let url: URL
    public let syntax: SourceFileSyntax

    public init(path: String, url: URL, syntax: SourceFileSyntax) {
        self.path = path
        self.url = url
        self.syntax = syntax
    }

    public init(url: URL, syntax: SourceFileSyntax) {
        self.path = url.path
        self.url = url
        self.syntax = syntax
    }

    /// Get filename without full path
    public var filename: String {
        return URL(fileURLWithPath: path).lastPathComponent
    }

    /// Get relative path from current directory
    public var relativePath: String {
        let currentPath = FileManager.default.currentDirectoryPath
        return path.hasPrefix(currentPath) ?
            String(path.dropFirst(currentPath.count + 1)) : path
    }
}