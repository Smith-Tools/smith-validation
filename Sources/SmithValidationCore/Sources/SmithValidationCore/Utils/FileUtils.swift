// Utils/FileUtils.swift
// Shared file system utilities for architectural validation

import Foundation
import SwiftSyntax

/// Shared file system utilities used across all validation rules
public enum FileUtils {

    /// Find all Swift files in a directory recursively
    /// - Parameter directory: Directory URL to search
    /// - Returns: Array of Swift file URLs
    /// - Throws: File system errors
    public static func findSwiftFiles(
        in directory: URL,
        includeGlobs: [String] = ["**/*.swift"],
        excludeGlobs: [String] = []
    ) throws -> [URL] {
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
                // If the directory itself matches an exclude glob, prune it to avoid traversing huge artifacts.
                let dirPath = fileURL.path + "/" // ensure trailing slash for glob match
                if matches(globs: excludeGlobs, path: dirPath) {
                    directoryEnumerator?.skipDescendants()
                    continue
                }
                // Recursively search subdirectories
                swiftFiles.append(contentsOf: try findSwiftFiles(in: fileURL, includeGlobs: includeGlobs, excludeGlobs: excludeGlobs))
            } else if fileURL.pathExtension == "swift" {
                let path = fileURL.path
                if matches(globs: includeGlobs, path: path) && !matches(globs: excludeGlobs, path: path) {
                    swiftFiles.append(fileURL)
                }
            }
        }

        return swiftFiles
    }

    private static func matches(globs: [String], path: String) -> Bool {
        guard !globs.isEmpty else { return true }
        return globs.contains { glob in
            path.range(of: globToRegex(glob), options: .regularExpression) != nil
        }
    }

    private static func globToRegex(_ glob: String) -> String {
        // Very simple glob->regex for ** and *
        var regex = "^"
        var i = glob.startIndex
        while i < glob.endIndex {
            let ch = glob[i]
            if ch == "*" {
                let next = glob.index(after: i)
                if next < glob.endIndex && glob[next] == "*" {
                    regex.append(".*")
                    i = glob.index(after: next)
                    continue
                } else {
                    regex.append("[^/]*")
                }
            } else if ch == "." {
                regex.append("\\.")
            } else if ch == "/" {
                regex.append("/")
            } else {
                regex.append(ch)
            }
            i = glob.index(after: i)
        }
        regex.append("$")
        return regex
    }
}

/// Validation errors that can occur during file processing
public enum ValidationError: Error, LocalizedError {
    case directoryNotFound(URL)
    case fileNotFound(URL)
    case parsingError(Error)
    case invalidConfiguration(String)

    public var errorDescription: String? {
        switch self {
        case .directoryNotFound(let url):
            return "Directory not found: \(url.path)"
        case .fileNotFound(let url):
            return "File not found: \(url.path)"
        case .parsingError(let error):
            return "Parsing error: \(error.localizedDescription)"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        }
    }
}
