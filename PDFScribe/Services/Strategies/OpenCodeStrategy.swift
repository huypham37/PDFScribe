import Foundation

class OpenCodeStrategy: AIProviderStrategy {
    private let binaryPath: String
    private var processManager: ProcessManager?
    private var rpcClient: JSONRPCClient?
    private var isInitialized = false
    
    init(binaryPath: String) {
        self.binaryPath = binaryPath
    }
    
    func send(message: String, context: [AIMessage]) async throws -> String {
        if !isInitialized {
            try await initialize()
        }
        
        guard let processManager = processManager,
              let rpcClient = rpcClient,
              processManager.isRunning else {
            throw AIError.serverError("OpenCode process not running")
        }
        
        // Convert AIMessage context to ACP format
        let messages = context.map { ["role": $0.role, "content": $0.content] }
        
        let params: [String: Any] = [
            "messages": messages + [["role": "user", "content": message]]
        ]
        
        let requestData = try rpcClient.getMessageToSend(method: "agent/chat", params: params)
        try processManager.write(requestData)
        
        // Wait for response (simplified - real implementation needs proper async handling)
        return try await withCheckedThrowingContinuation { continuation in
            var responseText = ""
            
            processManager.onStdout = { data in
                rpcClient.handleIncomingData(data)
                
                // Parse the response (simplified)
                if let jsonString = String(data: data, encoding: .utf8),
                   let jsonData = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let result = json["result"] as? [String: Any],
                   let content = result["content"] as? String {
                    responseText = content
                    continuation.resume(returning: content)
                }
            }
        }
    }
    
    private func initialize() async throws {
        let manager = ProcessManager(binaryPath: binaryPath, arguments: ["acp"])
        let client = JSONRPCClient()
        
        manager.onStdout = { [weak client] data in
            client?.handleIncomingData(data)
        }
        
        manager.onStderr = { data in
            if let error = String(data: data, encoding: .utf8) {
                print("OpenCode stderr: \(error)")
            }
        }
        
        try manager.launch()
        
        // Send initialization handshake
        let initParams: [String: Any] = [
            "capabilities": [
                "chat": true
            ],
            "clientInfo": [
                "name": "PDFScribe",
                "version": "1.0.0"
            ]
        ]
        
        let initData = try client.getMessageToSend(method: "initialize", params: initParams)
        try manager.write(initData)
        
        self.processManager = manager
        self.rpcClient = client
        self.isInitialized = true
    }
    
    deinit {
        processManager?.terminate()
    }
}
