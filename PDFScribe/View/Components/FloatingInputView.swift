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
            TextField("Ask anything...", text: $aiViewModel.currentInput, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .lineLimit(1...10)
                .padding(16)
                .frame(maxWidth: 680)
                .glassBackground()
        }
    }
}

