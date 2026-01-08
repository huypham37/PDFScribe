import Combine
import Foundation

enum AIProvider: String, CaseIterable {
    case openai = "OpenAI"
    case anthropic = "Anthropic"
    case opencode = "OpenCode"
}

enum AIError: Error {
    case invalidAPIKey
    case invalidResponse
    case networkError(Error)
    case serverError(String)
}

struct AIMessage: Codable, Identifiable {
    let id: String
    let role: String
    let content: String
    
    init(role: String, content: String) {
        self.id = UUID().uuidString
        self.role = role
        self.content = content
    }
}

@MainActor
class AIService: ObservableObject {
    @Published var apiKey: String = ""
    @Published var provider: AIProvider = .openai
    @Published var opencodePath: String = "/usr/local/bin/opencode"
    
    private var currentStrategy: AIProviderStrategy?
    
    init() {
        loadAPIKey()
        updateStrategy()
    }
    
    func sendMessage(_ message: String, context: [AIMessage]) async throws -> String {
        guard let strategy = currentStrategy else {
            throw AIError.invalidAPIKey
        }
        
        return try await strategy.send(message: message, context: context)
    }
    
    private func updateStrategy() {
        switch provider {
        case .openai:
            currentStrategy = OpenAIStrategy(apiKey: apiKey)
        case .anthropic:
            currentStrategy = AnthropicStrategy(apiKey: apiKey)
        case .opencode:
            currentStrategy = OpenCodeStrategy(binaryPath: opencodePath)
        }
    }
    
    func saveAPIKey() {
        UserDefaults.standard.set(apiKey, forKey: "ai_api_key")
        UserDefaults.standard.set(provider.rawValue, forKey: "ai_provider")
        UserDefaults.standard.set(opencodePath, forKey: "opencode_path")
        updateStrategy()
    }
    
    private func loadAPIKey() {
        apiKey = UserDefaults.standard.string(forKey: "ai_api_key") ?? ""
        opencodePath = UserDefaults.standard.string(forKey: "opencode_path") ?? "/usr/local/bin/opencode"
        if let providerString = UserDefaults.standard.string(forKey: "ai_provider"),
           let savedProvider = AIProvider(rawValue: providerString) {
            provider = savedProvider
        }
    }
}
