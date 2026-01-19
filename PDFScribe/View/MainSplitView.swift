import SwiftUI

struct MainSplitView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var aiViewModel: AIViewModel
    @EnvironmentObject var aiService: AIService
    
    var body: some View {
        NavigationSplitView {
            // Left sidebar - NavigationSplitView automatically applies Liquid Glass
            SidebarView()
                .environmentObject(appViewModel)
                .navigationSplitViewColumnWidth(280)
        } detail: {
            // Main content area with optional inspector
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Report/Chat content (left side of detail)
                    ZStack(alignment: .topTrailing) {
                        ZStack {
                            Color.brandBackground
                                .ignoresSafeArea()
                            
                            // Chat home view with centered input
                            if aiViewModel.messages.isEmpty {
                                FloatingInputView()
                                    .environmentObject(aiViewModel)
                            } else {
                                // Research document view - NYT editorial style
                                ReportView()
                                    .environmentObject(aiViewModel)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        // Connection status indicator in top-right corner (only on empty state)
                        if aiService.provider == .opencode && aiViewModel.messages.isEmpty {
                            ConnectionStatusView(state: aiService.connectionState)
                                .padding(.top, 16)
                                .padding(.trailing, 16)
                        }
                    }
                    .frame(width: aiViewModel.selectedCitationURL != nil ? geometry.size.width * 0.55 : geometry.size.width)
                    .transaction { $0.animation = nil }  // Force immediate frame update (fixes text jiggling)
                    
                    // Source Inspector (right side of detail, only when citation selected)
                    if let citationURL = aiViewModel.selectedCitationURL {
                        Divider()
                        
                        SourceInspectorView(
                            url: citationURL,
                            onClose: {
                                aiViewModel.closeCitation()
                            }
                        )
                        .frame(width: geometry.size.width * 0.45)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.25), value: citationURL)  // Animate inspector appearance
                    }
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 800, minHeight: 600)
    }
}

struct ChatConversationView: View {
    @EnvironmentObject var aiViewModel: AIViewModel
    
    var body: some View {
        VStack {
            // Message list with auto-scroll
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(aiViewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: aiViewModel.messages.last?.content) {
                    // Auto-scroll to the last message when content updates
                    if let lastMessage = aiViewModel.messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input at bottom
            HStack {
                TextField("Ask anything...", text: $aiViewModel.currentInput)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        aiViewModel.sendMessage()
                    }
                
                Button(action: {
                    aiViewModel.sendMessage()
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                }
                .buttonStyle(.plain)
                .disabled(aiViewModel.currentInput.isEmpty)
            }
            .padding()
        }
    }
}

struct MessageBubble: View {
    let message: StoredMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Circle()
                .fill(message.role == "user" ? Color.brandSecondary : Color.brandPrimary)
                .frame(width: 32, height: 32)
                .overlay(
                    Text(message.role == "user" ? "U" : "A")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            // Message content
            VStack(alignment: .leading, spacing: 4) {
                Text(message.role == "user" ? "You" : "Assistant")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Text(message.content)
                    .font(.system(size: 14))
                    .textSelection(.enabled)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
    }
}
