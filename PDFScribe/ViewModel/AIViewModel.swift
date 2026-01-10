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
    
    private func updateAssistantMessage(content: String) async {
        await MainActor.run {
            // Use smooth animation for text updates (0.3s fade-in)
            withAnimation(.easeOut(duration: 0.3)) {
                if let lastIndex = messages.indices.last {
                    messages[lastIndex] = StoredMessage(
                        id: messages[lastIndex].id,
                        role: "assistant",
                        content: content,
                        timestamp: messages[lastIndex].timestamp
                    )
                }
            }
        }
    }
    
    func sendMessage() {
        print("🟢 DEBUG: sendMessage() called")
        guard !isProcessing else { 
            print("🟡 DEBUG: sendMessage() blocked - isProcessing is true")
            return 
        }
        
        let message = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { 
            print("🟡 DEBUG: sendMessage() blocked - message is empty")
            return 
        }
        
        print("🟢 DEBUG: sendMessage() proceeding with message: '\(message.prefix(30))...'")
        currentInput = ""
        isProcessing = true
        
        // Add user message immediately
        let userMessage = StoredMessage(role: "user", content: message)
        messages.append(userMessage)
        
        // Add empty assistant message placeholder
        let assistantMessage = StoredMessage(role: "assistant", content: "")
        messages.append(assistantMessage)
        
        Task(priority: .userInitiated) {
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
            
            // Process chunks with smooth animation - no throttling needed
            for await chunk in controlledStream {
                print("🟡 DEBUG: AIViewModel received chunk: '\(chunk.prefix(30))...' (\(chunk.count) chars)")
                fullResponse += chunk
                hasReceivedContent = true
                
                // Update UI immediately with animation
                await updateAssistantMessage(content: fullResponse)
                print("🟡 DEBUG: Updated UI with \(fullResponse.count) total chars")
            }
            
            // Final update to ensure complete message is shown
            await updateAssistantMessage(content: fullResponse)
            
            // Handle stream failure: if no content received, remove the empty placeholder
            await MainActor.run {
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
