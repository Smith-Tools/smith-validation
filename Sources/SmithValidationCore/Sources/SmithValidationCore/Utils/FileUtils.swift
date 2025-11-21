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
    public static func findSwiftFiles(in directory: URL) throws -> [URL] {
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