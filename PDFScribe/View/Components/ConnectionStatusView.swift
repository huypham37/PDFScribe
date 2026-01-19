import SwiftUI

struct ConnectionStatusView: View {
    let state: ConnectionState
    @State private var isVisible: Bool = true
    @State private var pulseOpacity: Double = 1.0
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
                .opacity(state == .connecting ? pulseOpacity : 1.0)
                .animation(
                    state == .connecting 
                        ? Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                        : .default,
                    value: pulseOpacity
                )
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.8))
        )
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: isVisible)
        .onAppear {
            if state == .connecting {
                pulseOpacity = 0.3
            }
        }
        .onChange(of: state) { oldValue, newValue in
            isVisible = true
            
            // Start pulsing animation for connecting state
            if newValue == .connecting {
                pulseOpacity = 0.3
            } else {
                pulseOpacity = 1.0
            }
            
            // Auto-hide after 5 seconds for connected state
            if newValue == .connected {
                Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    withAnimation {
                        isVisible = false
                    }
                }
            }
        }
    }
    
    private var dotColor: Color {
        switch state {
        case .disconnected:
            return .gray
        case .connecting:
            return .gray
        case .connected:
            return .green
        case .failed:
            return .red
        }
    }
    
    private var statusText: String {
        switch state {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .failed:
            return "Connection failed"
        }
    }
}
