import SwiftUI

struct AgentModeSelector: View {
    @Binding var selectedMode: AgentMode
    let availableModes: [AgentMode]
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(availableModes) { mode in
                ModeTag(
                    mode: mode,
                    isSelected: mode == selectedMode,
                    onTap: {
                        selectedMode = mode
                    }
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .focusable()
        .focused($isFocused)
        .onKeyPress(.tab) {
            cycleMode(forward: true)
            return .handled
        }
        .onKeyPress(keys: [.tab], phases: .down) { press in
            if press.modifiers.contains(.shift) {
                cycleMode(forward: false)
                return .handled
            }
            return .ignored
        }
    }
    
    private func cycleMode(forward: Bool) {
        guard let currentIndex = availableModes.firstIndex(of: selectedMode) else { return }
        
        let nextIndex: Int
        if forward {
            nextIndex = (currentIndex + 1) % availableModes.count
        } else {
            nextIndex = (currentIndex - 1 + availableModes.count) % availableModes.count
        }
        
        selectedMode = availableModes[nextIndex]
    }
}

struct ModeTag: View {
    let mode: AgentMode
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: mode.icon)
                    .font(.system(size: 11))
                Text(mode.rawValue)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? mode.color : Color.gray.opacity(0.15))
            .foregroundColor(isSelected ? .white : .secondary)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .help(mode.description)
    }
}
