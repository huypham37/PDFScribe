# Agent Mode Selector - Feature Plan

## Overview
Add a visual mode selector above the chat input field that displays available agent modes (Build, Explore, Research, etc.) as tags with rounded rectangles. Users can press Tab to cycle between modes.

## Visual Design (Based on Reference Image)
```
┌─────────────────────────────────────────────────────┐
│  [Build] [Explore] [Research]                       │  ← Mode selector area
├─────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────┐  │
│  │ Type your message...                          │  │  ← Input field
│  └───────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

### Tag Styling
- **Shape**: Rounded rectangle (capsule)
- **Active state**: Highlighted with accent color (purple/indigo)
- **Inactive state**: Gray/subtle background
- **Font**: Small, medium weight
- **Spacing**: 8px between tags
- **Padding**: 6px horizontal, 4px vertical

## Agent Modes to Support

### 1. **General** (default)
- Icon: `💬` or `bubble.left`
- Description: Standard chat mode
- Use case: Regular conversations

### 2. **Build** 
- Icon: `🔨` or `hammer`
- Description: Code generation and file modifications
- Use case: Writing code, creating files, making changes

### 3. **Explore**
- Icon: `🔍` or `magnifyingglass`
- Description: Codebase exploration and search
- Use case: Finding files, understanding structure

### 4. **Research**
- Icon: `📚` or `book`
- Description: Web research and fact-finding
- Use case: Looking up documentation, fetching external info

## Data Model

```swift
enum AgentMode: String, CaseIterable {
    case general = "General"
    case build = "Build"
    case explore = "Explore"
    case research = "Research"
    
    var icon: String {
        switch self {
        case .general: return "bubble.left"
        case .build: return "hammer"
        case .explore: return "magnifyingglass"
        case .research: return "book"
        }
    }
    
    var color: Color {
        switch self {
        case .general: return .blue
        case .build: return .purple
        case .explore: return .green
        case .research: return .orange
        }
    }
}
```

## Component Structure

### 1. **AgentModeSelector** (New View Component)
```swift
struct AgentModeSelector: View {
    @Binding var selectedMode: AgentMode
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(AgentMode.allCases, id: \.self) { mode in
                ModeTag(mode: mode, isSelected: mode == selectedMode) {
                    selectedMode = mode
                }
            }
        }
        .focused($isFocused)
        .onKeyPress(.tab) { handleTabPress() }
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
                Text(mode.rawValue)
            }
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? mode.color : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .secondary)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
```

### 2. **AIViewModel** (Update)
- Add `@Published var selectedMode: AgentMode = .general`
- Pass mode to AIService when sending messages

### 3. **AIPanel** (Update Input Area)
```swift
VStack(spacing: 8) {
    // Agent mode selector (NEW)
    AgentModeSelector(selectedMode: $viewModel.selectedMode)
        .padding(.horizontal, 16)
    
    // Existing input field
    HStack(alignment: .bottom, spacing: 8) {
        TextField("Message...", text: $inputText)
        // ... rest of input UI
    }
}
```

## Keyboard Navigation

### Tab Key Behavior
- **Press Tab**: Cycle to next mode (right)
- **Press Shift+Tab**: Cycle to previous mode (left)
- **Wrap around**: Research → General, General → Build (with Shift+Tab)

### Implementation
```swift
.onKeyPress(.tab) { press in
    let currentIndex = AgentMode.allCases.firstIndex(of: selectedMode) ?? 0
    let nextIndex = press.modifiers.contains(.shift) 
        ? (currentIndex - 1 + AgentMode.allCases.count) % AgentMode.allCases.count
        : (currentIndex + 1) % AgentMode.allCases.count
    selectedMode = AgentMode.allCases[nextIndex]
    return .handled
}
```

## Integration with AIService

### Update Message Sending
```swift
func sendMessage(_ content: String, mode: AgentMode) async {
    // Prepend mode instruction to system message or user message
    let modeInstruction = getModeInstruction(for: mode)
    let enhancedContent = mode == .general ? content : "\(modeInstruction)\n\n\(content)"
    
    // Send to AI with mode context
    await sendToAI(enhancedContent)
}

private func getModeInstruction(for mode: AgentMode) -> String {
    switch mode {
    case .general:
        return ""
    case .build:
        return "[Mode: Build] Focus on code generation and file modifications."
    case .explore:
        return "[Mode: Explore] Focus on codebase exploration and understanding structure."
    case .research:
        return "[Mode: Research] Use web research to find accurate information."
    }
}
```

## Files to Modify

1. **New Files**:
   - `PDFScribe/Model/AgentMode.swift` - Enum definition
   - `PDFScribe/View/Chat/AgentModeSelector.swift` - Mode selector component

2. **Modified Files**:
   - `PDFScribe/View/Chat/AIPanel.swift` - Integrate mode selector above input
   - `PDFScribe/ViewModel/AIViewModel.swift` - Add selectedMode property
   - `PDFScribe/Services/AIService.swift` - Accept mode parameter in sendMessage

## Testing Plan

1. **Visual Testing**:
   - Verify tags render correctly with rounded corners
   - Check active/inactive states display properly
   - Confirm spacing and alignment

2. **Interaction Testing**:
   - Click each mode tag to switch
   - Press Tab to cycle forward
   - Press Shift+Tab to cycle backward
   - Verify wrapping at boundaries

3. **Integration Testing**:
   - Send message in each mode
   - Verify mode instruction is prepended
   - Check AI responds appropriately to mode

## Open Questions

1. **Should mode persist across app restarts?**
   - Suggestion: Yes, add to AppState

2. **Should mode be session-specific or global?**
   - Suggestion: Global (same mode across all sessions)

3. **Should we show a tooltip explaining each mode?**
   - Suggestion: Yes, add `.help()` modifier to each tag

4. **Should pressing Enter in mode selector send the message?**
   - Suggestion: No, only Tab/Shift+Tab for navigation

## Next Steps (Implementation Order)

1. Create AgentMode enum
2. Create AgentModeSelector component
3. Add selectedMode to AIViewModel
4. Integrate selector into AIPanel above input field
5. Implement Tab key navigation
6. Update AIService to accept mode parameter
7. Test mode switching and message sending
8. Add mode persistence to AppState (optional)
