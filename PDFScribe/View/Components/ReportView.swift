import SwiftUI

struct ReportView: View {
    @EnvironmentObject var aiViewModel: AIViewModel
    
    private let contentPadding: CGFloat = 100
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main scrollable content
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .center, spacing: 0) {
                        // Group messages into query-response pairs
                        ForEach(0..<(aiViewModel.messages.count / 2 + aiViewModel.messages.count % 2), id: \.self) { pairIndex in
                            let index = pairIndex * 2
                            if index < aiViewModel.messages.count {
                            let queryMessage = aiViewModel.messages[index]
                            
                            VStack(alignment: .leading, spacing: 0) {
                                PremiumQuerySectionWithTools(
                                    query: queryMessage,
                                    response: index + 1 < aiViewModel.messages.count ? aiViewModel.messages[index + 1] : nil
                                )
                                .environmentObject(aiViewModel)
                                .id("anchor-\(queryMessage.id)")  // Attach ID directly to the real view
                                
                                // Divider between sections (except after last)
                                if index + 2 < aiViewModel.messages.count {
                                    Divider()
                                        .background(Color.brandBackgroundSecondary)
                                        .frame(height: 1)
                                        .padding(.horizontal, contentPadding)
                                        .padding(.vertical, 32)
                                }
                            }
                        }
                        }
                        
                        // Phantom spacer - provides scroll runway so new queries can reach the top
                        // Height roughly matches screen height to ensure proper scrolling
                        Color.clear
                            .frame(height: 600)
                            .id("phantom-spacer")
                    }
                }
                .onChange(of: aiViewModel.messages.count) { oldCount, newCount in
                    print("🔄 [Scroll] Messages count changed: \(oldCount) -> \(newCount)")
                    
                    // Scroll when a new Q&A pair is added (count increases by 2)
                    // This happens when user sends a message (user msg + assistant placeholder added together)
                    guard newCount > oldCount && newCount >= 2 else {
                        print("⚠️ [Scroll] Not enough messages or count didn't increase, skipping")
                        return
                    }
                    
                    // Find the new user query (second-to-last message)
                    let queryIndex = newCount - 2
                    guard queryIndex >= 0 && queryIndex < aiViewModel.messages.count else {
                        print("⚠️ [Scroll] Invalid queryIndex: \(queryIndex)")
                        return
                    }
                    
                    // Verify it's actually a user message
                    guard aiViewModel.messages[queryIndex].role == "user" else {
                        print("⚠️ [Scroll] Message at index \(queryIndex) is not a user message, skipping")
                        return
                    }
                    
                    let queryId = aiViewModel.messages[queryIndex].id
                    let anchorId = "anchor-\(queryId)"
                    print("📍 [Scroll] Will scroll to new query: \(anchorId)")
                    
                    // Scroll immediately when user sends message (before streaming starts)
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s delay for anchor to appear
                        print("✅ [Scroll] Executing scrollTo(\(anchorId), anchor: .top)")
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(anchorId, anchor: .top)
                        }
                        print("✅ [Scroll] scrollTo completed")
                    }
                }
            }
            
            // Floating input at bottom
            VStack {
                Spacer()
                FloatingInput()
                    .environmentObject(aiViewModel)
                    .padding(.horizontal, contentPadding)
                    .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - Premium Query Section Component
struct PremiumQuerySection: View {
    @EnvironmentObject var aiService: AIService
    let query: StoredMessage
    let response: StoredMessage?
    
    private let contentPadding: CGFloat = 100
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // User query - clean typography
            Text(query.content)
                .font(.system(size: 17))
                .foregroundColor(.brandText)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding(.top, 32)
                .padding(.bottom, 16)
                .padding(.horizontal, contentPadding)
            
            // AI Response with collapsible sections
            if let response = response {
                EditorialResponseView(message: response, modelName: aiService.currentModel?.name ?? aiService.provider.rawValue)
                    .padding(.horizontal, contentPadding)
                    .padding(.bottom, 32)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Query Section with Tool Calls
struct PremiumQuerySectionWithTools: View {
    @EnvironmentObject var aiViewModel: AIViewModel
    @EnvironmentObject var aiService: AIService
    let query: StoredMessage
    let response: StoredMessage?
    
    private let contentPadding: CGFloat = 100
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // User query
            Text(query.content)
                .font(.system(size: 17))
                .foregroundColor(.brandText)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding(.top, 32)
                .padding(.bottom, 16)
                .padding(.horizontal, contentPadding)
            
            // Tool Call Display
            // For the current processing message, show currentToolCalls
            // For completed messages, show the message's own toolCalls
            let isCurrentMessage = aiViewModel.isProcessing && response == aiViewModel.messages.last
            let toolCallsToShow = isCurrentMessage ? aiViewModel.currentToolCalls : (response?.toolCalls ?? [])
            
            if !toolCallsToShow.isEmpty {
                if isCurrentMessage && aiViewModel.isProcessing {
                    // During execution - show spotlight for current running tool
                    ToolCallSpotlightView(viewModel: aiViewModel)
                        .padding(.horizontal, contentPadding)
                        .padding(.bottom, 24)
                } else {
                    // After completion - show collapsed timeline
                    ToolCallTimelineView(toolCalls: toolCallsToShow)
                        .padding(.horizontal, contentPadding)
                        .padding(.bottom, 24)
                }
            }
            
            // AI Response
            if let response = response {
                EditorialResponseView(message: response, modelName: aiService.currentModel?.name ?? aiService.provider.rawValue)
                    .padding(.horizontal, contentPadding)
                    .padding(.bottom, 32)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Floating Input Component
struct FloatingInput: View {
    @EnvironmentObject var aiViewModel: AIViewModel
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            TextField("Ask anything...", text: $aiViewModel.currentInput, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 17))
                .lineLimit(1...10)
                .padding(.leading, 8)
            
            Button(action: {
                aiViewModel.sendMessage()
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(aiViewModel.currentInput.isEmpty || aiViewModel.isProcessing ? .gray : .brandAccent)
            }
            .buttonStyle(.plain)
            .disabled(aiViewModel.currentInput.isEmpty || aiViewModel.isProcessing)
            .keyboardShortcut(.return, modifiers: [])
        }
        .padding(.vertical, 16)
        .padding(.leading, 16)
        .padding(.trailing, 16)
        .glassBackground()
    }
}
