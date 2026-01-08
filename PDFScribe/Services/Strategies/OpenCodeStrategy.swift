import Foundation

protocol ToolCallHandler: AnyObject {
    func addToolCall(id: String, title: String)
    func updateToolCall(id: String, status: ToolCall.Status)
}

class OpenCodeStrategy: AIProviderStrategy {
    private let binaryPath: String
    private let workingDirectory: String
    private var processManager: ProcessManager?
    private var rpcClient: JSONRPCClient?
    private var sessionId: String?
    private var isInitialized = false
    private var accumulatedResponse = ""
    private var availableModelsList: [AIModel] = []
    private var availableModesList: [AIMode] = []
    private var selectedModel: AIModel?
    private var selectedMode: AIMode?
    weak var toolCallHandler: ToolCallHandler?
    
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
    
    func send(message: String, context: AIContext) async throws -> String {
        let sendStartTime = Date()
        print("OpenCodeStrategy.send() called - isInitialized: \(isInitialized), sessionId: \(sessionId ?? "nil")")
        if !isInitialized {
            print("Initializing OpenCode...")
            try await initialize()
            print("Creating session...")
            try await createSession()
        }
        
        print("[TIMING] Initialization/session took: \(Date().timeIntervalSince(sendStartTime))s")
        
        guard let sessionId = sessionId else {
            throw AIError.serverError("No active session")
        }
        
        return try await sendPrompt(sessionId: sessionId, message: message, context: context)
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
    
    private func sendPrompt(sessionId: String, message: String, context: AIContext) async throws -> String {
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
        
        accumulatedResponse = ""
        
        let promptStartTime = Date()
        print("[TIMING] Sending session/prompt request...")
        let (requestId, requestData) = try rpcClient.createRequest(method: "session/prompt", params: params)
        try processManager.write(requestData)
        print("[TIMING] Request sent, waiting for response...")
        
        let response = try await rpcClient.awaitResponse(forRequestId: requestId)
        let promptDuration = Date().timeIntervalSince(promptStartTime)
        
        print("[TIMING] session/prompt completed in \(promptDuration)s")
        print("session/prompt response received - error: \(response.error?.message ?? "none"), accumulated: \(accumulatedResponse.count) chars")
        
        guard response.error == nil else {
            let errorMsg = response.error?.message ?? "Unknown error"
            throw AIError.serverError(errorMsg)
        }
        
        return accumulatedResponse.isEmpty ? "No response received" : accumulatedResponse
    }
    
    private func handleNotification(_ notification: JSONRPCNotification) {
        guard let params = notification.params?.value as? [String: Any],
              let update = params["update"] as? [String: Any],
              let sessionUpdate = update["sessionUpdate"] as? String else {
            return
        }
        
        guard notification.method == "session/update" else { return }
        
        print("[NOTIFICATION] Received update type: \(sessionUpdate)")
        switch sessionUpdate {
        case "agent_message_chunk":
            if let content = update["content"] as? [String: Any],
               let type = content["type"] as? String,
               type == "text",
               let text = content["text"] as? String {
                accumulatedResponse += text
            }
            
        case "tool_call":
            if let toolCallId = update["toolCallId"] as? String,
               let title = update["title"] as? String,
               let kind = update["kind"] as? String {
                // Combine title and kind for better display
                let displayTitle = "\(title): \(kind)"
                Task { @MainActor in
                    toolCallHandler?.addToolCall(id: toolCallId, title: displayTitle)
                }
            }
            
        case "tool_call_update":
            // Debug: print the entire update to see what fields are available
            if let jsonData = try? JSONSerialization.data(withJSONObject: update),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("OpenCode tool_call_update: \(jsonString)")
            }
            
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
                Task { @MainActor in
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
