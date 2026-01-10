import Combine
import SwiftUI

@MainActor
class AIViewModel: ObservableObject {
    @Published var messages: [StoredMessage] = []
    @Published var currentInput: String = ""
    @Published var isProcessing: Bool = false
    @Published var toolCalls: [ToolCall] = []
    
    private let aiService: AIService
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
        let message = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        currentInput = ""
        isProcessing = true
        
        Task {
            do {
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
                
                let stream = aiService.sendMessageStream(message, context: context)
                var fullResponse = ""
                
                for try await chunk in stream {
                    fullResponse += chunk
                }
                
                isProcessing = false
            } catch {
                print("Error sending message: \(error)")
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
