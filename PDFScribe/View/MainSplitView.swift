import SwiftUI

struct MainSplitView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var aiViewModel: AIViewModel
    @EnvironmentObject var aiService: AIService
    
    @State private var showSplash: Bool = false
    @State private var splashDismissed: Bool = false
    @State private var showTopRightIndicator: Bool = false
    @State private var indicatorDismissTask: Task<Void, Never>?
    
    var body: some View {
        ZStack {
            // Main content
            NavigationSplitView {
                // Left sidebar - NavigationSplitView automatically applies Liquid Glass
                SidebarView()
                    .environmentObject(appViewModel)
                    .navigationSplitViewColumnWidth(280)
            } detail: {
                // Main content area (opaque - the "content is clear" principle)
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
            }
            .navigationSplitViewStyle(.balanced)
            .frame(minWidth: 800, minHeight: 600)
            .allowsHitTesting(!showSplash) // Block interaction when splash is showing
            
            // Top-right connection indicator (after splash dismisses, shows for 5 seconds)
            if showTopRightIndicator && aiService.provider == .opencode {
                VStack {
                    HStack {
                        Spacer()
                        TopRightConnectionIndicator(status: aiService.connectionStatus)
                            .padding(.top, 16)
                            .padding(.trailing, 16)
                    }
                    Spacer()
                }
                .transition(.opacity)
            }
            
            // Full-screen connection splash (blocks interaction)
            if showSplash {
                ConnectionSplashView(status: aiService.connectionStatus) {
                    // Callback: dismiss splash after checkmark animation completes
                    dismissSplashWithIndicator()
                }
                .transition(.opacity)
            }
        }
        .onChange(of: aiService.connectionStatus) { oldValue, newValue in
            handleConnectionStatusChange(oldValue: oldValue, newValue: newValue)
        }
        .onChange(of: aiService.provider) { oldValue, newValue in
            handleProviderChange(newValue: newValue)
        }
        .onAppear {
            // Show splash if starting with OpenCode provider
            if aiService.provider == .opencode {
                showSplash = true
                splashDismissed = false
            }
        }
    }
    
    private func handleConnectionStatusChange(oldValue: ConnectionStatus, newValue: ConnectionStatus) {
        guard aiService.provider == .opencode else { return }
        
        // Show splash when connecting
        if newValue == .connecting && !splashDismissed {
            withAnimation(.easeInOut(duration: 0.3)) {
                showSplash = true
            }
        }
        
        // Note: Splash dismissal is now handled by the callback from ConnectionSplashView
        // This allows the checkmark animation to complete before dismissing
        
        // Handle disconnection while splash is showing
        if newValue == .disconnected && showSplash {
            // Keep splash visible to show error state
            // User will need to retry or switch providers
        }
    }
    
    private func dismissSplashWithIndicator() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showSplash = false
            splashDismissed = true
            showTopRightIndicator = true
        }
        
        // Auto-dismiss top-right indicator after 5 seconds
        indicatorDismissTask?.cancel()
        indicatorDismissTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showTopRightIndicator = false
                }
            }
        }
    }
    
    private func handleProviderChange(newValue: AIProvider) {
        if newValue == .opencode {
            // Show splash when switching to OpenCode
            showSplash = true
            splashDismissed = false
            showTopRightIndicator = false
            indicatorDismissTask?.cancel()
        } else {
            // Hide splash and indicator for non-OpenCode providers
            showSplash = false
            splashDismissed = false
            showTopRightIndicator = false
            indicatorDismissTask?.cancel()
        }
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
