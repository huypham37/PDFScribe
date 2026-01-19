# AGENTS.md - PDFScribe

## What is this project?
Native macOS app (Perplexity clone) for AI-powered research. Uses OpenCode via Agent Context Protocol (ACP).

## Quick rules (always apply)
- Build without `--debug` flag. Debug output bloats context with no value on success. If build fails, report to user to enable debugging.
- Wireframes before any UI implementation. No exceptions.
- Break views into modular components. No massive single-file views.
- Follow Liquid Glass guidelines (see section below).

---

## Architecture

### AI Service Layer
```
User → AIViewModel → AIService → OpenCodeStrategy → OpenCode (subprocess)
                                      ↓
                              JSONRPCClient (ACP/JSON-RPC over stdio)
```

**Entry points:**
| File | Role | Rule |
|------|------|------|
| `AIService.swift` | Orchestration, session management | All AI calls go through here. Never instantiate strategies directly. |
| `OpenCodeStrategy.swift` | ACP protocol, JSON-RPC | Don't modify unless changing protocol behavior. |
| `JSONRPCClient.swift` | Low-level transport | Rarely touch this. |

**Why OpenCode + ACP?**
- Supports stateful sessions with persistent history
- Handles context (files, selections, PDF text) efficiently
- Enables sub-agent delegation (e.g., `research-leader` mode)

### View Layer
```
MainSplitView
├── SidebarView (glass effect)
└── ReportView
    ├── EditorialResponseView
    │   ├── BadgeRow
    │   ├── CollapsibleSection
    │   └── CitationPills
    ├── SourcesList
    └── FloatingInputView
```

**Rules:**
- Views only talk to ViewModels, never Services directly
- New UI elements → build in isolation first, then integrate
- Glass effects on navigation only (sidebar, toolbars), not content

---

## Decision Log

| Decision | Rationale | Date |
|----------|-----------|------|
| OpenCode over direct API calls | Stateful sessions, sub-agent delegation, context handling | — |
| ACP (JSON-RPC over stdio) | Matches OpenCode's protocol, efficient for local subprocess | — |
| Liquid Glass for navigation only | Apple HIG, content needs to stay readable | — |
| Charter/Palatino fonts | Luxury editorial aesthetic | — |

---

## Code Style

### Philosophy
Minimal code that works. Clarity over cleverness. No premature abstraction.

### Naming
| Type | Convention | Example |
|------|------------|---------|
| Classes/Structs/Enums | PascalCase | `PDFViewModel`, `AIService` |
| Functions/Variables | camelCase | `loadPDF`, `currentPage` |
| Booleans | `is`/`has`/`should` prefix | `isEditable`, `hasSelection` |

### Formatting
- 4 spaces (no tabs)
- Opening brace on same line
- ~120 char lines (soft limit)

---

## Liquid Glass (macOS 26+)

**Apply to:**
- ✅ Sidebars, toolbars, floating controls

**Don't apply to:**
- ❌ Lists, tables, editors, media, content areas

**Implementation:**
```swift
// Automatic (preferred)
NavigationSplitView {
    SidebarView()  // Gets glass automatically
} detail: {
    ContentView()
}

// Manual
MyView().glassEffect(in: RoundedRectangle(cornerRadius: 12))

// Fallback (macOS < 26)
MyView().glassBackground()  // Uses .ultraThinMaterial
```

**Gotchas:**
- Remove custom backgrounds that interfere with glass
- Glass needs colorful content underneath to show refraction

Full docs: `assets/liquid-glass-docs/README.md`

---

## Common Tasks

### List GitHub issues
```bash
gh issue list --limit 20
```

### Add a new View
1. Create isolated component in `View/Components/`
2. Test in preview with mock data
3. Integrate into parent view
4. Update this doc if it's a major component

---

## Anti-patterns (don't do these)

| ❌ Don't | ✅ Do instead |
|----------|---------------|
| Call AIService from Views | Go through ViewModel |
| Put everything in one massive View file | Break into components |
| Apply glass to content areas | Glass on navigation only |
| Skip wireframes | Always wireframe first |
| Instantiate strategies directly | Use AIService |

---

## Updating this document

**When to update:**
- New architectural decision
- New anti-pattern discovered
- Component added/removed
- Convention changed

**How:**
- Add to Decision Log with rationale
- Keep sections focused
- Remove outdated info (don't just add)

---

## Project Structure

<details>
<summary>Expand file tree</summary>

[your existing tree here, collapsed by default]

</details>
