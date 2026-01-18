import SwiftUI

struct FloatingInputView: View {
    @EnvironmentObject var aiViewModel: AIViewModel
    @EnvironmentObject var aiService: AIService
    
    private var isInputDisabled: Bool {
        aiService.provider == .opencode && aiService.connectionState != .connected
    }
    
    private var placeholderText: String {
        if aiService.provider == .opencode && aiService.connectionState == .connecting {
            return "Connecting..."
        }
        return "Ask anything..."
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Large centered icon (Perplexity logo placeholder)
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundColor(.brandPrimary)
                .padding(.bottom, 32)
            
            // Input container with glass effect
            HStack(alignment: .bottom, spacing: 12) {
                TextField(placeholderText, text: $aiViewModel.currentInput, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .lineLimit(1...10)
                    .disabled(isInputDisabled)
                
                Button(action: {
                    aiViewModel.sendMessage()
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(aiViewModel.currentInput.isEmpty || isInputDisabled ? .gray : .brandAccent)
                }
                .buttonStyle(.plain)
                .disabled(aiViewModel.currentInput.isEmpty || isInputDisabled)
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding(16)
            .frame(maxWidth: 680)
            .glassBackground()
        }
    }
}

