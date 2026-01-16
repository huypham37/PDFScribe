import SwiftUI

struct ConnectionSplashView: View {
    let status: ConnectionStatus
    let errorMessage: String?
    let onDismissAfterSuccess: (() -> Void)?
    let onRetry: (() -> Void)?
    
    @State private var showCheckmark = false
    @State private var scaleAnimation = false
    @State private var isSpinning = false
    
    init(
        status: ConnectionStatus,
        errorMessage: String? = nil,
        onDismissAfterSuccess: (() -> Void)? = nil,
        onRetry: (() -> Void)? = nil
    ) {
        self.status = status
        self.errorMessage = errorMessage
        self.onDismissAfterSuccess = onDismissAfterSuccess
        self.onRetry = onRetry
    }
    
    var body: some View {
        ZStack {
            // Background overlay - much lighter and friendlier
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)
            
            VStack(spacing: 32) {
                // Logo/Icon area
                ZStack {
                    // Outer pulsing ring (only during connecting)
                    if status == .connecting {
                        PulsingRing()
                    }
                    
                    // Main circle background
                    Circle()
                        .fill(circleBackgroundColor)
                        .frame(width: 100, height: 100)
                        .shadow(color: circleShadowColor, radius: 20, x: 0, y: 10)
                    
                    // Content based on status
                    if status == .connecting {
                        // Spinning loader with brand colors - uses continuous rotation
                        SpinningLoader(isSpinning: isSpinning)
                    } else if status == .connected {
                        // Success checkmark with animation
                        Image(systemName: "checkmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(showCheckmark ? 1.0 : 0.3)
                            .opacity(showCheckmark ? 1.0 : 0)
                    } else if status == .disconnected {
                        // Error state
                        Image(systemName: "xmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .frame(height: 120)
                
                // Status text
                VStack(spacing: 8) {
                    Text(titleText)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitleText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    // Show error message and retry button if disconnected
                    if status == .disconnected {
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 12))
                                .foregroundColor(.red.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                                .padding(.horizontal, 32)
                        }
                        
                        if let onRetry = onRetry {
                            Button(action: onRetry) {
                                Text("Retry Connection")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 10)
                                    .background(Color.brandPrimary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 16)
                        }
                    }
                }
            }
        }
        .onAppear {
            handleStatusOnAppear()
        }
        .onChange(of: status) { oldValue, newValue in
            handleStatusChange(from: oldValue, to: newValue)
        }
    }
    
    // MARK: - Status Handlers
    
    private func handleStatusOnAppear() {
        switch status {
        case .connecting:
            // Start spinning animation
            isSpinning = true
        case .connected:
            // If we appear already connected, show checkmark immediately
            showCheckmark = true
        case .disconnected:
            break
        }
    }
    
    private func handleStatusChange(from oldValue: ConnectionStatus, to newValue: ConnectionStatus) {
        if newValue == .connected && oldValue == .connecting {
            // Stop spinner, show checkmark with spring animation
            isSpinning = false
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showCheckmark = true
            }
            
            // Notify parent to dismiss after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                onDismissAfterSuccess?()
            }
        } else if newValue == .connecting {
            // Reset state for new connection attempt
            showCheckmark = false
            isSpinning = true
        }
    }
    
    // MARK: - Computed Properties
    
    private var circleBackgroundColor: Color {
        switch status {
        case .connecting:
            return Color.brandPrimary.opacity(0.15)
        case .connected:
            return Color.green.opacity(0.2)
        case .disconnected:
            return Color.gray.opacity(0.2)
        }
    }
    
    private var circleShadowColor: Color {
        switch status {
        case .connecting:
            return Color.brandPrimary.opacity(0.3)
        case .connected:
            return Color.green.opacity(0.4)
        case .disconnected:
            return Color.gray.opacity(0.3)
        }
    }
    
    private var titleText: String {
        switch status {
        case .connecting:
            return "Connecting to OpenCode"
        case .connected:
            return "Ready to Serve"
        case .disconnected:
            return "Connection Failed"
        }
    }
    
    private var subtitleText: String {
        switch status {
        case .connecting:
            return "Initializing AI service..."
        case .connected:
            return "Server is connected and ready"
        case .disconnected:
            return "Please check your OpenCode installation"
        }
    }
}

// MARK: - Subviews

/// Continuous spinning loader using TimelineView for smooth rotation
private struct SpinningLoader: View {
    let isSpinning: Bool
    
    var body: some View {
        TimelineView(.animation) { context in
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    AngularGradient(
                        colors: [.brandPrimary, .brandAccent, .brandPrimary],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(isSpinning ? context.date.timeIntervalSinceReferenceDate * 360 : 0))
        }
    }
}

/// Pulsing ring animation for connecting state
private struct PulsingRing: View {
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.8
    
    var body: some View {
        Circle()
            .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 3)
            .frame(width: 120, height: 120)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    scale = 1.4
                    opacity = 0
                }
            }
    }
}

// MARK: - Previews

#Preview("Connecting") {
    ConnectionSplashView(status: .connecting)
}

#Preview("Connected") {
    ConnectionSplashView(status: .connected)
}

#Preview("Disconnected") {
    ConnectionSplashView(status: .disconnected)
}

#Preview("Transition Demo") {
    ConnectionTransitionDemo()
}

/// Demo view to test the full transition
private struct ConnectionTransitionDemo: View {
    @State private var status: ConnectionStatus = .connecting
    
    var body: some View {
        ZStack {
            Color.gray
            
            ConnectionSplashView(status: status) {
                print("Dismissing splash!")
            }
            
            VStack {
                Spacer()
                Button("Simulate Connect") {
                    status = .connected
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 50)
            }
        }
    }
}
