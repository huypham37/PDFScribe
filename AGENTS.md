# AGENTS.md - PDFScribe Developer Guide

This document provides guidelines for AI coding agents working on the PDFScribe codebase.

## Project Overview

This is a native MacOS app, cloning Perplexity for researching topics using opencode as AI service.

## AI Service Architecture

The app drives its research capabilities using **OpenCode**, a local AI service. Interaction is handled via the **Agent Context Protocol (ACP)** (JSON-RPC over stdio), which manages:

- **Sessions**: Stateful conversation contexts with persistent history
- **Context**: Efficient transport of file contents, editor selections, and PDF text as resources
- **Delegation**: Support for specialized modes (e.g., `research-leader`) and sub-agent task execution
- **Tool Calls**: Real-time tracking of agent actions and delegations to sub-agents

**Key Implementation Files:**
- `PDFScribe/Services/AIService.swift` - Main service orchestration and session management
- `PDFScribe/Services/Strategies/OpenCodeStrategy.swift` - ACP protocol implementation and JSON-RPC communication

## IMPORTANT

- Always following the liquid glass guidelines at @assets/liquid-glass-doc
- only use build without debug. report to user if build failed to enable debugging.
## Liquid Glass Implementation (macOS 26+)

**Quick Reference:**

1. **Use NavigationSplitView** - Automatic glass effect on sidebar when built with Xcode 26
   ```swift
   NavigationSplitView {
       SidebarView()  // Gets automatic glass effect
   } detail: {
       ContentView()  // Stays opaque
   }
   ```

2. **Apply to Navigation Only** - Glass for sidebars/toolbars, NOT content
   - ✅ Sidebars, toolbars, floating controls
   - ❌ Lists, tables, editors, media

3. **Manual Application** - For custom views:
   ```swift
   MyView()
       .glassEffect()  // Default shape
       .glassEffect(in: RoundedRectangle(cornerRadius: 12))  // Custom shape
   ```

4. **Backward Compatibility** - Fallback for macOS < 26:
   ```swift
   @ViewBuilder
   func glassBackground() -> some View {
       if #available(macOS 26.0, *) {
           self.glassEffect()
       } else {
           self.background(.ultraThinMaterial)
       }
   }
   ```

5. **Key Rules:**
   - Remove custom backgrounds that interfere
   - Glass needs colorful content underneath to show refraction
   - Don't over-apply - follow "navigation only" principle

## Code Style Guidelines

### Philosophy: Minimalism
- **Write minimal code that works** (this strictly applies to code style not design)
- Break code into small, focused classes/functions
- Avoid over-engineering and premature abstraction
- Prefer clarity over cleverness



### Swift Formatting
- **Indentation**: 4 spaces (no tabs)
- **Line length**: No hard limit, but aim for readability (~120 chars)
- **Braces**: Opening brace on same line
```swift
func example() {
    // code
}
```
- **Spacing**: One blank line between functions, two between major sections

### Naming Conventions
- **Classes/Structs/Enums**: PascalCase (`PDFViewModel`, `AIService`)
- **Functions/Variables**: camelCase (`loadPDF`, `currentPage`)
- **Constants**: camelCase (`maxFileSize`, `debounceInterval`)
- **Private properties**: Use `private` keyword, same naming as public
- **Booleans**: Use `is`, `has`, `should` prefixes (`isEditable`, `hasSelection`)



### Github issues:

- always use gh issue list --limit 20 for listing issues





