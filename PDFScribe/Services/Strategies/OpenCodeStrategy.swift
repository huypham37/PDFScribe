import Foundation

class OpenCodeStrategy: AIProviderStrategy {
    private let binaryPath: String
    private let workingDirectory: String
    private var processManager: ProcessManager?
    private var rpcClient: JSONRPCClient?
    private var sessionId: String?
    private var isInitialized = false
    private var accumulatedResponse = ""
    
    init(binaryPath: String, workingDirectory: String? = nil) {
        self.binaryPath = binaryPath
        self.workingDirectory = workingDirectory ?? FileManager.default.homeDirectoryForCurrentUser.path
    }
    
    func send(message: String, context: [AIMessage]) async throws -> String {
        print("OpenCode: Starting send()")
        if !isInitialized {
            print("OpenCode: Initializing...")
            try await initialize()
            print("OpenCode: Creating session...")
            try await createSession()
            print("OpenCode: Session created: \(sessionId ?? "nil")")
        }
        
        guard let sessionId = sessionId else {
            throw AIError.serverError("No active session")
        }
        
        print("OpenCode: Sending prompt...")
        return try await sendPrompt(sessionId: sessionId, message: message, context: context)
    }
    
    private func initialize() async throws {
        print("OpenCode: Creating ProcessManager...")
        let manager = ProcessManager(binaryPath: binaryPath, arguments: ["acp"])
        let client = JSONRPCClient()
        
        client.setNotificationHandler { [weak self] notification in
            print("OpenCode: Received notification: \(notification.method)")
            self?.handleNotification(notification)
        }
        
        manager.onStdout = { [weak client] data in
            if let str = String(data: data, encoding: .utf8) {
                print("OpenCode stdout: \(str)")
            }
            client?.handleIncomingData(data)
        }
        
        manager.onStderr = { data in
            if let error = String(data: data, encoding: .utf8) {
                print("OpenCode stderr: \(error)")
            }
        }
        
        print("OpenCode: Launching process...")
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
        
        print("OpenCode: Sending initialize request...")
        let (requestId, requestData) = try client.createRequest(method: "initialize", params: initParams)
        try manager.write(requestData)
        
        print("OpenCode: Waiting for initialize response...")
        let response = try await client.awaitResponse(forRequestId: requestId)
        
        guard response.error == nil else {
            let errorMsg = response.error?.message ?? "Unknown error"
            print("OpenCode: Initialize error: \(errorMsg)")
            throw AIError.serverError("Initialization failed: \(errorMsg)")
        }
        
        print("OpenCode: Initialized successfully")
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
            "mcpServers": [] // Empty array for no MCP servers
        ]
        
        print("OpenCode: Creating session with cwd: \(workingDirectory)")
        let (requestId, requestData) = try rpcClient.createRequest(method: "session/new", params: params)
        try processManager.write(requestData)
        
        let response = try await rpcClient.awaitResponse(forRequestId: requestId)
        
        guard response.error == nil else {
            let errorMsg = response.error?.message ?? "Unknown error"
            print("OpenCode: Session creation error: \(errorMsg)")
            throw AIError.serverError("Failed to create session: \(errorMsg)")
        }
        
        guard let result = response.result?.value as? [String: Any],
              let sessionId = result["sessionId"] as? String else {
            throw AIError.serverError("Failed to get sessionId from response")
        }
        
        print("OpenCode: Session created with ID: \(sessionId)")
        self.sessionId = sessionId
    }
    
    private func sendPrompt(sessionId: String, message: String, context: [AIMessage]) async throws -> String {
        guard let rpcClient = rpcClient,
              let processManager = processManager else {
            throw AIError.serverError("Client not initialized")
        }
        
        // Build prompt with context
        var contentBlocks: [[String: Any]] = []
        
        // Add context messages if any
        for msg in context {
            contentBlocks.append([
                "type": "text",
                "text": "\(msg.role): \(msg.content)"
            ])
        }
        
        // Add current message
        contentBlocks.append([
            "type": "text",
            "text": message
        ])
        
        let params: [String: Any] = [
            "sessionId": sessionId,
            "prompt": contentBlocks
        ]
        
        print("OpenCode: Sending prompt with params: \(params)")
        
        // Reset accumulated response
        accumulatedResponse = ""
        
        let (requestId, requestData) = try rpcClient.createRequest(method: "session/prompt", params: params)
        try processManager.write(requestData)
        
        print("OpenCode: Waiting for prompt response...")
        let response = try await rpcClient.awaitResponse(forRequestId: requestId)
        
        guard response.error == nil else {
            let errorMsg = response.error?.message ?? "Unknown error"
            print("OpenCode: Prompt error: \(errorMsg)")
            throw AIError.serverError(errorMsg)
        }
        
        print("OpenCode: Got response, accumulated: \(accumulatedResponse)")
        // Return accumulated response from notifications
        return accumulatedResponse.isEmpty ? "No response received" : accumulatedResponse
    }
    
    private func handleNotification(_ notification: JSONRPCNotification) {
        print("OpenCode: Received notification method: \(notification.method)")
        
        guard let params = notification.params?.value as? [String: Any] else {
            print("OpenCode: No params in notification")
            return
        }
        
        print("OpenCode: Notification params keys: \(params.keys)")
        
        guard let update = params["update"] as? [String: Any] else {
            print("OpenCode: No update in params")
            return
        }
        
        print("OpenCode: Update keys: \(update.keys)")
        
        guard let sessionUpdate = update["sessionUpdate"] as? String else {
            print("OpenCode: No sessionUpdate in update")
            return
        }
        
        print("OpenCode: sessionUpdate type: \(sessionUpdate)")
        
        switch notification.method {
        case "session/update":
            switch sessionUpdate {
            case "agent_message_chunk":
                if let content = update["content"] as? [String: Any],
                   let type = content["type"] as? String,
                   type == "text",
                   let text = content["text"] as? String {
                    accumulatedResponse += text
                    print("OpenCode: Accumulated chunk: '\(text)' (total: \(accumulatedResponse.count) chars)")
                } else {
                    print("OpenCode: Failed to extract text from content")
                }
            default:
                break
            }
        default:
            break
        }
    }
    
    deinit {
        processManager?.terminate()
    }
}
