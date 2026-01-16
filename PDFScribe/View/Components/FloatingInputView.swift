import SwiftUI

struct FloatingInputView: View {
    @EnvironmentObject var aiViewModel: AIViewModel
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Large centered icon (Perplexity logo placeholder)
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundColor(.brandPrimary)
                .padding(.bottom, 32)
            
            // Input container with glass effect
            HStack(alignment: .bottom, spacing: 12) {
                TextField("Ask anything...", text: $aiViewModel.currentInput, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .lineLimit(1...10)
                    .focused($isFocused)
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
            .frame(maxWidth: 680)
            .glassBackground()
            .onKeyPress(.escape) {
                if aiViewModel.isProcessing {
                    aiViewModel.cancelRequest()
                    return .handled
                }
                return .ignored
            }
        }
        .onAppear {
            isFocused = true
        }
    }
}

