import Foundation

/// OpenCode configuration file structure
struct OpenCodeConfig: Codable {
    let agents: [String: OpenCodeAgent]?
    
    struct OpenCodeAgent: Codable {
        let name: String
        let mode: String
        let description: String?
        let instructions: String?
        let model: String?
    }
}

/// Helper to load OpenCode configuration
class OpenCodeConfigLoader {
    static let shared = OpenCodeConfigLoader()
    
    private let configPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".config/opencode/opencode.json")
    
    /// Load all primary agents from OpenCode config
    func loadPrimaryAgents() -> [AgentMode] {
        // Start with default primary agents
        var agents: [AgentMode] = [.build, .plan, .explore]
        
        // Try to load custom primary agents from config
        guard FileManager.default.fileExists(atPath: configPath.path) else {
            print("⚠️ OpenCode config not found at \(configPath.path)")
            return agents
        }
        
        do {
            let data = try Data(contentsOf: configPath)
            let config = try JSONDecoder().decode(OpenCodeConfig.self, from: data)
            
            // Extract custom primary agents
            if let configAgents = config.agents {
                for (id, agent) in configAgents {
                    // Only include primary agents (not subagents)
                    if agent.mode == "primary" {
                        let customMode = AgentMode.custom(
                            id: id,
                            name: agent.name,
                            description: agent.description ?? "Custom agent"
                        )
                        agents.append(customMode)
                        print("✅ Loaded custom primary agent: \(agent.name)")
                    }
                }
            }
        } catch {
            print("❌ Failed to load OpenCode config: \(error)")
        }
        
        return agents
    }
}
