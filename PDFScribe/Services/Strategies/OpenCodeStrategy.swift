import Foundation

@MainActor
protocol ToolCallHandler: AnyObject {
    func addToolCall(id: String, name: String, query: String, toolType: ToolCall.ToolType)
    func updateToolCall(id: String, status: ToolCall.Status)
    func updateToolCallTitle(id: String, title: String)
    func updateToolCallQuery(id: String, query: String)
}

class OpenCodeStrategy: AIProviderStrategy {
    private let binaryPath: String
    private let workingDirectory: String
    private var processManager: ProcessManager?
    private var rpcClient: JSONRPCClient?
    private var sessionId: String? // OpenCode's internal session ID (not used for our persistence)
    private var isInitialized = false
    private var availableModelsList: [AIModel] = []
    private var availableModesList: [AIMode] = []
    private var selectedModel: AIModel?
    private var selectedMode: AIMode?
    private var activeDelegationId: String? = nil  // Track when main agent delegates to sub-agent
    weak var toolCallHandler: ToolCallHandler?
    
    // Streaming support
    private var streamContinuation: AsyncThrowingStream<String, Error>.Continuation?
    private var streamCompletionTask: Task<Void, Never>? = nil
    
    init(binaryPath: String, workingDirectory: String? = nil) {
        self.binaryPath = binaryPath
        self.workingDirectory = workingDirectory ?? FileManager.default.homeDirectoryForCurrentUser.path
    }
    
    func connect() async throws {
        guard !isInitialized else {
            return
        }
        
        try await initialize()
        try await createSession()
    }
    
