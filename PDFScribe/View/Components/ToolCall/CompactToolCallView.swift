import SwiftUI

struct CompactToolCallView: View {
    let toolCalls: [ToolCall]
    
    var body: some View {
        if toolCalls.count == 1, let tool = toolCalls.first {
            // Single tool - no expand/collapse
            CompactToolCallPill(tool: tool)
        } else if toolCalls.count > 1 {
            // Multiple tools - show as vertical stack with subtle tree
            MultipleToolCallsView(toolCalls: toolCalls)
        }
    }
}

// MARK: - Animated Color Text View (Mask-based sweep)
struct AnimatedColorText: View {
    let text: String
    /// 0...1: how much of the text is "filled" with toColor
    let progress: CGFloat
    let fromColor: Color
    let toColor: Color
    
    var body: some View {
        Text(text)
            .foregroundColor(fromColor) // base moss/brandSecondary
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    let width = proxy.size.width * max(0, min(1, progress))
                    
                    Text(text)
                        .foregroundColor(toColor) // sweep color (charcoal/brandPrimary)
                        .mask(
                            HStack {
                                Rectangle()
                                    .frame(width: width)
                                Spacer(minLength: 0)
                            }
                        )
                }
                .allowsHitTesting(false)
            }
    }
}

// MARK: - Single Tool Pill
struct CompactToolCallPill: View {
    let tool: ToolCall
    
    @State private var colorProgress: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 10) {
            // Icon
            Image(systemName: tool.metadata.iconName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(tool.status == .completed ? .brandPrimary : .brandSecondary)
                .frame(width: 20, height: 20)
            
            // Text content
            VStack(alignment: .leading, spacing: 2) {
                // Tool name (monospace, subtle)
                Text(tool.name)
                    .font(.system(size: 11, weight: .medium))
                    .fontDesign(.monospaced)
                    .foregroundColor(.brandPrimary.opacity(0.6))
                
                // Display name with animated color transition
                AnimatedColorText(
                    text: tool.metadata.displayName,
                    progress: colorProgress,
                    fromColor: Color.brandSecondary,
                    toColor: Color.brandPrimary
                )
                .font(.system(size: 13, weight: .semibold))
                .animation(.linear(duration: 2.0), value: colorProgress)
            }
            
            Spacer()
            
            // Status indicator
            statusIndicator
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.brandBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.brandBackgroundSecondary, lineWidth: 1)
        )
        .onChange(of: tool.status) { _, newStatus in
            switch newStatus {
            case .running:
                startRunningAnimation()
            case .completed:
                // Smoothly fill to charcoal
                withAnimation(.easeOut(duration: 0.25)) {
                    colorProgress = 1.0
                }
            default:
                break
            }
        }
        .onAppear {
            if tool.status == .running {
                startRunningAnimation()
            } else if tool.status == .completed {
                colorProgress = 1.0
            }
        }
    }
    
    private func startRunningAnimation() {
        colorProgress = 0
        // Single smooth sweep from left to right
        withAnimation(.linear(duration: 2.0)) {
            colorProgress = 1.0
        }
    }
    
    @ViewBuilder
    private var statusIndicator: some View {
        switch tool.status {
        case .running:
            // Pulsing dot
            Circle()
                .fill(Color.brandSecondary)
                .frame(width: 8, height: 8)
                .modifier(PulsingModifier())
            
        case .completed:
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.brandSecondary)
            
        case .failed:
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.red)
            
        case .cancelled:
            Image(systemName: "minus")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.brandPrimary.opacity(0.5))
        }
    }
}

// MARK: - Multiple Tools View
struct MultipleToolCallsView: View {
    let toolCalls: [ToolCall]
    @State private var isExpanded = false
    
    private var completedCount: Int {
        toolCalls.filter { $0.status == .completed }.count
    }
    
