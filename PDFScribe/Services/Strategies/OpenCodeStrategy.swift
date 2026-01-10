import Foundation

@MainActor
protocol ToolCallHandler: AnyObject {
    func addToolCall(id: String, title: String)
    func updateToolCall(id: String, status: ToolCall.Status)
    func updateToolCallTitle(id: String, title: String)
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
    
    init(binaryPath: String, workingDirectory: String? = nil) {
        self.binaryPath = binaryPath
        self.workingDirectory = workingDirectory ?? FileManager.default.homeDirectoryForCurrentUser.path
    }
    
    func connect() async throws {
        guard !isInitialized else {
            print("OpenCode already connected")
            return
        }
        
        print("Proactively connecting to OpenCode...")
        try await initialize()
        print("Creating session with default model/mode...")
        try await createSession()
        print("OpenCode connection established - sessionId: \(sessionId ?? "nil")")
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
        
        print("[ACP] Waiting for session/prompt response...")
        let response = try await rpcClient.awaitResponse(forRequestId: requestId)
        print("[ACP] Got session/prompt response: \(response)")
        
        guard response.error == nil else {
            let errorMsg = response.error?.message ?? "Unknown error"
            throw AIError.serverError(errorMsg)
        }
        
        // Finish the stream when response completes
        print("[ACP] Finishing stream")
        self.streamContinuation?.finish()
        self.streamContinuation = nil
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
        
        // Debug: print the full response to see structure
        if let jsonData = try? JSONSerialization.data(withJSONObject: result, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("OpenCode session/new response: \(jsonString)")
        }
        
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
        
        print("[DEFAULT] Available models: \(availableModelsList.map { $0.id }.joined(separator: ", "))")
        print("[DEFAULT] Available modes: \(availableModesList.map { $0.id }.joined(separator: ", "))")
        
        // Set default model to github-copilot/gemini-3-pro-preview if available
        if let preferredModel = availableModelsList.first(where: { $0.id == "github-copilot/gemini-3-pro-preview" }) {
            print("[DEFAULT] Setting default model to github-copilot/gemini-3-pro-preview")
            try await selectModel(preferredModel)
            print("[DEFAULT] Model set successfully - current: \(selectedModel?.id ?? "none")")
        } else {
            print("[DEFAULT] github-copilot/gemini-3-pro-preview not available in models list")
        }
        
        // Set default mode to research-leader if available
        if let preferredMode = availableModesList.first(where: { $0.id == "research-leader" }) {
            print("[DEFAULT] Setting default mode to research-leader")
            try await selectMode(preferredMode)
            print("[DEFAULT] Mode set successfully - current: \(selectedMode?.id ?? "none")")
        } else {
            print("[DEFAULT] research-leader not available in modes list")
        }
    }
    
    private func handleNotification(_ notification: JSONRPCNotification) {
        guard let params = notification.params?.value as? [String: Any],
              let update = params["update"] as? [String: Any],
              let sessionUpdate = update["sessionUpdate"] as? String else {
            return
        }
        
        guard notification.method == "session/update" else { return }
        
        // Debug: print all sessionUpdate types
        print("[ACP] sessionUpdate: \(sessionUpdate)")
        
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
            // Agent finished generating response - finish the stream on MainActor
            Task { @MainActor in
                self.streamContinuation?.finish()
                self.streamContinuation = nil
            }
            
        case "tool_call":
            if let toolCallId = update["toolCallId"] as? String,
               let title = update["title"] as? String,
               let kind = update["kind"] as? String {
                
                // If a delegation is active, ignore all subsequent tool calls (they're from sub-agent)
                if activeDelegationId != nil {
                    return
                }
                
                // Check if this is a delegation (task tool)
                if title == "task" {
                    // Mark that we're now delegating
                    activeDelegationId = toolCallId
                    
                    // Format display title
                    var displayTitle = "Delegate: \(kind)"
                    if let rawInput = update["rawInput"] as? [String: Any],
                       let subagentType = rawInput["subagent_type"] as? String {
                        displayTitle = "Delegate: \(subagentType)"
                    }
                    
                    Task { @MainActor in
                        toolCallHandler?.addToolCall(id: toolCallId, title: displayTitle)
                    }
                } else {
                    // Normal main agent tool call
                    let displayTitle = "\(title): \(kind)"
                    Task { @MainActor in
                        toolCallHandler?.addToolCall(id: toolCallId, title: displayTitle)
                    }
                }
            }
            
        case "tool_call_update":
            if let toolCallId = update["toolCallId"] as? String,
               let statusString = update["status"] as? String {
                let status: ToolCall.Status = {
                    switch statusString {
                    case "pending": return .pending
                    case "in_progress": return .inProgress
                    case "completed": return .completed
                    case "failed": return .failed
                    case "cancelled": return .cancelled
                    default: return .inProgress
                    }
                }()
                
                // Clear delegation state if this delegation completed
                if toolCallId == activeDelegationId {
                    if status == .completed || status == .failed || status == .cancelled {
                        activeDelegationId = nil
                    }
                }
                
                // Check if this update contains rawInput with subagent_type (for title update)
                var updatedTitle: String? = nil
                if let rawInput = update["rawInput"] as? [String: Any],
                   let subagentType = rawInput["subagent_type"] as? String {
                    updatedTitle = "Delegate: \(subagentType)"
                }
                
                Task { @MainActor in
                    toolCallHandler?.updateToolCall(id: toolCallId, status: status)
                    if let newTitle = updatedTitle {
                        toolCallHandler?.updateToolCallTitle(id: toolCallId, title: newTitle)
                    }
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
        
        print("Sending session/set_model to OpenCode - sessionId: \(sessionId), modelId: \(model.id)")
        
        let params: [String: Any] = [
            "sessionId": sessionId,
            "modelId": model.id
        ]
        
        do {
            let startTime = Date()
            let (requestId, requestData) = try rpcClient.createRequest(method: "session/set_model", params: params)
            try processManager.write(requestData)
            
            let response = try await rpcClient.awaitResponse(forRequestId: requestId)
            let duration = Date().timeIntervalSince(startTime)
            print("session/set_model completed in \(duration)s")
            
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
        
        print("Sending session/set_mode to OpenCode - sessionId: \(sessionId), modeId: \(mode.id)")
        
        let params: [String: Any] = [
            "sessionId": sessionId,
            "modeId": mode.id
        ]
        
        do {
            let startTime = Date()
            let (requestId, requestData) = try rpcClient.createRequest(method: "session/set_mode", params: params)
            try processManager.write(requestData)
            
            let response = try await rpcClient.awaitResponse(forRequestId: requestId)
            let duration = Date().timeIntervalSince(startTime)
            print("session/set_mode completed in \(duration)s")
            
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
