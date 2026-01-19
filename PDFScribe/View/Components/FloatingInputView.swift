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
            HStack(alignment: .center, spacing: 12) {
                TextField(placeholderText, text: $aiViewModel.currentInput, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 17))
                    .lineLimit(1...10)
                    .disabled(isInputDisabled)
                    .padding(.leading, 8)
                
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
            .padding(.vertical, 16)
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .frame(maxWidth: 680)
            .glassBackground()
        }
    }
}

