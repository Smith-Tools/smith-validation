// Engine/PerformanceOptimizer.swift
// Performance optimization and caching for validation engine

import Foundation
import SmithValidationCore
import SwiftSyntax

/// Performance optimization utilities for validation operations
public class PerformanceOptimizer {

    /// Cache for parsed AST results
    private var astCache: [String: CachedAST] = [:]
    private let maxCacheSize: Int
    private let cacheTimeout: TimeInterval

    /// Statistics tracking
    private var cacheHits = 0
    private var cacheMisses = 0
    private var totalParsingTime: TimeInterval = 0

    public init(maxCacheSize: Int = 1000, cacheTimeout: TimeInterval = 300.0) {
        self.maxCacheSize = maxCacheSize
        self.cacheTimeout = cacheTimeout
    }

    /// Get cached AST or parse and cache new one
    /// - Parameter filePath: Path to the Swift file
    /// - Returns: Cached AST if available, nil otherwise
    public func getCachedAST(for filePath: String) -> SourceFileSyntax? {
        if let cached = astCache[filePath] {
            // Check if cache is still valid
            if Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
                cacheHits += 1
                return cached.syntax
            } else {
                // Cache expired, remove it
                astCache.removeValue(forKey: filePath)
            }
        }

        cacheMisses += 1
        return nil
    }

    /// Cache an AST for future use
    /// - Parameters:
    ///   - syntax: Parsed AST to cache
    ///   - filePath: Path to the source file
    public func cacheAST(_ syntax: SourceFileSyntax, for filePath: String) {
        // Remove oldest entries if cache is full
        if astCache.count >= maxCacheSize {
            evictOldestCacheEntries()
        }

        astCache[filePath] = CachedAST(
            syntax: syntax,
            timestamp: Date(),
            fileSize: getFileSize(filePath)
        )
    }

    /// Check if file has been modified since caching
    /// - Parameters:
    ///   - filePath: Path to check
    ///   - cachedAST: Previously cached AST
    /// - Returns: True if file is unchanged, false if modified
    public func isFileUnchanged(for filePath: String, cachedAST: CachedAST) -> Bool {
        let currentFileSize = getFileSize(filePath)
        return currentFileSize == cachedAST.fileSize
    }

    /// Get performance statistics
    /// - Returns: Performance statistics
    public func getStatistics() -> PerformanceStatistics {
        let cacheRequests = cacheHits + cacheMisses
        let hitRate = cacheRequests > 0 ? Double(cacheHits) / Double(cacheRequests) : 0.0

        return PerformanceStatistics(
            cacheHits: cacheHits,
            cacheMisses: cacheMisses,
            hitRate: hitRate,
            cacheSize: astCache.count,
            maxCacheSize: maxCacheSize,
            totalParsingTime: totalParsingTime
        )
    }

    /// Clear all caches
    public func clearCache() {
        astCache.removeAll()
        cacheHits = 0
        cacheMisses = 0
        totalParsingTime = 0
    }

    /// Time a validation operation for performance tracking
    /// - Parameter operation: Operation to time
    /// - Returns: Result of the operation and execution time
    public func timeOperation<T>(_ operation: () throws -> T) rethrows -> (result: T, duration: TimeInterval) {
        let startTime = Date()
        let result = try operation()
        let duration = Date().timeIntervalSince(startTime)
        totalParsingTime += duration
        return (result, duration)
    }

    // MARK: - Private Methods

    /// Get file size for cache validation
    /// - Parameter filePath: Path to the file
    /// - Returns: File size in bytes, 0 if file doesn't exist
    private func getFileSize(_ filePath: String) -> Int {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
            return attributes[.size] as? Int ?? 0
        } catch {
            return 0
        }
    }

    /// Evict oldest cache entries to make room for new ones
    private func evictOldestCacheEntries() {
        // Sort by timestamp and remove oldest entries
        let sortedEntries = astCache.sorted { $0.value.timestamp < $1.value.timestamp }
        let entriesToRemove = sortedEntries.prefix(maxCacheSize / 4) // Remove 25% of cache

        for (key, _) in entriesToRemove {
            astCache.removeValue(forKey: key)
        }
    }
}

/// Cached AST with metadata
public struct CachedAST {
    public let syntax: SourceFileSyntax
    public let timestamp: Date
    public let fileSize: Int

    public init(syntax: SourceFileSyntax, timestamp: Date, fileSize: Int) {
        self.syntax = syntax
        self.timestamp = timestamp
        self.fileSize = fileSize
    }
}

/// Performance statistics
public struct PerformanceStatistics {
    public let cacheHits: Int
    public let cacheMisses: Int
    public let hitRate: Double
    public let cacheSize: Int
    public let maxCacheSize: Int
    public let totalParsingTime: TimeInterval

    public init(
        cacheHits: Int,
        cacheMisses: Int,
        hitRate: Double,
        cacheSize: Int,
        maxCacheSize: Int,
        totalParsingTime: TimeInterval
    ) {
        self.cacheHits = cacheHits
        self.cacheMisses = cacheMisses
        self.hitRate = hitRate
        self.cacheSize = cacheSize
        self.maxCacheSize = maxCacheSize
        self.totalParsingTime = totalParsingTime
    }

    /// Generate human-readable performance report
    public var description: String {
        return """
        📊 Performance Statistics:
        Cache Hit Rate: \(String(format: "%.1f%%", hitRate * 100))
        Cache Hits: \(cacheHits), Cache Misses: \(cacheMisses)
        Cache Size: \(cacheSize) / \(maxCacheSize)
        Total Parsing Time: \(String(format: "%.3f", totalParsingTime))s
        """
    }
}