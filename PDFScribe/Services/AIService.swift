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
    
    // Current session ID (our own UUID, not provider-specific)
    private(set) var currentSessionId: String?
    
    init() {
        loadAPIKey()
        updateStrategy()
    }
    
    func getCurrentSessionId() -> String? {
        return currentSessionId
    }
    
    func setCurrentSessionId(_ sessionId: String?) {
        self.currentSessionId = sessionId
    }
    
    /// Call this when the project root URL becomes available
    func onProjectLoaded() {
        print("📱 AIService.onProjectLoaded() called")
        loadOrCreateSession()
    }
    
    func setToolCallHandler(_ handler: ToolCallHandler) {
        self.toolCallHandler = handler
        if let opencodeStrategy = currentStrategy as? OpenCodeStrategy {
            opencodeStrategy.toolCallHandler = handler
        }
    }
    
    func sendMessageStream(_ message: String, context: AIContext, saveToHistory: Bool = true) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task { @MainActor in
                guard let strategy = self.currentStrategy else {
                    continuation.finish(throwing: AIError.invalidAPIKey)
                    return
                }
                
                // Store user message
                if saveToHistory, let sessionId = self.currentSessionId, let fileService = self.fileService {
                    let userMsg = StoredMessage(role: "user", content: message)
                    fileService.addMessageToSession(sessionId: sessionId, message: userMsg)
                }
                
                var fullResponse = ""
                let stream = strategy.sendStream(message: message, context: context)
                
                do {
                    for try await chunk in stream {
                        fullResponse += chunk
                        continuation.yield(chunk)
                    }
                    
                    // Store assistant response after completion
                    if saveToHistory, let sessionId = self.currentSessionId, let fileService = self.fileService {
                        let assistantMsg = StoredMessage(role: "assistant", content: fullResponse)
                        fileService.addMessageToSession(sessionId: sessionId, message: assistantMsg)
                    }
                    
                    self.updateAvailableModelsAndModes()
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func sendMessage(_ message: String, context: AIContext, saveToHistory: Bool = true) async throws -> String {
        guard let strategy = currentStrategy else {
            throw AIError.invalidAPIKey
        }
        
        // Store user message (only if saveToHistory is true)
        if saveToHistory, let sessionId = currentSessionId, let fileService = fileService {
            let userMsg = StoredMessage(role: "user", content: message)
            fileService.addMessageToSession(sessionId: sessionId, message: userMsg)
        }
        
        // Use streaming internally but collect full response
        var fullResponse = ""
        let stream = strategy.sendStream(message: message, context: context)
        
        for try await chunk in stream {
            fullResponse += chunk
        }
        
        // Store assistant response (only if saveToHistory is true)
        if saveToHistory, let sessionId = currentSessionId, let fileService = fileService {
            let assistantMsg = StoredMessage(role: "assistant", content: fullResponse)
            fileService.addMessageToSession(sessionId: sessionId, message: assistantMsg)
        }
        
        // Update current model/mode in case they changed during session creation
        updateAvailableModelsAndModes()
        
        return fullResponse
    }
    
    private func updateStrategy() {
        print("📱 AIService.updateStrategy() called - provider: \(provider.rawValue)")
        
        switch provider {
        case .openai:
            currentStrategy = OpenAIStrategy(apiKey: apiKey)
        case .anthropic:
            currentStrategy = AnthropicStrategy(apiKey: apiKey)
        case .opencode:
            let workingDir = appViewModel?.projectRootURL?.path
            print("📱 Creating OpenCodeStrategy - workingDir: \(workingDir ?? "nil")")
            let strategy = OpenCodeStrategy(binaryPath: opencodePath, workingDirectory: workingDir)
            strategy.toolCallHandler = toolCallHandler
            currentStrategy = strategy
            
            // Proactively connect to OpenCode when switching to this provider
            Task { @MainActor in
                isConnecting = true
                do {
                    print("🔌 Attempting to connect to OpenCode...")
                    try await strategy.connect()
                    print("✅ OpenCode connected successfully")
                    updateAvailableModelsAndModes()
                } catch {
                    print("❌ Failed to proactively connect to OpenCode: \(error)")
                }
                isConnecting = false
            }
        }
        
        // Don't call loadOrCreateSession() here - it's called when project is set
        updateAvailableModelsAndModes()
    }
    
    private func loadOrCreateSession() {
        print("📱 loadOrCreateSession() called")
        print("   - appViewModel?.projectRootURL: \(appViewModel?.projectRootURL?.path ?? "nil")")
        print("   - fileService: \(fileService != nil ? "exists" : "nil")")
        
        guard let projectURL = appViewModel?.projectRootURL,
              let fileService = fileService else {
            print("⚠️ Cannot load/create session: projectURL=\(appViewModel?.projectRootURL?.path ?? "nil"), fileService=\(fileService != nil ? "exists" : "nil")")
            return
        }
        
        print("📱 Attempting to load existing session for: \(projectURL.path)")
        
        // Try to load existing session
        if let existingSession = fileService.getMostRecentSession(for: projectURL.path) {
            currentSessionId = existingSession.id
            print("📂 Loaded existing session: \(existingSession.id) with \(existingSession.messages.count) messages")
        } else {
            // Create new session
            let newSessionId = UUID().uuidString
            print("✨ Creating new session: \(newSessionId)")
            let newSession = ChatSession(
                id: newSessionId,
                projectPath: projectURL.path,
                title: "New Session",
                messages: [],
                provider: provider.rawValue.lowercased()
            )
            print("💾 Calling fileService.addOrUpdateSession()")
            fileService.addOrUpdateSession(newSession)
            currentSessionId = newSessionId
            print("✅ New session created and saved: \(newSessionId)")
        }
    }
    
    func createNewSession() {
        guard let projectURL = appViewModel?.projectRootURL,
              let fileService = fileService else {
            return
        }
        
        let newSessionId = UUID().uuidString
        let newSession = ChatSession(
            id: newSessionId,
            projectPath: projectURL.path,
            title: "New Session",
            messages: [],
            provider: provider.rawValue.lowercased()
        )
        fileService.addOrUpdateSession(newSession)
        currentSessionId = newSessionId
        print("✨ Created new session: \(newSessionId)")
    }
    
    func loadSession(_ session: ChatSession) -> [StoredMessage] {
        currentSessionId = session.id
        return session.messages
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
