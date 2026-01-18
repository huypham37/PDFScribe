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
- When I ask you to implement an UI element, always implement it in isolated, separted view before integrating.


## Guidelines when working with Frontend:

- When working with new windows, always provides a wireframes before executing. 
- I ask you to break view into modular components instead putting everything into a single, massive file. 
- ALWAYS: give me the wireframes before executing.



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

## Project Structure

```
PDFScribe/
├── AGENTS.md
├── Makefile
├── PDFScribe/
│   ├── Assets.xcassets/
│   │   ├── AccentColor.colorset/
│   │   │   └── Contents.json
│   │   ├── AppIcon.appiconset/
│   │   │   └── Contents.json
│   │   ├── BrandAccent.colorset/
│   │   │   └── Contents.json
│   │   ├── BrandBackground.colorset/
│   │   │   └── Contents.json
│   │   ├── BrandBackgroundSecondary.colorset/
│   │   │   └── Contents.json
│   │   ├── BrandPrimary.colorset/
│   │   │   └── Contents.json
│   │   ├── BrandSecondary.colorset/
│   │   │   └── Contents.json
│   │   ├── BrandText.colorset/
│   │   │   └── Contents.json
│   │   ├── Contents.json
│   │   ├── PaperWhite.colorset/
│   │   │   └── Contents.json
│   │   ├── SlateIndigo.colorset/
│   │   │   └── Contents.json
│   │   ├── WarmGray.colorset/
│   │   │   └── Contents.json
│   │   ├── nasa-Q1p7bh3SHj8-unsplash.jpg
│   │   └── nasa-background.imageset/
│   │       ├── Contents.json
│   │       └── nasa-Q1p7bh3SHj8-unsplash.jpg
│   ├── Model/
│   │   ├── AIModel.swift
│   │   ├── AgentMode.swift
│   │   ├── AppState.swift
│   │   ├── ChatSession.swift
│   │   ├── FileItem.swift
│   │   ├── OpenCodeConfigLoader.swift
│   │   └── ToolCall.swift
│   ├── PDFScribe.entitlements
│   ├── PDFScribeApp.swift
│   ├── Services/
│   │   ├── AIService.swift
│   │   ├── FileService.swift
│   │   ├── Infrastructure/
│   │   │   ├── JSONRPCClient.swift
│   │   │   └── ProcessManager.swift
│   │   ├── MessageParser.swift
│   │   ├── ReportExportService.swift
│   │   ├── Strategies/
│   │   │   ├── AIProviderStrategy.swift
│   │   │   ├── AnthropicStrategy.swift
│   │   │   ├── OpenAIStrategy.swift
│   │   │   └── OpenCodeStrategy.swift
│   │   └── StreamController.swift
│   ├── View/
│   │   ├── Components/
│   │   │   ├── BadgeRow.swift
│   │   │   ├── CitationPills.swift
│   │   │   ├── CollapsibleSection.swift
│   │   │   ├── EditorialResponseView.swift
│   │   │   ├── FloatingInputView.swift
│   │   │   ├── LuxuryMarkdownTheme.swift
│   │   │   ├── MarkdownTextView.swift
│   │   │   ├── ReportView.swift
│   │   │   ├── SourcesList.swift
│   │   │   └── ToolCall/
│   │   │       ├── ToolCallCard.swift
│   │   │       ├── ToolCallSpotlightView.swift
│   │   │       └── ToolCallTimelineView.swift
│   │   ├── Extensions/
│   │   ├── MainSplitView.swift
│   │   ├── Modifiers/
│   │   │   └── View+GlassEffect.swift
│   │   ├── Settings/
│   │   │   └── AISettingsView.swift
│   │   └── Sidebar/
│   │       └── SidebarView.swift
│   └── ViewModel/
│       ├── AIViewModel.swift
│       ├── AppViewModel.swift
│       ├── EditorViewModel.swift
│       └── PDFViewModel.swift
├── PDFScribeTests/
│   └── PDFScribeTests.swift
├── PDFScribeUITests/
│   ├── PDFScribeUITests.swift
│   └── PDFScribeUITestsLaunchTests.swift
├── Package.swift
├── README.md
├── assets/
│   ├── frontend-design/
│   │   └── screen.png
│   ├── liquid-glass-docs/
│   │   └── README.md
│   └── nasa-Q1p7bh3SHj8-unsplash.jpg

```

### File Explanations

**Model/**
- `AppState.swift` - Persisted app state across sessions (project URL, sidebar mode)
- `AIModel.swift` - AI model and mode configurations
- `AgentMode.swift` - OpenCode agent modes (build/plan/explore)
- `ChatSession.swift` - Chat session and stored message structures
- `FileItem.swift` - File tree node structure
- `ToolCall.swift` - Agent tool execution tracking
- `OpenCodeConfigLoader.swift` - OpenCode config file parser

**Services/**
- `AIService.swift` - Main AI orchestration and session management
- `FileService.swift` - File I/O and chat history persistence
- `StreamController.swift` - Text streaming animation controller
- `MessageParser.swift` - Markdown and citation parsing
- `ReportExportService.swift` - Export chat to Markdown/PDF
- `ProcessManager.swift` - Subprocess lifecycle management
- `JSONRPCClient.swift` - JSON-RPC 2.0 protocol implementation
- `OpenCodeStrategy.swift` - ACP protocol implementation
- `OpenAIStrategy.swift` - OpenAI API provider
- `AnthropicStrategy.swift` - Claude API provider

**View/**
- `MainSplitView.swift` - Root NavigationSplitView layout
- `FloatingInputView.swift` - Centered input for empty state
- `ReportView.swift` - Editorial document layout (renamed from ResearchDocumentView)
- `EditorialResponseView.swift` - Main editorial response component with collapsible sections
- `BadgeRow.swift` - Model name and source count badges
- `CitationPills.swift` - Interactive citation pill buttons
- `CollapsibleSection.swift` - Animated section disclosure with chevron
- `SourcesList.swift` - Source URLs with hover effects
- `MarkdownTextView.swift` - Markdown renderer
- `LuxuryMarkdownTheme.swift` - Custom Markdown styling (Charter/Palatino fonts)
- `SidebarView.swift` - Navigation sidebar
- `AISettingsView.swift` - Provider/API key configuration
- `View+GlassEffect.swift` - Liquid Glass fallback modifier

**ViewModel/**
- `AppViewModel.swift` - Project/file/session state
- `AIViewModel.swift` - Chat, messages, tool calls state
- `PDFViewModel.swift` - PDF document and selection state
- `EditorViewModel.swift` - Markdown editor state

Dependencies: 
- markdownUI



