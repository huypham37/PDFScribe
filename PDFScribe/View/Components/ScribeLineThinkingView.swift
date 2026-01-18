import SwiftUI

/// A subtle scribe-style horizontal line animation for AI thinking state
/// Features a thin black ink line that draws from left to right, like a pen writing
struct ScribeLineThinkingView: View {
    @State private var isAnimating = false
    
    private let lineLength: CGFloat = 100
    
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.primary.opacity(0.5))
                .frame(width: isAnimating ? lineLength : 0, height: 1)
        }
        .frame(width: lineLength, alignment: .leading)
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            isAnimating = true
        }
    }
}

// MARK: - Compact variant
struct ScribeLineThinkingViewCompact: View {
    @State private var isAnimating = false
    
    private let lineLength: CGFloat = 80
    
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.primary.opacity(0.4))
                .frame(width: isAnimating ? lineLength : 0, height: 1)
        }
        .frame(width: lineLength, alignment: .leading)
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        withAnimation(
            .easeInOut(duration: 1.2)
            .repeatForever(autoreverses: true)
        ) {
            isAnimating = true
        }
    }
}

#Preview("Scribe Line Thinking") {
    VStack(spacing: 60) {
        VStack(alignment: .leading, spacing: 16) {
            Text("Query")
                .font(.body)
            
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 8, height: 8)
                Text("AI Assistant")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScribeLineThinkingView()
                .padding(.top, 4)
            
            Text("Answer will appear here...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: 400, alignment: .leading)
        
        Divider()
        
        VStack(alignment: .leading, spacing: 16) {
            Text("Compact Version")
                .font(.caption)
                .foregroundColor(.secondary)
            ScribeLineThinkingViewCompact()
        }
    }
    .padding(60)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.windowBackgroundColor))
}
