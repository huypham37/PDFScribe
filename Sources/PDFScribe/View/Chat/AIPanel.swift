import SwiftUI

@MainActor
class AIViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    
    let aiService: AIService
    
    init(aiService: AIService) {
        self.aiService = aiService
    }
    
    func sendMessage(_ text: String) async {
        guard !text.isEmpty else { return }
        
        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        
        isProcessing = true
        errorMessage = nil
        
        do {
            let aiMessages = messages.map { AIMessage(role: $0.role.rawValue, content: $0.content) }
            let response = try await aiService.sendMessage(text, context: aiMessages)
            
            let assistantMessage = ChatMessage(role: .assistant, content: response)
            messages.append(assistantMessage)
        } catch AIError.invalidAPIKey {
            errorMessage = "Please configure your API key in Settings"
        } catch AIError.serverError(let message) {
            errorMessage = "Server error: \(message)"
        } catch {
            errorMessage = "Failed to send message: \(error.localizedDescription)"
        }
        
        isProcessing = false
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    
    enum Role: String {
        case user
        case assistant
    }
}

struct AIPanel: View {
    @ObservedObject var viewModel: AIViewModel
    @State private var inputText: String = ""
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("AI Assistant")
                    .font(.headline)
                Spacer()
                Button(action: { showingSettings.toggle() }) {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Error message
            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
            }
            
            // Chat History
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                        
                        if viewModel.isProcessing {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Thinking...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                }
                .onReceive(viewModel.$messages) { messages in
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input Area
            HStack {
                TextField("Ask AI...", text: $inputText)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .onSubmit {
                        sendMessage()
                    }
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                }
                .buttonStyle(.borderless)
                .disabled(inputText.isEmpty || viewModel.isProcessing)
            }
            .padding()
        }
        .sheet(isPresented: $showingSettings) {
            AISettingsView(aiService: viewModel.aiService)
        }
    }
    
    private func sendMessage() {
        let message = inputText
        inputText = ""
        
        Task {
            await viewModel.sendMessage(message)
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            Text(message.content)
                .padding(10)
                .background(message.role == .user ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                .cornerRadius(12)
                .textSelection(.enabled)
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

struct AISettingsView: View {
    @ObservedObject var aiService: AIService
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("AI Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            Picker("Provider", selection: $aiService.provider) {
                ForEach(AIProvider.allCases, id: \.self) { provider in
                    Text(provider.rawValue).tag(provider)
                }
            }
            .pickerStyle(.segmented)
            
            VStack(alignment: .leading) {
                Text("API Key")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                SecureField("Enter your API key", text: $aiService.apiKey)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save") {
                    aiService.saveAPIKey()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}
