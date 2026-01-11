import SwiftUI

struct ToolCallSpotlightView: View {
    @ObservedObject var viewModel: AIViewModel
    
    @State private var currentTool: ToolCall?
    @State private var previousTool: ToolCall?
    @State private var isTransitioning = false
    
    var body: some View {
        VStack {
            if let activeTool = currentActiveTool {
                toolCardContainer(for: activeTool)
            }
        }
    }
    
    /// Returns the current running tool, or the most recently completed tool if none are running
    private var currentActiveTool: ToolCall? {
        // First, check for a running tool
        if let running = viewModel.currentToolCalls.first(where: { $0.status == .running }) {
            return running
        }
        // If no running tool, show the last tool (most recent)
        return viewModel.currentToolCalls.last
    }
    
    private var currentRunningTool: ToolCall? {
        viewModel.currentToolCalls.first(where: { $0.status == .running })
    }
    
    @ViewBuilder
    private func toolCardContainer(for running: ToolCall) -> some View {
        ZStack {
            // Previous tool sliding up
            if isTransitioning, let previous = previousTool {
                ToolCallCard(tool: previous)
                    .transition(.asymmetric(
                        insertion: .identity,
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
            
            // Current tool
            if !isTransitioning {
                ToolCallCard(tool: running)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
                    .onAppear {
                        // Detect tool change
                        if currentTool?.id != running.id {
                            handleToolChange(to: running)
                        }
                    }
            }
        }
        .frame(minHeight: 160)
        .animation(.easeOut(duration: 0.3), value: isTransitioning)
        .animation(.easeOut(duration: 0.3), value: running.id)
    }
    
    private func handleToolChange(to newTool: ToolCall) {
        if let current = currentTool {
            // Trigger slide-up animation
            withAnimation(.easeOut(duration: 0.3)) {
                isTransitioning = true
                previousTool = current
            }
            
            // After slide-up completes, show new tool
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.3)) {
                    currentTool = newTool
                    isTransitioning = false
                }
            }
        } else {
            // First tool, just show it
            currentTool = newTool
        }
    }
}

#Preview {
    ToolCallSpotlightView(viewModel: {
        let vm = AIViewModel(aiService: AIService())
        // Mock data would go here
        return vm
    }())
    .padding()
}