    func sendStream(message: String, context: AIContext) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task { @MainActor in
                self.streamContinuation = continuation
                
                do {
                    // Reset delegation state for new user turn
                    self.activeDelegationId = nil
                    
                    if !self.isInitialized {
                        try await self.initialize()
                        try await self.createSession()
                    }
                    
                    guard let sessionId = self.sessionId else {
                        self.streamContinuation?.finish(throwing: AIError.serverError("No active session"))
                        self.streamContinuation = nil
                        return
                    }
                    
                    try await self.sendPromptStreaming(sessionId: sessionId, message: message, context: context)
                } catch {
                    self.streamContinuation?.finish(throwing: error)
                    self.streamContinuation = nil
                }
            }
        }
    }
    
    @MainActor
    private func sendPromptStreaming(sessionId: String, message: String, context: AIContext) async throws {
        guard let rpcClient = rpcClient,
              let processManager = processManager else {
            throw AIError.serverError("Client not initialized")
        }
        
        var contentBlocks: [[String: Any]] = []
        
        // Add user message
        contentBlocks.append(["type": "text", "text": message])
        
        // Add current note file as resource if available
        if let fileURL = context.currentFile,
           let content = context.currentFileContent {
            let mimeType = fileURL.pathExtension == "md" ? "text/markdown" : "text/plain"
            contentBlocks.append([
                "type": "resource",
                "resource": [
                    "uri": fileURL.absoluteString,
                    "mimeType": mimeType,
                    "text": content
                ]
            ])
        }
        
        // Add referenced files as resources
        for fileURL in context.referencedFiles {
            if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
                let mimeType: String
                let ext = fileURL.pathExtension.lowercased()
                switch ext {
                case "md":
                    mimeType = "text/markdown"
                case "pdf":
                    mimeType = "application/pdf"
                default:
                    mimeType = "text/plain"
                }
                
                contentBlocks.append([
                    "type": "resource",
                    "resource": [
                        "uri": fileURL.absoluteString,
                        "mimeType": mimeType,
                        "text": content
                    ]
                ])
            }
        }
        
        // Add editor selection if available
        if let selection = context.selection, !selection.isEmpty {
            contentBlocks.append([
                "type": "text",
                "text": "Selected text from editor:\n\(selection)"
            ])
        }
        
        // Add PDF selection if available
        if let pdfSelection = context.pdfSelection, !pdfSelection.isEmpty {
            let pageInfo = context.pdfPage.map { " (Page \($0))" } ?? ""
            contentBlocks.append([
                "type": "text",
                "text": "Selected text from PDF\(pageInfo):\n\(pdfSelection)"
            ])
        }
        
        let params: [String: Any] = [
            "sessionId": sessionId,
            "prompt": contentBlocks
        ]
        
        let (requestId, requestData) = try rpcClient.createRequest(method: "session/prompt", params: params)
        try processManager.write(requestData)
        
        let response = try await rpcClient.awaitResponse(forRequestId: requestId)
        
        guard response.error == nil else {
            let errorMsg = response.error?.message ?? "Unknown error"
            throw AIError.serverError(errorMsg)
        }
        
        // Check if response contains stopReason
        if let result = response.result?.value as? [String: Any],
           let _ = result["stopReason"] as? String {
            // Schedule delayed stream completion to allow buffered notifications to be processed
            // The notification handler will cancel this if agent_message_complete arrives
            scheduleStreamCompletion(delay: 0.1) // 100ms buffer
        }
    }
    
    @MainActor
    private func scheduleStreamCompletion(delay: TimeInterval) {
        // Cancel any existing scheduled completion
        streamCompletionTask?.cancel()
        
        streamCompletionTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            
            finishStream()
        }
    }
    
    @MainActor
    private func finishStream() {
        streamCompletionTask?.cancel()
        streamCompletionTask = nil
        streamContinuation?.finish()
        streamContinuation = nil
    }
    
    private func initialize() async throws {
        let manager = ProcessManager(binaryPath: binaryPath, arguments: ["acp"])
        let client = JSONRPCClient()
        
        client.setNotificationHandler { [weak self] notification in
            self?.handleNotification(notification)
        }
        
        manager.onStdout = { [weak client] data in
            client?.handleIncomingData(data)
        }
        
        manager.onStderr = { _ in }
        
        try manager.launch()
        
        // Send initialize request
        let initParams: [String: Any] = [
            "protocolVersion": 1,
            "capabilities": [
                "prompts": [:],
                "sessions": [:]
            ],
            "clientInfo": [
                "name": "PDFScribe",
                "version": "1.0.0"
            ]
        ]
        
        let (requestId, requestData) = try client.createRequest(method: "initialize", params: initParams)
        try manager.write(requestData)
        
        let response = try await client.awaitResponse(forRequestId: requestId)
        
        guard response.error == nil else {
            let errorMsg = response.error?.message ?? "Unknown error"
            throw AIError.serverError("Initialization failed: \(errorMsg)")
        }
        
        self.processManager = manager
        self.rpcClient = client
        self.isInitialized = true
    }
    
    private func createSession() async throws {
        guard let rpcClient = rpcClient,
              let processManager = processManager else {
            throw AIError.serverError("Client not initialized")
        }
        
        let params: [String: Any] = [
            "cwd": workingDirectory,
            "mcpServers": []
        ]
        
        let (requestId, requestData) = try rpcClient.createRequest(method: "session/new", params: params)
        try processManager.write(requestData)
        
        let response = try await rpcClient.awaitResponse(forRequestId: requestId)
        
        guard response.error == nil else {
            let errorMsg = response.error?.message ?? "Unknown error"
            throw AIError.serverError("Failed to create session: \(errorMsg)")
        }
        
        guard let result = response.result?.value as? [String: Any],
              let sessionId = result["sessionId"] as? String else {
            throw AIError.serverError("Failed to get sessionId from response")
        }
        
        self.sessionId = sessionId
        
        // Parse available models (try both camelCase and snake_case)
        if let modelsData = result["models"] as? [String: Any] {
            let availableModels = (modelsData["availableModels"] as? [[String: Any]]) 
                ?? (modelsData["available_models"] as? [[String: Any]]) 
                ?? []
            
            self.availableModelsList = availableModels.compactMap { modelDict in
                let modelId = (modelDict["modelId"] as? String) ?? (modelDict["model_id"] as? String)
                let name = modelDict["name"] as? String
                guard let id = modelId, let displayName = name else { return nil }
                return AIModel(id: id, name: displayName, provider: .opencode)
            }
            
            let currentModelId = (modelsData["currentModelId"] as? String) ?? (modelsData["current_model_id"] as? String)
            if let currentId = currentModelId {
                self.selectedModel = availableModelsList.first { $0.id == currentId }
            }
        }
        
        // Parse available modes (try both camelCase and snake_case)
        if let modesData = result["modes"] as? [String: Any] {
            let availableModes = (modesData["availableModes"] as? [[String: Any]]) 
                ?? (modesData["available_modes"] as? [[String: Any]]) 
                ?? []
            
            self.availableModesList = availableModes.compactMap { modeDict in
                let modeId = modeDict["id"] as? String
                let name = modeDict["name"] as? String
                guard let id = modeId, let displayName = name else { return nil }
                let description = modeDict["description"] as? String
                return AIMode(id: id, name: displayName, description: description)
            }
            
            let currentModeId = (modesData["currentModeId"] as? String) ?? (modesData["current_mode_id"] as? String)
            if let currentId = currentModeId {
                self.selectedMode = availableModesList.first { $0.id == currentId }
            }
        }
        
        // Set default model to github-copilot/claude-sonnet-4.5 if available
        if let preferredModel = availableModelsList.first(where: { $0.id == "github-copilot/claude-sonnet-4.5" }) {
            try await selectModel(preferredModel)
        } else {
            if let firstModel = availableModelsList.first {
                try await selectModel(firstModel)
            }
        }
        
        // Set default mode to build if available
        if let preferredMode = availableModesList.first(where: { $0.id == "build" }) {
            try await selectMode(preferredMode)
        }
    }
    
    private func handleNotification(_ notification: JSONRPCNotification) {
        guard let params = notification.params?.value as? [String: Any],
              let update = params["update"] as? [String: Any],
              let sessionUpdate = update["sessionUpdate"] as? String else {
            return
        }
        
        guard notification.method == "session/update" else { 
            return 
        }
        
        switch sessionUpdate {
        case "agent_message_chunk":
            // Suppress text chunks while a delegation is active (sub-agent output)
            if activeDelegationId != nil {
                return
            }
            
            if let content = update["content"] as? [String: Any],
               let type = content["type"] as? String,
               type == "text",
               let text = content["text"] as? String {
                // Yield chunk to stream on MainActor
                Task { @MainActor in
                    self.streamContinuation?.yield(text)
                }
            }
        
        case "agent_message_complete", "turn_complete", "agent_turn_complete":
            // Agent finished generating response - finish the stream immediately
            // Cancel any scheduled delayed completion
            Task { @MainActor in
                self.finishStream()
            }
            
         case "tool_call":
            if let toolCallId = update["toolCallId"] as? String,
               let title = update["title"] as? String,
               let kind = update["kind"] as? String {
                
                // If a delegation is active, ignore all subsequent tool calls (they're from sub-agent)
                if activeDelegationId != nil {
                    return
                }
                
                // Infer tool type from name
                let toolType = ToolCall.inferToolType(from: title)
                
                // Check if this is a delegation (task tool)
                if title == "task" {
                    // Mark that we're now delegating
                    activeDelegationId = toolCallId
                    
                    // Extract subagent type for display
                    var subagentType = kind
                    if let rawInput = update["rawInput"] as? [String: Any],
                       let type = rawInput["subagent_type"] as? String {
                        subagentType = type
                    }
                    
                    Task { @MainActor in
                        toolCallHandler?.addToolCall(
                            id: toolCallId,
                            name: "task",
                            query: subagentType,
                            toolType: .delegate
                        )
                    }
                } else {
                    // Normal main agent tool call
                    // Extract query from rawInput based on tool type
                    var query = kind
                    if let rawInput = update["rawInput"] as? [String: Any] {
                        // Try common field names for the query
                        if let command = rawInput["command"] as? String {
                            query = command  // bash tool
                        } else if let filePath = rawInput["filePath"] as? String {
                            query = filePath  // read/write/edit tools
                        } else if let pattern = rawInput["pattern"] as? String {
                            query = pattern  // glob/grep tools
                        } else if let url = rawInput["url"] as? String {
                            query = url  // webfetch tool
                        } else if let description = rawInput["description"] as? String {
                            query = description  // fallback to description
                        }
                    }
                    
                    Task { @MainActor in
                        toolCallHandler?.addToolCall(
                            id: toolCallId,
                            name: title,
                            query: query,
                            toolType: toolType
                        )
                    }
                }
            }
            
        case "tool_call_update":
            if let toolCallId = update["toolCallId"] as? String,
               let statusString = update["status"] as? String {
                let status: ToolCall.Status = {
                    switch statusString {
                    case "completed": return .completed
                    case "failed": return .failed
                    case "cancelled": return .cancelled
                    default: return .running
                    }
                }()
                
                // Clear delegation state if this delegation completed
                if toolCallId == activeDelegationId {
                    if status == .completed || status == .failed || status == .cancelled {
                        activeDelegationId = nil
                    }
                }
                
                // Extract query and title updates from rawInput
                var updatedTitle: String? = nil
                var updatedQuery: String? = nil
                
                if let rawInput = update["rawInput"] as? [String: Any] {
                    // Check for subagent type (for delegation title)
                    if let subagentType = rawInput["subagent_type"] as? String {
                        updatedTitle = "Delegate: \(subagentType)"
                    }
                    
                    // Extract query from rawInput (same logic as tool_call)
                    if let command = rawInput["command"] as? String {
                        updatedQuery = command
                    } else if let filePath = rawInput["filePath"] as? String {
                        updatedQuery = filePath
                    } else if let pattern = rawInput["pattern"] as? String {
                        updatedQuery = pattern
                    } else if let url = rawInput["url"] as? String {
                        updatedQuery = url
                    } else if let description = rawInput["description"] as? String {
                        updatedQuery = description
                    }
                }
                
                Task { @MainActor in
                    // Update query first (if we have one)
                    if let query = updatedQuery {
                        toolCallHandler?.updateToolCallQuery(id: toolCallId, query: query)
                    }
                    // Update title if needed
                    if let newTitle = updatedTitle {
                        toolCallHandler?.updateToolCallTitle(id: toolCallId, title: newTitle)
                    }
                    // Update status
                    toolCallHandler?.updateToolCall(id: toolCallId, status: status)
                }
            }
            
        default:
            break
        }
    }
    
    func availableModels() -> [AIModel] {
        return availableModelsList
    }
    
    func availableModes() -> [AIMode] {
        return availableModesList
    }
    
    func currentModel() -> AIModel? {
        return selectedModel
    }
    
    func currentMode() -> AIMode? {
        return selectedMode
    }
    
    func selectModel(_ model: AIModel) async throws {
        // If no session exists yet, just update local state
        // The model will be used when session is created
        guard let sessionId = sessionId else {
            selectedModel = model
            return
        }
        
        guard let rpcClient = rpcClient,
              let processManager = processManager else {
            throw AIError.serverError("Client not initialized")
        }
        
        let oldModel = selectedModel
        selectedModel = model
        
        let params: [String: Any] = [
            "sessionId": sessionId,
            "modelId": model.id
        ]
        
        do {
            let (requestId, requestData) = try rpcClient.createRequest(method: "session/set_model", params: params)
            try processManager.write(requestData)
            
            let response = try await rpcClient.awaitResponse(forRequestId: requestId)
            
            if let error = response.error {
                selectedModel = oldModel
                throw AIError.serverError("Failed to set model: \(error.message)")
            }
        } catch {
            selectedModel = oldModel
            throw error
        }
    }
    
    func selectMode(_ mode: AIMode) async throws {
        // If no session exists yet, just update local state
        // The mode will be used when session is created
        guard let sessionId = sessionId else {
            selectedMode = mode
            return
        }
        
        guard let rpcClient = rpcClient,
              let processManager = processManager else {
            throw AIError.serverError("Client not initialized")
        }
        
        let oldMode = selectedMode
        selectedMode = mode
        
        let params: [String: Any] = [
            "sessionId": sessionId,
            "modeId": mode.id
        ]
        
        do {
            let (requestId, requestData) = try rpcClient.createRequest(method: "session/set_mode", params: params)
            try processManager.write(requestData)
            
            let response = try await rpcClient.awaitResponse(forRequestId: requestId)
            
            if let error = response.error {
                selectedMode = oldMode
                throw AIError.serverError("Failed to set mode: \(error.message)")
            }
        } catch {
            selectedMode = oldMode
            throw error
        }
    }
    
    deinit {
        processManager?.terminate()
    }
}
