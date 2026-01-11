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
                                PremiumQuerySection(
                                    query: aiViewModel.messages[index],
                                    response: index + 1 < aiViewModel.messages.count ? aiViewModel.messages[index + 1] : nil
                                )
                                .id(aiViewModel.messages[index].id)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                                
                                // Divider between sections (except after last)
                                if index + 2 < aiViewModel.messages.count {
                                    Divider()
                                        .background(Color(nsColor: NSColor(white: 0.9, alpha: 1.0)))
                                        .frame(height: 1)
                                        .padding(.horizontal, contentPadding)
                                        .padding(.vertical, 60)
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
                .foregroundColor(Color(nsColor: NSColor(white: 0.1, alpha: 1.0)))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding(.top, 48)
                .padding(.bottom, 32)
                .padding(.horizontal, contentPadding)
            
            // AI Response with collapsible sections
            if let response = response {
                EditorialResponseView(message: response, modelName: "AI Assistant")
                    .padding(.horizontal, contentPadding)
                    .padding(.bottom, 48)
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
                .font(.system(size: 15))
                .lineLimit(1...10)
                .padding(.vertical, 6)
            
            Button(action: {
                aiViewModel.sendMessage()
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(aiViewModel.currentInput.isEmpty || aiViewModel.isProcessing ? .gray : Color("SlateIndigo"))
            }
            .buttonStyle(.plain)
            .disabled(aiViewModel.currentInput.isEmpty || aiViewModel.isProcessing)
            .keyboardShortcut(.return, modifiers: [])
        }
        .padding(16)
        .glassBackground()
    }
}
