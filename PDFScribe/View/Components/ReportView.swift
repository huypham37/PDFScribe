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
                .onChange(of: aiViewModel.messages.count) {
                    // Auto-scroll to show new query with animation
                    if let lastMessage = aiViewModel.messages.last {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            proxy.scrollTo(lastMessage.id, anchor: .top)
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
                .padding(.bottom, 32)
                .padding(.horizontal, contentPadding)
            
            // AI Response with collapsible sections
            if let response = response {
                EditorialResponseView(message: response, modelName: "AI Assistant")
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
                .padding(.bottom, 32)
                .padding(.horizontal, contentPadding)
            
            // Tool Call Display
            // For the current processing message, show currentToolCalls
            // For completed messages, show the message's own toolCalls
            let isCurrentMessage = aiViewModel.isProcessing && response == aiViewModel.messages.last
            let toolCallsToShow = isCurrentMessage ? aiViewModel.currentToolCalls : (response?.toolCalls ?? [])
            
            if !toolCallsToShow.isEmpty {
                // Compact tool call display - same for running and completed
                CompactToolCallView(toolCalls: toolCallsToShow)
                    .padding(.horizontal, contentPadding)
                    .padding(.bottom, 24)
            }
            
            // AI Response
            if let response = response {
                EditorialResponseView(message: response, modelName: "AI Assistant")
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
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            TextField("Ask anything...", text: $aiViewModel.currentInput, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .lineLimit(1...10)
                .padding(.vertical, 6)
                .focused($isFocused)
                .disabled(aiViewModel.isProcessing)
                .onSubmit {
                    if !aiViewModel.isProcessing {
                        aiViewModel.sendMessage()
                    }
                }
            
            Button(action: {
                if aiViewModel.isProcessing {
                    aiViewModel.cancelRequest()
                } else {
                    aiViewModel.sendMessage()
                }
            }) {
                Image(systemName: aiViewModel.isProcessing ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(aiViewModel.isProcessing ? .red : (aiViewModel.currentInput.isEmpty ? .gray : .brandAccent))
            }
            .buttonStyle(.plain)
            .disabled(!aiViewModel.isProcessing && aiViewModel.currentInput.isEmpty)
            .keyboardShortcut(.return, modifiers: [])
        }
        .padding(16)
        .glassBackground()
        .onKeyPress(.escape) {
            if aiViewModel.isProcessing {
                aiViewModel.cancelRequest()
                return .handled
            }
            return .ignored
        }
    }
}
