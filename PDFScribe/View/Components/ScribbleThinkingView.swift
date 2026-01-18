import SwiftUI

/// A scribble/tangle thinking animation
/// Features a continuous line that draws into a messy scribble ball - like tangled thoughts
struct ScribbleThinkingView: View {
    @State private var progress: CGFloat = 0
    
    var body: some View {
        ScribblePath()
            .trim(from: 0, to: progress)
            .stroke(
                Color.primary.opacity(0.7),
                style: StrokeStyle(
                    lineWidth: 1.0,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            .frame(width: 80, height: 32)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    progress = 1.0
                }
            }
    }
}

// MARK: - Scribble Path Shape
struct ScribblePath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let centerX = width * 0.5
        let centerY = height * 0.5
        
        // Start with straight line from left
        path.move(to: CGPoint(x: 0, y: centerY))
        path.addLine(to: CGPoint(x: width * 0.2, y: centerY))
        
        let r: CGFloat = height * 0.38
        
        // Loop 1 - enter from left, swing up
        path.addCurve(
            to: CGPoint(x: centerX, y: centerY - r),
            control1: CGPoint(x: width * 0.25, y: centerY - r * 0.3),
            control2: CGPoint(x: centerX - r * 0.5, y: centerY - r * 1.1)
        )
        
        // Loop 2 - swing right and down
        path.addCurve(
            to: CGPoint(x: centerX + r * 0.7, y: centerY + r * 0.3),
            control1: CGPoint(x: centerX + r * 0.8, y: centerY - r * 0.9),
            control2: CGPoint(x: centerX + r * 1.0, y: centerY)
        )
        
        // Loop 3 - swing left across
        path.addCurve(
            to: CGPoint(x: centerX - r * 0.6, y: centerY - r * 0.2),
            control1: CGPoint(x: centerX + r * 0.3, y: centerY + r * 0.8),
            control2: CGPoint(x: centerX - r * 0.9, y: centerY + r * 0.5)
        )
        
        // Loop 4 - swing back right through center
        path.addCurve(
            to: CGPoint(x: centerX + r * 0.5, y: centerY - r * 0.5),
            control1: CGPoint(x: centerX - r * 0.3, y: centerY - r * 0.9),
            control2: CGPoint(x: centerX + r * 0.2, y: centerY - r * 0.8)
        )
        
        // Loop 5 - down and around
        path.addCurve(
            to: CGPoint(x: centerX - r * 0.4, y: centerY + r * 0.6),
            control1: CGPoint(x: centerX + r * 0.9, y: centerY - r * 0.1),
            control2: CGPoint(x: centerX + r * 0.4, y: centerY + r * 0.9)
        )
        
        // Loop 6 - back up through middle
        path.addCurve(
            to: CGPoint(x: centerX + r * 0.3, y: centerY + r * 0.2),
            control1: CGPoint(x: centerX - r * 0.8, y: centerY + r * 0.3),
            control2: CGPoint(x: centerX - r * 0.2, y: centerY - r * 0.3)
        )
        
        // Loop 7 - one more cross
        path.addCurve(
            to: CGPoint(x: centerX - r * 0.3, y: centerY),
            control1: CGPoint(x: centerX + r * 0.6, y: centerY + r * 0.6),
            control2: CGPoint(x: centerX, y: centerY + r * 0.4)
        )
        
        // Exit the scribble
        path.addCurve(
            to: CGPoint(x: width * 0.8, y: centerY),
            control1: CGPoint(x: centerX - r * 0.1, y: centerY - r * 0.3),
            control2: CGPoint(x: width * 0.7, y: centerY - r * 0.2)
        )
        
        // Straight line to right edge
        path.addLine(to: CGPoint(x: width, y: centerY))
        
        return path
    }
}

#Preview("Scribble Thinking") {
    VStack(spacing: 40) {
        VStack(alignment: .leading, spacing: 12) {
            Text("how are you doing")
                .font(.body)
            
            HStack(spacing: 6) {
                Circle()
                    .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                    .frame(width: 10, height: 10)
                Text("AI Assistant")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScribbleThinkingView()
                .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: 300, alignment: .leading)
    }
    .padding(40)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.windowBackgroundColor))
}
