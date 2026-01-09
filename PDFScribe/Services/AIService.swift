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
    @Published var availableModels: [AIModel] = []
    @Published var availableModes: [AIMode] = []
    @Published var currentModel: AIModel?
    @Published var currentMode: AIMode?
    @Published var isConnecting: Bool = false
    
    private var currentStrategy: AIProviderStrategy?
    weak var appViewModel: AppViewModel?
    weak var toolCallHandler: ToolCallHandler?
    weak var fileService: FileService?
    
    init() {
        loadAPIKey()
        updateStrategy()
    }
    
    func setToolCallHandler(_ handler: ToolCallHandler) {
        self.toolCallHandler = handler
        if let opencodeStrategy = currentStrategy as? OpenCodeStrategy {
            opencodeStrategy.toolCallHandler = handler
        }
    }
    
    func sendMessage(_ message: String, context: AIContext) async throws -> String {
        guard let strategy = currentStrategy else {
            throw AIError.invalidAPIKey
        }
        
        let response = try await strategy.send(message: message, context: context)
        
        // Update session's last active time
        if let sessionId = (strategy as? OpenCodeStrategy)?.getSessionId(),
           let projectURL = appViewModel?.projectRootURL,
           let fileService = fileService {
            
            var history = fileService.loadChatHistory()
            if let index = history.sessions.firstIndex(where: { $0.id == sessionId }) {
                history.sessions[index].lastActive = Date()
                fileService.saveChatHistory(history)
            }
        }
        
        // Update current model/mode in case they changed during session creation
        updateAvailableModelsAndModes()
        
        return response
    }
    
    private func updateStrategy() {
        switch provider {
        case .openai:
            currentStrategy = OpenAIStrategy(apiKey: apiKey)
        case .anthropic:
            currentStrategy = AnthropicStrategy(apiKey: apiKey)
        case .opencode:
            let workingDir = appViewModel?.projectRootURL?.path
            
            // Try to load existing session ID for this project
            var initialSessionId: String? = nil
            if let projectURL = appViewModel?.projectRootURL, let fileService = fileService {
                initialSessionId = fileService.getMostRecentSessionId(for: projectURL.path)
                print("Loaded session ID: \(initialSessionId ?? "none") for project: \(projectURL.lastPathComponent)")
            }
            
            let strategy = OpenCodeStrategy(binaryPath: opencodePath, workingDirectory: workingDir, initialSessionId: initialSessionId)
            strategy.toolCallHandler = toolCallHandler
            currentStrategy = strategy
            
            // Proactively connect to OpenCode when switching to this provider
            Task { @MainActor in
                isConnecting = true
                do {
                    try await strategy.connect()
                    
                    // Save the session ID (whether it was resumed or newly created)
                    if let sessionId = strategy.getSessionId(),
                       let projectURL = self.appViewModel?.projectRootURL,
                       let fileService = self.fileService {
                        
                        print("💾 Saving session: \(sessionId) for project: \(projectURL.path)")
                        
                        let session = ChatSession(
                            id: sessionId,
                            projectPath: projectURL.path,
                            title: "New Session", // Will be updated by auto-naming later
                            createdAt: Date(),
                            lastActive: Date()
                        )
                        fileService.addOrUpdateSession(session)
                        print("✅ Session saved successfully")
                        
                        // Verify it was saved
                        let history = fileService.loadChatHistory()
                        print("📚 History now contains \(history.sessions.count) session(s)")
                    } else {
                        print("⚠️ Failed to save session - sessionId: \(strategy.getSessionId() ?? "nil"), projectURL: \(self.appViewModel?.projectRootURL?.path ?? "nil"), fileService: \(self.fileService != nil ? "exists" : "nil")")
                    }
                    
                    updateAvailableModelsAndModes()
                } catch {
                    print("Failed to proactively connect to OpenCode: \(error)")
                }
                isConnecting = false
            }
        }
        
        updateAvailableModelsAndModes()
    }
    
    private func updateAvailableModelsAndModes() {
        guard let strategy = currentStrategy else {
            availableModels = []
            availableModes = []
            currentModel = nil
            currentMode = nil
            return
        }
        
        availableModels = strategy.availableModels()
        availableModes = strategy.availableModes()
        currentModel = strategy.currentModel()
        currentMode = strategy.currentMode()
    }
    
    func selectModel(_ model: AIModel) async throws {
        guard let strategy = currentStrategy else {
            throw AIError.invalidAPIKey
        }
        
        try await strategy.selectModel(model)
        self.currentModel = model
    }
    
    func selectMode(_ mode: AIMode) async throws {
        guard let strategy = currentStrategy else {
            throw AIError.invalidAPIKey
        }
        
        try await strategy.selectMode(mode)
        self.currentMode = mode
    }
    
    func saveAPIKey() {
        let oldProvider = AIProvider(rawValue: UserDefaults.standard.string(forKey: "ai_provider") ?? "") ?? .openai
        let oldPath = UserDefaults.standard.string(forKey: "opencode_path") ?? "/usr/local/bin/opencode"
        
        UserDefaults.standard.set(apiKey, forKey: "ai_api_key")
        UserDefaults.standard.set(provider.rawValue, forKey: "ai_provider")
        UserDefaults.standard.set(opencodePath, forKey: "opencode_path")
        
        // Only recreate strategy if provider or path changed
        if oldProvider != provider || oldPath != opencodePath {
            updateStrategy()
        }
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
