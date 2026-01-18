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
                        ForEach(Array(stride(from: 0, to: aiViewModel.messages.count, by: 2)), id: \.self) { index in
                            if index < aiViewModel.messages.count {
                                PremiumQuerySectionWithTools(
                                    query: aiViewModel.messages[index],
                                    response: index + 1 < aiViewModel.messages.count ? aiViewModel.messages[index + 1] : nil
                                )
                                .environmentObject(aiViewModel)
                                .id(aiViewModel.messages[index].id)
                                .padding(.top, index == 0 ? 32 : 0)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                                
                                // Divider between sections (except after last)
                                if index + 2 < aiViewModel.messages.count {
                                    Divider()
                                        .background(Color.brandBackgroundSecondary)
                                        .frame(height: 1)
                                        .padding(.horizontal, contentPadding)
                                        .padding(.vertical, 24)
                                }
                            }
                        }
                        
                        // Bottom padding for floating input
                        Color.clear.frame(height: 140)
                    }
                }
                .onChange(of: aiViewModel.messages.count) { oldCount, newCount in
                    print("🔄 [ReportView] Messages count changed: \(oldCount) -> \(newCount)")
                    
                    // Scroll to show new query at top of viewport
                    // Query is at index count-2 (user), response is at count-1 (assistant)
                    guard newCount >= 2 else { 
                        print("⚠️ [ReportView] Not enough messages to scroll")
                        return 
                    }
                    
                    let queryIndex = newCount - 2
                    guard queryIndex >= 0 && queryIndex < aiViewModel.messages.count else {
                        print("⚠️ [ReportView] Invalid query index: \(queryIndex)")
                        return
                    }
                    
                    let queryId = aiViewModel.messages[queryIndex].id
                    print("📍 [ReportView] Will scroll to query at index \(queryIndex), id: \(queryId)")
                    
                    // Delay slightly to ensure view has rendered
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
                        print("✅ [ReportView] Executing scroll to \(queryId)")
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                            proxy.scrollTo(queryId, anchor: .top)
                        }
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
