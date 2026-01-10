import SwiftUI

struct FloatingInputView: View {
    @EnvironmentObject var aiViewModel: AIViewModel
    @State private var hoveredIcon: String? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            // Large centered icon (Perplexity logo placeholder)
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundColor(Color("SlateIndigo"))
                .padding(.bottom, 32)
            
            // Input container
            VStack(spacing: 0) {
                // Text input area
                TextField("Ask anything...", text: $aiViewModel.currentInput, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .lineLimit(1...10)
                    .padding(16)
                
                Divider()
                
                // Action bar
                HStack(spacing: 12) {
                    // Left side actions
                    HStack(spacing: 8) {
                        ActionButton(icon: "magnifyingglass", label: "Focus", isHovered: hoveredIcon == "focus") {
                            hoveredIcon = "focus"
                        } onHoverEnd: {
                            hoveredIcon = nil
                        }
                        
                        ActionButton(icon: "sparkles", label: "Pro", isHovered: hoveredIcon == "pro") {
                            hoveredIcon = "pro"
                        } onHoverEnd: {
                            hoveredIcon = nil
                        }
                        
                        ActionButton(icon: "lightbulb", label: "Reasoning", isHovered: hoveredIcon == "reasoning") {
                            hoveredIcon = "reasoning"
                        } onHoverEnd: {
                            hoveredIcon = nil
                        }
                    }
                    
                    Spacer()
                    
                    // Right side actions
                    HStack(spacing: 8) {
                        IconButton(icon: "photo", isHovered: hoveredIcon == "photo") {
                            hoveredIcon = "photo"
                        } onHoverEnd: {
                            hoveredIcon = nil
                        }
                        
                        IconButton(icon: "globe", isHovered: hoveredIcon == "globe") {
                            hoveredIcon = "globe"
                        } onHoverEnd: {
                            hoveredIcon = nil
                        }
                        
                        IconButton(icon: "paperclip", isHovered: hoveredIcon == "attach") {
                            hoveredIcon = "attach"
                        } onHoverEnd: {
                            hoveredIcon = nil
                        }
                        
                        IconButton(icon: "waveform", isHovered: hoveredIcon == "voice") {
                            hoveredIcon = "voice"
                        } onHoverEnd: {
                            hoveredIcon = nil
                        }
                        
                        IconButton(icon: "arrow.forward.circle.fill", isHovered: hoveredIcon == "code") {
                            hoveredIcon = "code"
                        } onHoverEnd: {
                            hoveredIcon = nil
                        }
                        
                        IconButton(icon: "mic.fill", isHovered: hoveredIcon == "mic") {
                            hoveredIcon = "mic"
                        } onHoverEnd: {
                            hoveredIcon = nil
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 4)
            .frame(maxWidth: 680)
        }
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let isHovered: Bool
    let onHover: () -> Void
    let onHoverEnd: () -> Void
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isHovered ? .primary : Color("WarmGray"))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering {
                onHover()
            } else {
                onHoverEnd()
            }
        }
    }
}

struct IconButton: View {
    let icon: String
    let isHovered: Bool
    let onHover: () -> Void
    let onHoverEnd: () -> Void
    
    var body: some View {
        Button(action: {}) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(isHovered ? .primary : Color("WarmGray"))
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering {
                onHover()
            } else {
                onHoverEnd()
            }
        }
    }
}
