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
    weak var toolCallHandler: ToolCallHandler?
    
    init(binaryPath: String, workingDirectory: String? = nil) {
        self.binaryPath = binaryPath
        self.workingDirectory = workingDirectory ?? FileManager.default.homeDirectoryForCurrentUser.path
    }
    
    func send(message: String, context: AIContext) async throws -> String {
        if !isInitialized {
            try await initialize()
            try await createSession()
        }
        
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
        
        let (requestId, requestData) = try rpcClient.createRequest(method: "session/prompt", params: params)
        try processManager.write(requestData)
        
        let response = try await rpcClient.awaitResponse(forRequestId: requestId)
        
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
    
    deinit {
        processManager?.terminate()
    }
}
