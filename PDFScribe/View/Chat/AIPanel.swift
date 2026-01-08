import Combine
import SwiftUI

@MainActor
class AIViewModel: ObservableObject, ToolCallHandler {
    @Published var messages: [ChatMessage] = []
    @Published var toolCalls: [String: ToolCall] = [:] // toolCallId -> ToolCall
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    @Published var mentionedFiles: [URL] = []
    
    let aiService: AIService
    weak var editorViewModel: EditorViewModel?
    weak var pdfViewModel: PDFViewModel?
    weak var fileService: FileService?
    
    init(aiService: AIService) {
        self.aiService = aiService
        aiService.setToolCallHandler(self)
    }
    
    // Combine messages and tool calls, sorted by timestamp
    var chronologicalItems: [Any] {
        let allItems = messages as [Any] + toolCalls.values.map { $0 as Any }
        return allItems.sorted { item1, item2 in
            let time1 = (item1 as? ChatMessage)?.timestamp ?? (item1 as? ToolCall)?.timestamp ?? Date.distantPast
            let time2 = (item2 as? ChatMessage)?.timestamp ?? (item2 as? ToolCall)?.timestamp ?? Date.distantPast
            return time1 < time2
        }
    }
    
    func addToolCall(id: String, title: String) {
        toolCalls[id] = ToolCall(id: id, title: title, status: .inProgress)
    }
    
    func updateToolCall(id: String, status: ToolCall.Status) {
        if var toolCall = toolCalls[id] {
            toolCall.status = status
            toolCalls[id] = toolCall
        }
    }
    
