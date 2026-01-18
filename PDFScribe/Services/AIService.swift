import Combine
import Foundation

enum AIProvider: String, CaseIterable {
    case openai = "OpenAI"
    case anthropic = "Anthropic"
    case opencode = "OpenCode"
    case mock = "Mock"
}

enum TypingSpeed: Int, CaseIterable {
    case fast = 5       // 5ms → 200 chars/s (ChatGPT/GetStream standard)
    case normal = 10    // 10ms → 100 chars/s (smooth, balanced)
    case relaxed = 20   // 20ms → 50 chars/s (slower, more readable)
    
    var nanoseconds: UInt64 {
        UInt64(self.rawValue) * 1_000_000 // Convert ms to nanoseconds
    }
    
    var displayName: String {
        switch self {
        case .fast: return "Fast"
        case .normal: return "Normal"
        case .relaxed: return "Relaxed"
        }
    }
}

enum FadeInSpeed: Double, CaseIterable {
    case instant = 0.0   // No animation
    case fast = 0.1      // Quick fade
    case normal = 0.3    // Balanced
    case smooth = 0.5    // Slow, smooth
    
    var displayName: String {
        switch self {
        case .instant: return "Instant"
        case .fast: return "Fast"
        case .normal: return "Normal"
        case .smooth: return "Smooth"
        }
    }
}

enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case failed
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
    @Published var typingSpeed: TypingSpeed = .normal
    @Published var fadeInSpeed: FadeInSpeed = .normal
    @Published var availableModels: [AIModel] = []
    @Published var availableModes: [AIMode] = []
    @Published var currentModel: AIModel?
    @Published var currentMode: AIMode?
    @Published var connectionState: ConnectionState = .disconnected
    
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
        switch provider {
        case .openai:
            currentStrategy = OpenAIStrategy(apiKey: apiKey)
        case .anthropic:
            currentStrategy = AnthropicStrategy(apiKey: apiKey)
        case .opencode:
            let workingDir = appViewModel?.projectRootURL?.path
            let strategy = OpenCodeStrategy(binaryPath: opencodePath, workingDirectory: workingDir)
            strategy.toolCallHandler = toolCallHandler
            currentStrategy = strategy
            
            // Proactively connect to OpenCode when switching to this provider
            Task { @MainActor in
                connectionState = .connecting
                do {
                    try await strategy.connect()
                    updateAvailableModelsAndModes()
                    connectionState = .connected
                } catch {
                    connectionState = .failed
                }
            }
        case .mock:
            currentStrategy = MockAIStrategy(typingSpeed: typingSpeed)
            connectionState = .connected
        }
        
        // Don't call loadOrCreateSession() here - it's called when project is set
        updateAvailableModelsAndModes()
    }
    
    private func loadOrCreateSession() {
        guard let projectURL = appViewModel?.projectRootURL,
              let fileService = fileService else {
            return
        }
        
        // Try to load existing session
        if let existingSession = fileService.getMostRecentSession(for: projectURL.path) {
            currentSessionId = existingSession.id
        } else {
            // Create new session
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
        UserDefaults.standard.set(typingSpeed.rawValue, forKey: "typing_speed")
        
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
        let speedRawValue = UserDefaults.standard.integer(forKey: "typing_speed")
        if speedRawValue != 0, let savedSpeed = TypingSpeed(rawValue: speedRawValue) {
            typingSpeed = savedSpeed
        }
    }
}
