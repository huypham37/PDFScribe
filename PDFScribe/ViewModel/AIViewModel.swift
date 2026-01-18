import Combine
import SwiftUI

@MainActor
class AIViewModel: ObservableObject {
    @Published var messages: [StoredMessage] = []
    @Published var currentInput: String = ""
    @Published var isProcessing: Bool = false
    @Published var currentToolCalls: [ToolCall] = [] // Tool calls for current query only
    
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
            // Use fade-in speed from settings
            let duration = aiService.fadeInSpeed.rawValue
            if duration > 0 {
                withAnimation(.easeOut(duration: duration)) {
                    if let lastIndex = messages.indices.last {
                        messages[lastIndex] = StoredMessage(
                            id: messages[lastIndex].id,
                            role: "assistant",
                            content: content,
                            timestamp: messages[lastIndex].timestamp
                        )
                    }
                }
            } else {
                // Instant update (no animation)
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
        guard !isProcessing else { 
            return 
        }
        
        let message = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { 
            return 
        }
        
        currentInput = ""
        isProcessing = true
        currentToolCalls.removeAll()  // Clear previous tool calls for new query
        
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
            
            // Wait for scroll animation to complete before starting stream
            // This separates "scroll to position" from "start typing" phases
            try? await Task.sleep(nanoseconds: 600_000_000) // 0.6s delay
            
            var fullResponse = ""
            var hasReceivedContent = false
            
            // Process chunks with smooth animation - no throttling needed
            for await chunk in controlledStream {
                fullResponse += chunk
                hasReceivedContent = true
                
                // Update UI immediately with animation
                await updateAssistantMessage(content: fullResponse)
            }
            
            // Final update to ensure complete message is shown
            await updateAssistantMessage(content: fullResponse)
            
            // Handle stream failure: if no content received, remove the empty placeholder
            await MainActor.run {
                if !hasReceivedContent {
                    if let lastMessage = messages.last, lastMessage.role == "assistant", lastMessage.content.isEmpty {
                        messages.removeLast()
                    }
                } else {
                    // Save tool calls to the assistant message
                    if let lastIndex = messages.indices.last, messages[lastIndex].role == "assistant" {
                        messages[lastIndex].toolCalls = currentToolCalls
                    }
                }
                
                isProcessing = false
            }
        }
    }
}

@MainActor
extension AIViewModel: ToolCallHandler {
    func addToolCall(id: String, name: String, query: String, toolType: ToolCall.ToolType) {
        let tool = ToolCall(id: id, name: name, query: query, status: .running, toolType: toolType)
        currentToolCalls.append(tool)
    }
    
    func updateToolCall(id: String, status: ToolCall.Status) {
        if let index = currentToolCalls.firstIndex(where: { $0.id == id }) {
            currentToolCalls[index].status = status
            if status == .completed || status == .failed || status == .cancelled {
                currentToolCalls[index].endTime = Date()
            }
        }
    }
    
    func updateToolCallTitle(id: String, title: String) {
        if let index = currentToolCalls.firstIndex(where: { $0.id == id }) {
            currentToolCalls[index].name = title
        }
    }
    
    func updateToolCallQuery(id: String, query: String) {
        if let index = currentToolCalls.firstIndex(where: { $0.id == id }) {
            // Only update if we have a more meaningful query
            if !query.isEmpty && currentToolCalls[index].query != query {
                currentToolCalls[index].query = query
            }
        }
    }
}
