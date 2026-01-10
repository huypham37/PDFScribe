import SwiftUI

struct FloatingInputView: View {
    @EnvironmentObject var aiViewModel: AIViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Large centered icon (Perplexity logo placeholder)
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundColor(Color("SlateIndigo"))
                .padding(.bottom, 32)
            
            // Input container with glass effect
            HStack(alignment: .bottom, spacing: 12) {
                TextField("Ask anything...", text: $aiViewModel.currentInput, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .lineLimit(1...10)
                    .onSubmit {
                        aiViewModel.sendMessage()
                    }
                
                Button(action: {
                    aiViewModel.sendMessage()
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(aiViewModel.currentInput.isEmpty ? .gray : Color("SlateIndigo"))
                }
                .buttonStyle(.plain)
                .disabled(aiViewModel.currentInput.isEmpty)
            }
            .padding(16)
            .frame(maxWidth: 680)
            .glassBackground()
        }
    }
}