    func sendMessage(_ text: String) async {
        guard !text.isEmpty else { return }
        
        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        
        isProcessing = true
        errorMessage = nil
        
        do {
            let aiMessages = messages.map { AIMessage(role: $0.role.rawValue, content: $0.content) }
            
            // Gather context from editor and PDF
            let currentFile = fileService?.currentNoteURL
            let currentFileContent = editorViewModel?.content
            let pdfSelection = pdfViewModel?.currentSelection
            
            let context = AIContext(
                messages: aiMessages,
                currentFile: currentFile,
                currentFileContent: currentFileContent,
                selection: nil, // TODO: Add editor text selection if needed
                pdfURL: nil, // TODO: Add current PDF URL from pdfViewModel if needed
                pdfSelection: pdfSelection?.text,
                pdfPage: pdfSelection?.pageNumber,
                referencedFiles: mentionedFiles
            )
            let response = try await aiService.sendMessage(text, context: context)
            
            let assistantMessage = ChatMessage(role: .assistant, content: response)
            messages.append(assistantMessage)
            
            // Clear mentioned files after sending
            mentionedFiles.removeAll()
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
    let timestamp: Date
    
    enum Role: String {
        case user
        case assistant
        case toolCall
    }
    
    init(role: Role, content: String) {
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}

struct ToolCall: Identifiable {
    let id: String // toolCallId from OpenCode
    let title: String
    var status: Status
    let timestamp: Date
    
    enum Status {
        case pending
        case inProgress
        case completed
        case failed
        case cancelled
    }
    
    init(id: String, title: String, status: Status) {
        self.id = id
        self.title = title
        self.status = status
        self.timestamp = Date()
    }
}

struct AIPanel: View {
    @ObservedObject var viewModel: AIViewModel
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var inputText: String = ""
    @State private var showingSettings = false
    @State private var showingMentionPicker = false
    @State private var mentionFilter: String = ""
    @State private var selectedMentionIndex: Int = 0
    
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
                    LazyVStack(alignment: .leading, spacing: 12) {
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
                        
                        // Messages and tool calls in chronological order
                        ForEach(Array(viewModel.chronologicalItems.enumerated()), id: \.offset) { _, item in
                            if let message = item as? ChatMessage {
                                MessageView(message: message)
                                    .id(message.id)
                            } else if let toolCall = item as? ToolCall {
                                ToolCallView(toolCall: toolCall)
                                    .id(toolCall.id)
                            }
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
                // Chat input field with mention support
                HStack(spacing: 8) {
                    ZStack(alignment: .bottomLeading) {
                        TextField("Message...", text: $inputText, onEditingChanged: { _ in }, onCommit: {
                            if showingMentionPicker && !filteredFiles.isEmpty {
                                selectFile(filteredFiles[selectedMentionIndex])
                            } else {
                                sendMessage()
                            }
                        })
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                            .disabled(viewModel.isProcessing)
                            .onChange(of: inputText) { newValue in
                                handleTextChange(newValue)
                            }
                            .onKeyPress(.upArrow) {
                                if showingMentionPicker {
                                    selectedMentionIndex = max(0, selectedMentionIndex - 1)
                                    return .handled
                                }
                                return .ignored
                            }
                            .onKeyPress(.downArrow) {
                                if showingMentionPicker {
                                    selectedMentionIndex = min(filteredFiles.count - 1, selectedMentionIndex + 1)
                                    return .handled
                                }
                                return .ignored
                            }
                            .onKeyPress(.tab) {
                                if showingMentionPicker && !filteredFiles.isEmpty {
                                    selectFile(filteredFiles[selectedMentionIndex])
                                    return .handled
                                }
                                return .ignored
                            }
                            .onKeyPress(.escape) {
                                if showingMentionPicker {
                                    showingMentionPicker = false
                                    return .handled
                                }
                                return .ignored
                            }
                        
                        if showingMentionPicker {
                            mentionPickerView
                                .offset(y: -50)
                        }
                    }
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(inputText.isEmpty ? .secondary : Color("SlateIndigo"))
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.isEmpty || viewModel.isProcessing)
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
    
    private func sendMessage() {
        guard !viewModel.isProcessing else { return }
        
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        parseMentions(from: text)
        inputText = ""
        
        Task {
            await viewModel.sendMessage(text)
        }
    }
    
    private func handleTextChange(_ newValue: String) {
        if let lastAtIndex = newValue.lastIndex(of: "@") {
            let afterAt = String(newValue[newValue.index(after: lastAtIndex)...])
            if !afterAt.contains(" ") {
                mentionFilter = afterAt
                showingMentionPicker = true
                selectedMentionIndex = 0
                return
            }
        }
        showingMentionPicker = false
    }
    
    private func parseMentions(from text: String) {
        let pattern = "@\\[([^\\]]+)\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        var mentionedURLs: [URL] = []
        
        for match in matches {
            if let range = Range(match.range(at: 1), in: text) {
                let filename = String(text[range])
                if let fileItem = appViewModel.getAllFiles().first(where: { $0.name == filename }) {
                    mentionedURLs.append(fileItem.url)
                }
            }
        }
        
        viewModel.mentionedFiles = mentionedURLs
    }
    
    private func selectFile(_ fileItem: FileItem) {
        if let atIndex = inputText.lastIndex(of: "@") {
            let beforeAt = String(inputText[..<atIndex])
            inputText = beforeAt + "@[\(fileItem.name)] "
        }
        showingMentionPicker = false
    }
    
    private var filteredFiles: [FileItem] {
        let allFiles = appViewModel.getAllFiles()
        if mentionFilter.isEmpty {
            return Array(allFiles.prefix(10))
        }
        return allFiles.filter { $0.name.localizedCaseInsensitiveContains(mentionFilter) }.prefix(10).map { $0 }
    }
    
    private var mentionPickerView: some View {
        let itemHeight: CGFloat = 28
        let calculatedHeight = min(CGFloat(filteredFiles.count) * itemHeight, 280)
        
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(filteredFiles.enumerated()), id: \.element.id) { index, file in
                Button(action: { selectFile(file) }) {
                    HStack(spacing: 8) {
                        Image(systemName: file.iconName)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text(file.name)
                            .font(.system(size: 12))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(index == selectedMentionIndex ? Color.accentColor.opacity(0.2) : Color(NSColor.controlBackgroundColor))
                
                if file.id != filteredFiles.last?.id {
                    Divider()
                }
            }
        }
        .frame(width: 250, height: calculatedHeight)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
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

// MARK: - Tool Call View
struct ToolCallView: View {
    let toolCall: ToolCall
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Run Command")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Text(toolCall.title)
                .font(.system(size: 13))
                .foregroundColor(toolCall.status == .inProgress ? Color.green : Color.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
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
            
            if aiService.provider != .opencode {
                VStack(alignment: .leading, spacing: 6) {
                    Text("API Key")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    SecureField("Enter your API key", text: $aiService.apiKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13))
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("OpenCode Binary Path")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    TextField("/usr/local/bin/opencode", text: $aiService.opencodePath)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13))
                }
            }
            
            // Model selector
            if !aiService.availableModels.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Model")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Picker("Model", selection: Binding(
                        get: { aiService.currentModel?.id ?? aiService.availableModels.first?.id ?? "" },
                        set: { newId in
                            if let model = aiService.availableModels.first(where: { $0.id == newId }) {
                                Task {
                                    try? await aiService.selectModel(model)
                                }
                            }
                        }
                    )) {
                        ForEach(aiService.availableModels) { model in
                            Text(model.name).tag(model.id)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            // Mode selector (only for OpenCode)
            if !aiService.availableModes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Mode")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Picker("Mode", selection: Binding(
                        get: { aiService.currentMode?.id ?? aiService.availableModes.first?.id ?? "" },
                        set: { newId in
                            if let mode = aiService.availableModes.first(where: { $0.id == newId }) {
                                Task {
                                    try? await aiService.selectMode(mode)
                                }
                            }
                        }
                    )) {
                        ForEach(aiService.availableModes) { mode in
                            Text(mode.name).tag(mode.id)
                        }
                    }
                    .pickerStyle(.menu)
                }
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
