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
    
    func updateToolCallTitle(id: String, title: String) {
        if var toolCall = toolCalls[id] {
            toolCall.title = title
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
            
            // Trigger auto-naming if this is the first exchange
            if messages.count == 2 { // First user message + first assistant response
                triggerAutoNaming(userMessage: text, assistantResponse: response)
            }
            
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
    
    private func triggerAutoNaming(userMessage: String, assistantResponse: String) {
        // Run auto-naming in background to avoid disrupting the main conversation
        Task {
            await generateSessionTitle(userMessage: userMessage, assistantResponse: assistantResponse)
        }
    }
    
    private func generateSessionTitle(userMessage: String, assistantResponse: String) async {
        guard let fileService = fileService else { return }
        
        // Get the current project path - we need access to AppViewModel through a different route
        // For now, we'll use a simple title generation based on the user message
        // TODO: Could be improved by accessing AppViewModel directly
        
        // Simple title generation: use first few words of user message
        let words = userMessage.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .prefix(4)
        let simpleTitle = words.joined(separator: " ")
        let cleanTitle = simpleTitle.isEmpty ? "Chat Session" : simpleTitle
        
        // Update the session title in storage for sessions that still have default title
        var history = fileService.loadChatHistory()
        
        // Find the most recent session that still has "New Session" title
        if let sessionIndex = history.sessions.indices.reversed().first(where: { index in
            history.sessions[index].title == "New Session"
        }) {
            history.sessions[sessionIndex].title = cleanTitle
            fileService.saveChatHistory(history)
            print("Auto-generated session title: \(cleanTitle)")
        }
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
    var title: String
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
                        
                        // Processing indicator (only show if no tool calls are active)
                        if viewModel.isProcessing && viewModel.toolCalls.isEmpty {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.6)
                                Text("Thinking...")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                        
                        // Bottom anchor for auto-scroll
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding(16)
                }
                // Auto-scroll on any content change
                .onChange(of: viewModel.messages.count) { _ in scrollToBottom(proxy) }
                .onChange(of: viewModel.toolCalls.count) { _ in scrollToBottom(proxy) }
                .onChange(of: viewModel.isProcessing) { _ in scrollToBottom(proxy) }
            }
            
            Spacer()
            
            // Bottom section
            VStack(spacing: 12) {
                // Chat input field with mention support
                HStack(alignment: .bottom, spacing: 8) {
                    ZStack(alignment: .bottomLeading) {
                        TextField("Message...", text: $inputText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .lineLimit(1...5)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                            .disabled(viewModel.isProcessing)
                            .onChange(of: inputText) { newValue in
                                handleTextChange(newValue)
                            }
                            .onSubmit {
                                if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    sendMessage()
                                }
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
    
    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }
    
    private func sendMessage() {
        guard !viewModel.isProcessing else { return }
        
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        parseMentions(from: text)
        
        // Clear input on main thread to ensure UI update
        Task { @MainActor in
            inputText = ""
        }
        
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
    private let parser = MessageParser()
    
    var body: some View {
        let parsed = parser.parse(message.content)
        
        VStack(alignment: .leading, spacing: 6) {
            Text(message.role == .user ? "You" : "Assistant")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            // Render parsed blocks
            VStack(alignment: .leading, spacing: 12) {
                ForEach(parsed.blocks) { block in
                    switch block {
                    case .text(let content):
                        Text(LocalizedStringKey(content))
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .textSelection(.enabled)
                            .lineSpacing(3)
                    case .code(let language, let code):
                        CodeBlockView(language: language, code: code)
                    }
                }
            }
            
            // References section
            if !parsed.references.isEmpty {
                Divider()
                    .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("References")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    ForEach(Array(parsed.references.enumerated()), id: \.offset) { index, url in
                        ReferenceView(number: index + 1, url: url)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Code Block View
struct CodeBlockView: View {
    let language: String?
    let code: String
    @State private var showCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with language and copy button
            HStack {
                if let lang = language {
                    Text(lang)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: copyCode) {
                    HStack(spacing: 4) {
                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11))
                        Text(showCopied ? "Copied" : "Copy")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            
            // Code content
            ScrollView(.horizontal, showsIndicators: true) {
                Text(code)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                    .padding(12)
            }
            .background(Color(NSColor.controlBackgroundColor))
        }
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
    }
    
    private func copyCode() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        showCopied = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopied = false
        }
    }
}

// MARK: - Reference View
struct ReferenceView: View {
    let number: Int
    let url: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("[\(number)]")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
            
            Link(url, destination: URL(string: url) ?? URL(string: "about:blank")!)
                .font(.system(size: 11))
                .foregroundColor(.blue)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

// MARK: - Tool Call View
struct ToolCallView: View {
    let toolCall: ToolCall
    @State private var pulseOpacity: Double = 1.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Run Command")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Text(toolCall.title)
                .font(.system(size: 13))
                .foregroundColor(toolCall.status == .inProgress ? Color.green : Color.gray)
                .opacity(toolCall.status == .inProgress ? pulseOpacity : 1.0)
                .onAppear {
                    if toolCall.status == .inProgress {
                        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                            pulseOpacity = 0.3
                        }
                    }
                }
                .onChange(of: toolCall.status) { newStatus in
                    if newStatus == .inProgress {
                        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                            pulseOpacity = 0.3
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            pulseOpacity = 1.0
                        }
                    }
                }
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
            
            // Connection status for OpenCode
            if aiService.provider == .opencode {
                if aiService.isConnecting {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Connecting to OpenCode...")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
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
                    .disabled(aiService.isConnecting)
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
                    .disabled(aiService.isConnecting)
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
