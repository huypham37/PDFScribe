import SwiftUI

struct AgentModeSelector: View {
    @Binding var selectedMode: AgentMode
    let availableModes: [AgentMode]
    
    var body: some View {
        HStack {
            // Single mode tag (left-aligned)
            ModeTag(
                mode: selectedMode,
                isSelected: true,
                onTap: {
                    // Cycle to next mode when clicked
                    cycleMode(forward: true)
                }
            )
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            // Invisible view to capture Shift+Tab globally
            ShiftTabHandler(onShiftTab: {
                cycleMode(forward: true)
            })
        )
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
        print("🔄 Cycled to mode: \(selectedMode.rawValue)")
    }
}

// MARK: - Shift+Tab Handler using NSEvent monitor
struct ShiftTabHandler: NSViewRepresentable {
    let onShiftTab: () -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = ShiftTabView()
        view.onShiftTab = onShiftTab
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let view = nsView as? ShiftTabView {
            view.onShiftTab = onShiftTab
        }
    }
    
    class ShiftTabView: NSView {
        var onShiftTab: (() -> Void)?
        var monitor: Any?
        
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            
            if window != nil && monitor == nil {
                monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                    // Check for Shift+Tab
                    if event.keyCode == 48 && event.modifierFlags.contains(.shift) {
                        self?.onShiftTab?()
                        return nil // Consume the event
                    }
                    return event
                }
            }
        }
        
        override func removeFromSuperview() {
            if let monitor = monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
            super.removeFromSuperview()
        }
        
        deinit {
            if let monitor = monitor {
                NSEvent.removeMonitor(monitor)
            }
        }
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
