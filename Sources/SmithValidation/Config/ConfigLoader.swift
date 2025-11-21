// Config/ConfigLoader.swift
// Loads smith-validation configuration from a PKL file using pkl-swift runtime.

import Foundation
import Dispatch
import PklSwift

public enum ConfigLoaderError: LocalizedError {
    case decodeFailed(String)
    case evaluationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .decodeFailed(let message):
            return "Failed to decode PKL output as JSON: \(message)"
        case .evaluationFailed(let message):
            return "Failed to evaluate PKL config: \(message)"
        }
    }
}

public struct ConfigLoader {
    /// Evaluate the given PKL file and decode into `SmithValidationConfig`.
    /// - Parameter path: Path to the PKL config file.
    public init() {}

    public func load(at path: String) throws -> SmithValidationConfig {
        let absolute = URL(fileURLWithPath: path).standardizedFileURL

        do {
            let config: SmithValidationConfig = try runBlocking {
                try await PklSwift.withEvaluator { evaluator in
                    let value = try await evaluator.evaluateModule(
                        source: .path(absolute.path),
                        as: SmithValidationConfig.self
                    )
                    return value
                }
            }
            return config
        } catch {
            throw ConfigLoaderError.evaluationFailed(error.localizedDescription)
        }
    }

    // MARK: - Helper

    /// Run an async block synchronously (simple semaphore wrapper).
    private func runBlocking<T>(_ block: @escaping () async throws -> T) throws -> T {
        let group = DispatchGroup()
        var result: Result<T, Error>!
        group.enter()
        Task {
            do {
                let value = try await block()
                result = .success(value)
            } catch {
                result = .failure(error)
            }
            group.leave()
        }
        group.wait()
        return try result.get()
    }
}
