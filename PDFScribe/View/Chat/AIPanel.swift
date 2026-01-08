import Combine
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
    
    func newThread() {
        messages.removeAll()
        errorMessage = nil
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
    @State private var showingModelPicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header - minimal like reference
            HStack {
                // Left: New conversation button
                Button(action: viewModel.newThread) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                Menu {
                    Button("New Conversation", action: viewModel.newThread)
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 16)
                
                Spacer()
                
                // Center: Title with dropdown
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Text("New Conversation")
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Right: History
                Button(action: {}) {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .opacity(0.5)
            
            // Chat Content - clean white space
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        // Error message
                        if let error = viewModel.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 12))
                                Text(error)
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(.orange)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.06))
                            .cornerRadius(8)
                        }
                        
                        // Messages
                        ForEach(viewModel.messages) { message in
                            MessageView(message: message)
                                .id(message.id)
                        }
                        
                        // Processing indicator
                        if viewModel.isProcessing {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.6)
                                Text("Thinking...")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(16)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Bottom section
            VStack(spacing: 12) {
                // Model selector - like reference "No model selected"
                Button(action: { showingModelPicker.toggle() }) {
                    HStack {
                        Text(modelDisplayName)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingModelPicker) {
                    modelPickerView
                }
                
                // Bottom toolbar
                HStack(spacing: 16) {
                    // Attachment button
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "paperclip")
                                .font(.system(size: 14))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8))
                        }
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    // Right side icons
                    HStack(spacing: 12) {
                        Button(action: {}) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { showingSettings.toggle() }) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingSettings) {
            AISettingsView(aiService: viewModel.aiService)
        }
    }
    
    private var modelDisplayName: String {
        if viewModel.aiService.apiKey.isEmpty {
            return "No model selected"
        }
        return viewModel.aiService.provider == .openai ? "GPT-4" : "Claude"
    }
    
    private var modelPickerView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                viewModel.aiService.provider = .openai
                showingModelPicker = false
            }) {
                HStack {
                    Text("GPT-4")
                        .font(.system(size: 13))
                    Spacer()
                    if viewModel.aiService.provider == .openai {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Divider()
            
            Button(action: {
                viewModel.aiService.provider = .anthropic
                showingModelPicker = false
            }) {
                HStack {
                    Text("Claude")
                        .font(.system(size: 13))
                    Spacer()
                    if viewModel.aiService.provider == .anthropic {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(width: 160)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Message View
struct MessageView: View {
    let message: ChatMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(message.role == .user ? "You" : "Assistant")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(message.content)
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .textSelection(.enabled)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Settings View
struct AISettingsView: View {
    @ObservedObject var aiService: AIService
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("AI Settings")
                .font(.system(size: 15, weight: .semibold))
            
            Picker("Provider", selection: $aiService.provider) {
                ForEach(AIProvider.allCases, id: \.self) { provider in
                    Text(provider.rawValue).tag(provider)
                }
            }
            .pickerStyle(.segmented)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("API Key")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                SecureField("Enter your API key", text: $aiService.apiKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13))
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
                .buttonStyle(.borderedProminent)
                .tint(Color("SlateIndigo"))
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}
