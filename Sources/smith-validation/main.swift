import Foundation

/// Honest, AI-Optimized Smith Validation CLI
/// No custom formatting - just real architectural analysis

struct SmithValidationCLI {

    static func main() {
        let args = CommandLine.arguments

        guard args.count == 2 else {
            print(jsonError("Usage: smith-validation <project-path>"))
            return
        }

        let projectPath = args[1]

        // Validate project exists
        guard FileManager.default.fileExists(atPath: projectPath) else {
            print(jsonError("Project path does not exist: \(projectPath)"))
            return
        }

        // Run honest architectural analysis
        let analyzer = HonestAnalyzer()
        let result = analyzer.analyzeProject(at: projectPath)

        // Output AI-optimized JSON
        print(result.asJSON())
    }

    private static func jsonError(_ message: String) -> String {
        return """
{
  "error": "\(message)",
  "usage": "smith-validation <project-path>",
  "description": "Honest AI-optimized architectural validation tool"
}
"""
    }
}

SmithValidationCLI.main()
