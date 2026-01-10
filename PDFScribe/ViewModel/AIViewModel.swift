import Combine
import SwiftUI

@MainActor
class AIViewModel: ObservableObject {
    @Published var messages: [StoredMessage] = []
    @Published var currentInput: String = ""
    @Published var isProcessing: Bool = false
    @Published var toolCalls: [ToolCall] = []
    
    private let aiService: AIService
    private let streamController = StreamController()
    weak var appViewModel: AppViewModel?
    weak var fileService: FileService?
    
    init(aiService: AIService) {
        self.aiService = aiService
        aiService.setToolCallHandler(self)
    }
    
    func loadSession(_ session: ChatSession) {
        messages = aiService.loadSession(session)
    }
    
    func sendMessage() {
        guard !isProcessing else { return }  // Prevent concurrent sends
        
        let message = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        currentInput = ""
        isProcessing = true
        
        // Add user message immediately
        let userMessage = StoredMessage(role: "user", content: message)
        messages.append(userMessage)
        
        // Add empty assistant message placeholder
        let assistantMessage = StoredMessage(role: "assistant", content: "")
        messages.append(assistantMessage)
        
        Task {
            let context = AIContext(
                messages: [],
                currentFile: fileService?.currentNoteURL,
                currentFileContent: fileService?.currentNoteURL.flatMap { fileService?.loadNote(from: $0) } ?? nil,
                selection: nil,
                pdfURL: nil,
                pdfSelection: nil,
                pdfPage: nil,
                referencedFiles: []
            )
            
            let rawStream = aiService.sendMessageStream(message, context: context)
            let controlledStream = await streamController.process(rawStream, speed: aiService.typingSpeed)
            
            var fullResponse = ""
            var hasReceivedContent = false
            var updateCounter = 0
            let updateThrottle = 5  // Update UI every 5 characters for smooth performance
            
            for await chunk in controlledStream {
                fullResponse += chunk
                hasReceivedContent = true
                updateCounter += chunk.count
                
                // Throttle UI updates to reduce SwiftUI re-renders
                if updateCounter >= updateThrottle {
                    updateCounter = 0
                    if let lastIndex = messages.indices.last {
                        messages[lastIndex] = StoredMessage(
                            id: messages[lastIndex].id,
                            role: "assistant",
                            content: fullResponse,
                            timestamp: messages[lastIndex].timestamp
                        )
                    }
                }
            }
            
            // Final update to ensure complete message is shown
            if let lastIndex = messages.indices.last {
                messages[lastIndex] = StoredMessage(
                    id: messages[lastIndex].id,
                    role: "assistant",
                    content: fullResponse,
                    timestamp: messages[lastIndex].timestamp
                )
            }
            
            // Handle stream failure: if no content received, remove the empty placeholder
            if !hasReceivedContent {
                if let lastMessage = messages.last, lastMessage.role == "assistant", lastMessage.content.isEmpty {
                    messages.removeLast()
                    print("⚠️ Stream failed: No content received, removed placeholder message")
                }
            }
            
            isProcessing = false
        }
    }
}

@MainActor
extension AIViewModel: ToolCallHandler {
    func addToolCall(id: String, title: String) {
        toolCalls.append(ToolCall(id: id, title: title, status: .running))
    }
    
    func updateToolCall(id: String, status: ToolCall.Status) {
        if let index = toolCalls.firstIndex(where: { $0.id == id }) {
            toolCalls[index].status = status
        }
    }
    
    func updateToolCallTitle(id: String, title: String) {
        if let index = toolCalls.firstIndex(where: { $0.id == id }) {
            toolCalls[index].title = title
        }
    }
}
