// Protocols/ASTExtensionProvider.swift
// Protocol for registering AST extensions

import SwiftSyntax

/// Protocol for providers that register AST extensions
/// Allows the framework to be extended with custom semantic operations
public protocol ASTExtensionProvider {
    /// Register AST extensions with the framework
    /// This method should be called during framework initialization
    static func registerExtensions()
}

/// Default registry for AST extension providers
public enum ASTExtensionRegistry {
    private nonisolated(unsafe) static var registeredProviders: [any ASTExtensionProvider.Type] = []

    /// Register a new AST extension provider
    /// - Parameter provider: The provider type to register
    public static func register(_ provider: any ASTExtensionProvider.Type) {
        registeredProviders.append(provider)
        provider.registerExtensions()
    }

    /// Get all registered providers
    /// - Returns: Array of registered provider types
    public static func getRegisteredProviders() -> [any ASTExtensionProvider.Type] {
        return registeredProviders
    }

    /// Initialize all registered providers
    /// Call this during framework startup
    public static func initializeAll() {
        for provider in registeredProviders {
            provider.registerExtensions()
        }
    }
}