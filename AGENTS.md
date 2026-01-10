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

## Code Style Guidelines

### Philosophy: Minimalism
- **Write minimal code that works** (this strictly applies to code style not design)
- Break code into small, focused classes/functions
- Avoid over-engineering and premature abstraction
- Prefer clarity over cleverness


```

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



```





