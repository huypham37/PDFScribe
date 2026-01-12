import SwiftUI

struct ToolCallTimelineView: View {
    let toolCalls: [ToolCall]
    @State private var viewMode: ViewMode = .collapsed
    
    enum ViewMode {
        case collapsed
        case timeline
        case tree
    }
    
    private var totalTime: TimeInterval {
        toolCalls.reduce(0) { $0 + $1.elapsedTime }
    }
    
    private var totalTimeString: String {
        String(format: "%.1fs", totalTime)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            switch viewMode {
            case .collapsed:
                collapsedView
            case .timeline:
                timelineView
            case .tree:
                treeView
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Collapsed View
    private var collapsedView: some View {
        Button {
            withAnimation { viewMode = .timeline }
        } label: {
            HStack(spacing: 16) {
                // Stacked icons
                HStack(spacing: -8) {
                    ForEach(toolCalls.prefix(4)) { tool in
                        Image(systemName: tool.metadata.iconName)
                            .font(.system(size: 16))
                            .foregroundColor(tool.metadata.color)
                            .frame(width: 32, height: 32)
                            .background(Color(nsColor: .windowBackgroundColor))
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(Color(nsColor: .windowBackgroundColor), lineWidth: 2))
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Execution Timeline")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("\(toolCalls.count) tools • \(totalTimeString) total")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Timeline View
    private var timelineView: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 16) {
                HStack(spacing: -8) {
                    ForEach(toolCalls.prefix(4)) { tool in
                        Image(systemName: tool.metadata.iconName)
                            .font(.system(size: 16))
                            .foregroundColor(tool.metadata.color)
                            .frame(width: 32, height: 32)
                            .background(Color(nsColor: .windowBackgroundColor))
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(Color(nsColor: .windowBackgroundColor), lineWidth: 2))
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Execution Timeline")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("\(toolCalls.count) tools • \(totalTimeString) total")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button {
                        withAnimation { viewMode = .tree }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.branch")
                                .font(.system(size: 12))
                            Text("Tree View")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.brandAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    
                    Button {
                        withAnimation { viewMode = .collapsed }
                    } label: {
                        Image(systemName: "chevron.up")
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Timeline content
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(toolCalls.enumerated()), id: \.element.id) { index, tool in
                        HStack(alignment: .top, spacing: 12) {
                            // Timeline dot and line
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 12, height: 12)
                                    .overlay(Circle().strokeBorder(Color(nsColor: .windowBackgroundColor), lineWidth: 2))
                                
                                if index < toolCalls.count - 1 {
                                    Rectangle()
                                        .fill(Color(nsColor: .separatorColor))
                                        .frame(width: 2)
                                        .frame(maxHeight: .infinity)
                                }
                            }
                            .frame(height: index < toolCalls.count - 1 ? 60 : 12)
                            
                            // Tool info
                            HStack {
                                Image(systemName: tool.metadata.iconName)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                
                                Text(tool.metadata.displayName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    Text("Complete")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    
                                    Text(tool.elapsedTimeString)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.top, -4)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, index == 0 ? 16 : 0)
                    }
                }
            }
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Tree View
    private var treeView: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "arrow.triangle.branch")
                    .foregroundColor(.brandSecondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Execution Flow Diagram")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("\(toolCalls.count) tools • \(totalTimeString) total")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    withAnimation { viewMode = .collapsed }
                } label: {
                    Image(systemName: "chevron.up")
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color.brandSecondary.opacity(0.05), Color.brandAccent.opacity(0.05)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            
            Divider()
            
            // Tree content
            ScrollView {
                VStack(spacing: 32) {
                    // Start node
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 20, height: 20)
                            .overlay(Circle().strokeBorder(Color(nsColor: .windowBackgroundColor), lineWidth: 4))
                            .shadow(color: Color.green.opacity(0.3), radius: 4)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            Text("Start Execution")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.green.opacity(0.3), lineWidth: 2)
                        )
                        
                        Spacer()
                    }
                    .padding(.leading, 24)
                    
                    // Tool nodes
                    ForEach(toolCalls) { tool in
                        HStack(alignment: .top, spacing: 0) {
                            // Branch connector
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(tool.metadata.color)
                                    .frame(width: 20, height: 20)
                                    .overlay(Circle().strokeBorder(Color(nsColor: .windowBackgroundColor), lineWidth: 4))
                                    .shadow(color: tool.metadata.color.opacity(0.3), radius: 4)
                            }
                            .padding(.top, 16)
                            
                            Rectangle()
                                .fill(Color(nsColor: .separatorColor))
                                .frame(width: 40, height: 2)
                                .padding(.top, 26)
                            
                            // Tool card (mini version)
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 12) {
                                    Image(systemName: tool.metadata.iconName)
                                        .font(.system(size: 20))
                                        .foregroundColor(tool.metadata.color)
                                        .frame(width: 48, height: 48)
                                        .background(tool.metadata.color.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(tool.metadata.displayName)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.primary)
                                        
                                        Text(tool.query)
                                            .font(.system(size: 11))
                                            .fontDesign(.monospaced)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color(nsColor: .controlBackgroundColor))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }
                                    
                                    Spacer()
                                }
                                
                                HStack {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle")
                                            .font(.system(size: 12))
                                        Text("Complete")
                                            .font(.system(size: 12))
                                    }
                                    .foregroundColor(.green)
                                    
                                    Spacer()
                                    
                                    Text(tool.elapsedTimeString)
                                        .font(.system(size: 11))
                                        .fontDesign(.monospaced)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(nsColor: .controlBackgroundColor))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                            }
                            .padding(16)
                            .background(Color(nsColor: .windowBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 2)
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        .padding(.leading, 24)
                    }
                    
                    // End node
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 20, height: 20)
                            .overlay(Circle().strokeBorder(Color(nsColor: .windowBackgroundColor), lineWidth: 4))
                            .shadow(color: Color.green.opacity(0.3), radius: 4)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Execution Complete")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.green)
                                
                                Text("Total time: \(totalTimeString)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.green.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.green.opacity(0.3), lineWidth: 2)
                        )
                        
                        Spacer()
                    }
                    .padding(.leading, 24)
                }
                .padding(32)
            }
        }
    }
}

#Preview {
    ToolCallTimelineView(toolCalls: [
        ToolCall(id: "1", name: "read", query: "/Users/mac/project/main.swift", status: .completed, toolType: .file),
        ToolCall(id: "2", name: "bash", query: "git status", status: .completed, toolType: .code),
        ToolCall(id: "3", name: "glob", query: "**/*.swift", status: .completed, toolType: .search),
        ToolCall(id: "4", name: "webfetch", query: "https://docs.anthropic.com", status: .completed, toolType: .web),
    ])
    .padding()
    .frame(maxWidth: 600)
}
