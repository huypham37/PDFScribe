# PDFScribe Troubleshooting Guide

This document contains solutions to common issues encountered during development.

---

## SwiftUI Symbol Effects

### Issue: `.symbolEffect(.drawOn.wholeSymbol)` renders as invisible/blank

**Symptoms:**
- Using `.symbolEffect(.drawOn.wholeSymbol, options: .repeat(.continuous))` causes the SF Symbol to disappear completely
- The view renders but the icon is not visible
- No errors during compilation

**Root Cause:**
`.drawOn` is a **transition effect**, not a continuous animation effect. It is designed for one-time state changes (like appearing/disappearing), NOT for looping animations.

**Why `.repeat(.continuous)` fails:**
- `.drawOn` does not conform to `DiscreteSymbolEffect`, so it cannot use `value:` parameter for manual triggering
- Using `.repeat()` with `.drawOn` breaks the rendering engine, causing the symbol to render as invisible
- This is a known bug reported in Apple Developer Forums (Oct 2025) affecting macOS 26+

**Solution:**
Use the `isActive:` parameter with a Timer to manually toggle the state and retrigger the animation:

```swift
struct ThinkingIndicator: View {
    @State private var isActive = false
    @State private var timer: Timer?
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "scribble.variable")
                .font(.system(size: 20))
                .foregroundColor(.secondary)
                .symbolEffect(.drawOn.wholeSymbol, isActive: isActive)
                .onAppear {
                    // Toggle isActive every 2 seconds to retrigger draw animation
                    timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                        isActive.toggle()
                    }
                    // Initial trigger
                    isActive = true
                }
                .onDisappear {
                    timer?.invalidate()
                }
            
            Text("Thinking...")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }
}
```

**Key Points:**
- Use `scribble.variable` (works better than `scribble` for drawing effects)
- Toggle `isActive` state with a Timer (2 seconds recommended for drawing duration)
- Clean up timer in `.onDisappear` to prevent memory leaks
- Set initial `isActive = true` to trigger first animation immediately

**Alternative Solutions:**
1. **Use `.variableColor` instead** - Works natively with `.repeat(.continuous)`:
   ```swift
   .symbolEffect(.variableColor.iterative, options: .repeat(.continuous))
   ```

2. **Use `.pulse` effect** - Another continuous animation that works out of the box:
   ```swift
   .symbolEffect(.pulse, options: .repeat(.continuous))
   ```

**References:**
- Apple Developer Forums: "SF Symbols .drawOn effect not displaying" (Oct 2025)
- WWDC25 Session: "What's new in SF Symbols 7"
- Hacking with Swift: "How to make SF Symbols draw themselves"

**Tested On:**
- macOS 26.2 (deployment target: macOS 26.0)
- Xcode with Swift 6
- PDFScribe v0.1.0

**Related Files:**
- `PDFScribe/View/Chat/AIPanel.swift` - ThinkingIndicator component
- `PDFScribe/View/TestSymbolView.swift` - Test harness for symbol effects

---

## Future Issues

(Add new troubleshooting entries here as they are discovered)
