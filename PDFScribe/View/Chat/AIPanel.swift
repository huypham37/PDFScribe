import Combine
import SwiftUI

@MainActor
class AIViewModel: ObservableObject, ToolCallHandler {
    @Published var messages: [ChatMessage] = []
    @Published var toolCalls: [String: ToolCall] = [:] // toolCallId -> ToolCall
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    @Published var mentionedFiles: [URL] = []
    @Published var showingSettings = false
    @Published var currentSessionTitle: String = "New Conversation"
    @Published var recentSessions: [ChatSession] = []
    @Published var selectedMode: AgentMode = .build
    @Published var availableModes: [AgentMode] = []
    
    let aiService: AIService
    
    // Computed property to check if any tool call is actively running
    var hasActiveToolCalls: Bool {
        toolCalls.values.contains { $0.status == .inProgress }
    }
    weak var editorViewModel: EditorViewModel?
    weak var pdfViewModel: PDFViewModel?
    weak var fileService: FileService?
    weak var appViewModel: AppViewModel?
    
    init(aiService: AIService) {
        self.aiService = aiService
        
        // Register self as the tool call handler to receive tool call events
        self.aiService.setToolCallHandler(self)
        
        // Load available agent modes from OpenCode config
        self.availableModes = OpenCodeConfigLoader.shared.loadPrimaryAgents()
        print("📋 Loaded \(availableModes.count) agent modes: \(availableModes.map { $0.rawValue }.joined(separator: ", "))")
    }

    
    func fetchRecentSessions() {
        guard let projectURL = appViewModel?.projectRootURL,
              let fileService = fileService else {
            recentSessions = []
            return
        }
        
        recentSessions = fileService.getRecentSessions(for: projectURL.path, limit: 5)
        print("📚 Fetched \(recentSessions.count) recent sessions")
    }
    
    func switchToSession(_ session: ChatSession) {
        print("🔄 Switching to session: \(session.id) - \(session.title)")
        
        // Load messages from the session
        let storedMessages = aiService.loadSession(session)
        messages = storedMessages.map { stored in
            ChatMessage(
                role: stored.role == "user" ? .user : .assistant,
                content: stored.content
            )
        }
        
        // Update UI
        currentSessionTitle = session.title
        errorMessage = nil
        toolCalls.removeAll()
        
        // Refresh recent sessions list
        fetchRecentSessions()
        
        print("✅ Switched to session with \(messages.count) messages")
    }
    
