import SwiftUI

struct ToolCallCard: View {
    let tool: ToolCall
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                // Icon
                Image(systemName: tool.metadata.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(tool.metadata.color)
                    .frame(width: 40, height: 40)
                    .background(tool.metadata.color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Name and type
                VStack(alignment: .leading, spacing: 2) {
                    Text(tool.metadata.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.brandText)
                    
                    Text(tool.name)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.brandSecondary)
                        .fontDesign(.monospaced)
                }
                
                Spacer()
                
                // Status indicator
                statusIndicator
            }
            .padding(16)
            .background(statusBackgroundColor)
            
            // Query section
            VStack(alignment: .leading, spacing: 8) {
                Text("QUERY")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.brandSecondary)
                    .tracking(0.5)
                
                Text(tool.query)
                    .font(.system(size: 13))
                    .fontDesign(.monospaced)
                    .foregroundColor(.brandText)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.brandBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(.brandBackgroundSecondary, lineWidth: 1)
                    )
            }
            .padding(16)
            
            // Progress bar (only for running state)
            if tool.status == .running {
                progressBar
            }
        }
        .background(.brandBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(borderColor, lineWidth: 2)
        )
        .shadow(color: Color.brandPrimary.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    @ViewBuilder
    private var statusIndicator: some View {
        switch tool.status {
        case .running:
            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(tool.metadata.color)
                
                Text("Running...")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(tool.metadata.color)
            }
            
        case .completed:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                Text("Complete")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.green)
            }
            
        case .failed:
            HStack(spacing: 6) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                
                Text("Failed")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.red)
            }
            
        case .cancelled:
            HStack(spacing: 6) {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.brandSecondary)
                
                Text("Cancelled")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.brandSecondary)
            }
        }
    }
    
    private var statusBackgroundColor: Color {
        switch tool.status {
        case .running:
            return tool.metadata.color.opacity(0.05)
        case .completed:
            return Color.green.opacity(0.05)
        case .failed:
            return Color.red.opacity(0.05)
        default:
            return .brandBackgroundSecondary
        }
    }
    
    private var borderColor: Color {
        switch tool.status {
        case .running:
            return tool.metadata.color.opacity(0.4)
        case .completed:
            return Color.green.opacity(0.3)
        case .failed:
            return Color.red.opacity(0.4)
        default:
            return .brandBackgroundSecondary
        }
    }
    
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(.brandBackgroundSecondary)
                
                // Progress (animated)
                Rectangle()
                    .fill(tool.metadata.color)
                    .frame(width: geometry.size.width * 0.6)
                    .opacity(0.8)
            }
        }
        .frame(height: 4)
    }
}

#Preview {
    VStack(spacing: 20) {
        ToolCallCard(tool: ToolCall(
            id: "1",
            name: "read",
            query: "/Users/mac/project/src/main.swift",
            status: .running
        ))
        
        ToolCallCard(tool: ToolCall(
            id: "2",
            name: "bash",
            query: "git status",
            status: .completed
        ))
        
        ToolCallCard(tool: ToolCall(
            id: "3",
            name: "glob",
            query: "**/*.swift",
            status: .failed
        ))
    }
    .padding()
    .frame(maxWidth: 500)
}