    private var isAllCompleted: Bool {
        toolCalls.allSatisfy { $0.status == .completed }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - always visible
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    // Stacked icons
                    ZStack {
                        ForEach(Array(toolCalls.prefix(3).enumerated()), id: \.element.id) { index, tool in
                            Image(systemName: tool.metadata.iconName)
                                .font(.system(size: 12))
                                .foregroundColor(isAllCompleted ? .brandPrimary : .brandSecondary)
                                .frame(width: 18, height: 18)
                                .background(Color.brandBackground)
                                .clipShape(Circle())
                                .overlay(Circle().strokeBorder(Color.brandBackgroundSecondary, lineWidth: 1))
                                .offset(x: CGFloat(index) * 8)
                        }
                    }
                    .frame(width: 40, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(toolCalls.count) tools")
                            .font(.system(size: 11, weight: .medium))
                            .fontDesign(.monospaced)
                            .foregroundColor(.brandPrimary.opacity(0.6))
                        
                        Text(isAllCompleted ? "Completed" : "Running...")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(isAllCompleted ? .brandPrimary : .brandSecondary)
                    }
                    
                    Spacer()
                    
                    // Progress or checkmark
                    if isAllCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.brandSecondary)
                    } else {
                        Text("\(completedCount)/\(toolCalls.count)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.brandSecondary)
                    }
                    
                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.brandPrimary.opacity(0.4))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            
            // Expanded list
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(Array(toolCalls.enumerated()), id: \.element.id) { index, tool in
                        HStack(spacing: 8) {
                            // Tree line
                            VStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color.brandBackgroundSecondary)
                                    .frame(width: 1)
                                    .frame(maxHeight: index == 0 ? 10 : .infinity)
                                
                                Circle()
                                    .fill(tool.status == .completed ? Color.brandSecondary : Color.brandBackgroundSecondary)
                                    .frame(width: 6, height: 6)
                                
                                if index < toolCalls.count - 1 {
                                    Rectangle()
                                        .fill(Color.brandBackgroundSecondary)
                                        .frame(width: 1)
                                        .frame(maxHeight: .infinity)
                                }
                            }
                            .frame(width: 20)
                            
                            // Tool info
                            HStack(spacing: 8) {
                                Image(systemName: tool.metadata.iconName)
                                    .font(.system(size: 12))
                                    .foregroundColor(tool.status == .completed ? .brandPrimary : .brandSecondary)
                                    .frame(width: 16)
                                
                                Text(tool.metadata.displayName)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(tool.status == .completed ? .brandPrimary : .brandSecondary)
                                
                                Spacer()
                                
                                if tool.status == .completed {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.brandSecondary)
                                } else if tool.status == .running {
                                    Circle()
                                        .fill(Color.brandSecondary)
                                        .frame(width: 6, height: 6)
                                        .modifier(PulsingModifier())
                                }
                            }
                            .padding(.vertical, 6)
                        }
                        .frame(height: 32)
                    }
                }
                .padding(.leading, 24)
                .padding(.trailing, 12)
                .padding(.bottom, 8)
            }
        }
        .background(Color.brandBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.brandBackgroundSecondary, lineWidth: 1)
        )
    }
}

// MARK: - Pulsing Animation Modifier
struct PulsingModifier: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.4 : 1.0)
            .scaleEffect(isPulsing ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear {
                isPulsing = true
            }
    }
}

#Preview("Single Tool - Running") {
    CompactToolCallView(toolCalls: [
        ToolCall(id: "1", name: "glob", query: "**/*.swift", status: .running)
    ])
    .padding()
    .frame(maxWidth: 300)
}

#Preview("Single Tool - Completed") {
    CompactToolCallView(toolCalls: [
        ToolCall(id: "1", name: "bash", query: "pwd", status: .completed)
    ])
    .padding()
    .frame(maxWidth: 300)
}

#Preview("Multiple Tools") {
    CompactToolCallView(toolCalls: [
        ToolCall(id: "1", name: "read", query: "main.swift", status: .completed),
        ToolCall(id: "2", name: "bash", query: "git status", status: .completed),
        ToolCall(id: "3", name: "glob", query: "**/*.swift", status: .running)
    ])
    .padding()
    .frame(maxWidth: 300)
}