    func loadCurrentSessionMessages() {
        print("🔄 AIPanel.loadCurrentSessionMessages() called")
        print("   - aiService.getCurrentSessionId(): \(aiService.getCurrentSessionId() ?? "nil")")
        print("   - fileService: \(fileService != nil ? "exists" : "nil")")
        
        guard let sessionId = aiService.getCurrentSessionId(),
              let fileService = fileService else {
            print("⚠️ Cannot load messages: sessionId=\(aiService.getCurrentSessionId() ?? "nil"), fileService=\(fileService != nil ? "exists" : "nil")")
            return
        }
        
        print("📥 Loading messages for session: \(sessionId)")
        let storedMessages = fileService.getSessionMessages(sessionId: sessionId)
        print("📥 Found \(storedMessages.count) stored messages")
        
        messages = storedMessages.map { stored in
            ChatMessage(
                role: stored.role == "user" ? .user : .assistant,
                content: stored.content
            )
        }
        
        if !messages.isEmpty {
            print("✅ Loaded \(messages.count) messages from session \(sessionId)")
        } else {
            print("ℹ️ No messages to load for session \(sessionId)")
        }
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
        
        // Create placeholder for assistant message
        let assistantMessage = ChatMessage(role: .assistant, content: "")
        messages.append(assistantMessage)
        let assistantIndex = messages.count - 1
        
        do {
            let aiMessages = messages.dropLast().map { AIMessage(role: $0.role.rawValue, content: $0.content) }
            
            // Gather context from editor and PDF
            let currentFile = fileService?.currentNoteURL
            let currentFileContent = editorViewModel?.content
            let pdfSelection = pdfViewModel?.currentSelection
            
            let context = AIContext(
                messages: Array(aiMessages),
                currentFile: currentFile,
                currentFileContent: currentFileContent,
                selection: nil,
                pdfURL: nil,
                pdfSelection: pdfSelection?.text,
                pdfPage: pdfSelection?.pageNumber,
                referencedFiles: mentionedFiles
            )
            
            let stream = aiService.sendMessageStream(text, context: context)
            var fullResponse = ""
            
            for try await chunk in stream {
                // Implement typewriter effect: add characters progressively
                for char in chunk {
                    fullResponse.append(char)
                    messages[assistantIndex] = ChatMessage(role: .assistant, content: fullResponse)
                    
                    // Use customizable typing speed
                    try? await Task.sleep(nanoseconds: aiService.typingSpeed.nanoseconds)
                }
            }
            
            // Trigger auto-naming if this is the first exchange
            if messages.count == 2 {
                triggerAutoNaming(userMessage: text, assistantResponse: fullResponse)
            }
            
            // Clear mentioned files after sending
            mentionedFiles.removeAll()
        } catch AIError.invalidAPIKey {
            errorMessage = "Please configure your API key in Settings"
            // Remove the empty assistant message on error
            if assistantIndex < messages.count {
                messages.remove(at: assistantIndex)
            }
        } catch AIError.serverError(let message) {
            errorMessage = "Server error: \(message)"
            if assistantIndex < messages.count {
                messages.remove(at: assistantIndex)
            }
        } catch {
            errorMessage = "Failed to send message: \(error.localizedDescription)"
            if assistantIndex < messages.count {
                messages.remove(at: assistantIndex)
            }
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
        print("🏷️ Auto-naming: generateSessionTitle() called")
        print("   - sessionId: \(aiService.getCurrentSessionId() ?? "nil")")
        print("   - fileService: \(fileService != nil ? "exists" : "nil")")
        
        guard let fileService = fileService else {
            print("⚠️ Auto-naming: FileService not available")
            return
        }
        
        guard let sessionId = aiService.getCurrentSessionId() else {
            print("⚠️ Auto-naming: No current session ID")
            return
        }
        
        print("🏷️ Auto-naming: Asking AI for title...")
        
        // Prepare a prompt to ask the AI for a concise title
        let prompt = """
        Generate a concise title (3-5 words maximum) that summarizes this conversation.
        
        User asked: "\(userMessage)"
        
        Return ONLY the title, nothing else. No quotes, no explanation.
        """
        
        // Create minimal context for this meta-request
        let context = AIContext(
            messages: [],
            currentFile: nil,
            currentFileContent: nil,
            selection: nil,
            pdfURL: nil,
            pdfSelection: nil,
            pdfPage: nil,
            referencedFiles: []
        )
        
        var cleanTitle: String
        
        do {
            // Call AI with saveToHistory: false to avoid polluting chat history
            let response = try await aiService.sendMessage(prompt, context: context, saveToHistory: false)
            
            // Clean up the response
            cleanTitle = response
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                .components(separatedBy: .newlines).first ?? response
            
            // Limit length
            let words = cleanTitle.components(separatedBy: .whitespaces).prefix(6)
            cleanTitle = words.joined(separator: " ")
            
            if cleanTitle.isEmpty {
                cleanTitle = "Chat Session"
            }
            
            print("🏷️ Auto-naming: AI generated title: '\(cleanTitle)'")
            
        } catch {
            // Fallback to simple title if AI call fails
            print("⚠️ Auto-naming: AI call failed, using fallback: \(error)")
            let words = userMessage.components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .prefix(4)
            cleanTitle = words.joined(separator: " ")
            if cleanTitle.isEmpty {
                cleanTitle = "Chat Session"
            }
        }
        
        // Update the session title in storage
        var history = fileService.loadChatHistory()
        
        if let sessionIndex = history.sessions.firstIndex(where: { $0.id == sessionId }) {
            let oldTitle = history.sessions[sessionIndex].title
            history.sessions[sessionIndex].title = cleanTitle
            fileService.saveChatHistory(history)
            
            // Update the UI
            currentSessionTitle = cleanTitle
            
            print("✅ Auto-naming: Session '\(oldTitle)' renamed to '\(cleanTitle)'")
        } else {
            print("⚠️ Auto-naming: Could not find current session in history")
        }
    }
    
    func newThread() {
        messages.removeAll()
        errorMessage = nil
        toolCalls.removeAll()
        currentSessionTitle = "New Conversation"
        
        // Create new session in AIService
        aiService.createNewSession()
        
        // Refresh recent sessions list
        fetchRecentSessions()
        
        print("🆕 Started new conversation thread")
    }
    
    func changeAgentMode(to mode: AgentMode) async {
        guard aiService.provider == .opencode else {
            print("⚠️ Agent mode only supported for OpenCode provider")
            return
        }
        
        // Map AgentMode to OpenCode's AIMode
        let openCodeMode = AIMode(
            id: mode.agentID,
            name: mode.rawValue,
            description: mode.description
        )
        
        do {
            try await aiService.selectMode(openCodeMode)
            print("✅ Changed agent mode to: \(mode.rawValue)")
        } catch {
            print("❌ Failed to change agent mode: \(error)")
            errorMessage = "Failed to change agent mode: \(error.localizedDescription)"
        }
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
                
                Spacer()
                
                // Center: Title
                Text(viewModel.currentSessionTitle)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Right: History
                Menu {
                    if viewModel.recentSessions.isEmpty {
                        Text("No recent sessions")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.recentSessions) { session in
                            Button(action: {
                                viewModel.switchToSession(session)
                            }) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(session.title)
                                        .font(.system(size: 12))
                                    Text(formatDate(session.lastActive))
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                 .menuStyle(.borderlessButton)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .onAppear {
                // Fetch sessions when view appears (after dependencies are injected)
                viewModel.fetchRecentSessions()
            }
            
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
                        
                        // Processing indicator (only show if no active tool calls)
                        if viewModel.isProcessing && !viewModel.hasActiveToolCalls {
                            ThinkingIndicator()
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
            VStack(spacing: 0) {
                // Agent mode selector
                AgentModeSelector(selectedMode: $viewModel.selectedMode, availableModes: viewModel.availableModes)
                
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
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
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
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingSettings) {
            AISettingsView(aiService: viewModel.aiService)
        }
        .onChange(of: viewModel.selectedMode) { _, newMode in
            Task {
                await viewModel.changeAgentMode(to: newMode)
            }
        }
    }
    
    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Today, \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
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
            .onChange(of: aiService.provider) { _, _ in
                aiService.saveAPIKey()
            }
            
            if aiService.provider != .opencode {
                VStack(alignment: .leading, spacing: 6) {
                    Text("API Key")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    SecureField("Enter your API key", text: $aiService.apiKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13))
                        .onChange(of: aiService.apiKey) { _, _ in
                            aiService.saveAPIKey()
                        }
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("OpenCode Binary Path")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    TextField("/usr/local/bin/opencode", text: $aiService.opencodePath)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13))
                        .onChange(of: aiService.opencodePath) { _, _ in
                            aiService.saveAPIKey()
                        }
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
            
            // Typing speed selector
            VStack(alignment: .leading, spacing: 6) {
                Text("Typing Speed")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Picker("Typing Speed", selection: $aiService.typingSpeed) {
                    ForEach(TypingSpeed.allCases, id: \.self) { speed in
                        Text(speed.displayName).tag(speed)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: aiService.typingSpeed) { _, _ in
                    aiService.saveAPIKey()
                }
            }
        }
        .padding(20)
    }
}

// MARK: - Thinking Indicator
struct ThinkingIndicator: View {
    @State private var isActive = false
    @State private var timer: Timer?
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "scribble.variable")
                .font(.system(size: 20))
                .foregroundColor(.secondary)
                .symbolEffect(.drawOn.wholeSymbol, isActive: isActive)
                .onAppear {
                    // Toggle isActive every 2 seconds to retrigger draw animation
                    timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                        isActive.toggle()
                    }
                    // Initial trigger
                    isActive = true
                }
                .onDisappear {
                    timer?.invalidate()
                }
            
            Text("Thinking...")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }
}
