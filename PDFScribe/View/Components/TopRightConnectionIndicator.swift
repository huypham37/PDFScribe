import SwiftUI

struct TopRightConnectionIndicator: View {
    let status: ConnectionStatus
    @State private var isPulsing = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Status dot with pulsing animation
            ZStack {
                // Pulsing outer ring for connecting state
                if status == .connecting {
                    Circle()
                        .stroke(statusColor.opacity(0.5), lineWidth: 2)
                        .frame(width: 16, height: 16)
                        .scaleEffect(isPulsing ? 1.8 : 1.0)
                        .opacity(isPulsing ? 0 : 0.6)
                }
                
                // Status dot
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                    .shadow(color: statusColor.opacity(0.5), radius: 4, x: 0, y: 2)
            }
            .frame(width: 16, height: 16)
            
            // Status text
            Text(status.displayText)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            Capsule()
                .stroke(statusColor.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            if status == .connecting {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
            }
        }
        .onChange(of: status) { _, newStatus in
            if newStatus == .connecting {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
            } else {
                isPulsing = false
            }
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .disconnected:
            return Color(nsColor: .systemRed)
        case .connecting:
            return Color(nsColor: .systemOrange)
        case .connected:
            return Color(nsColor: .systemGreen)
        }
    }
}

#Preview("Connected") {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        VStack {
            HStack {
                Spacer()
                TopRightConnectionIndicator(status: .connected)
            }
            Spacer()
        }
        .padding()
    }
}

#Preview("Connecting") {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        VStack {
            HStack {
                Spacer()
                TopRightConnectionIndicator(status: .connecting)
            }
            Spacer()
        }
        .padding()
    }
}

#Preview("Disconnected") {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        VStack {
            HStack {
                Spacer()
                TopRightConnectionIndicator(status: .disconnected)
            }
            Spacer()
        }
        .padding()
    }
}
