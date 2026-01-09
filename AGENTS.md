# AGENTS.md - PDFScribe Developer Guide

This document provides guidelines for AI coding agents working on the PDFScribe codebase.

## Project Overview

PDFScribe is a native macOS application (macOS 12.0+) for reading PDFs with integrated note-taking and AI assistance. Built with SwiftUI, AppKit (NSTextView, PDFKit), and follows MVVM architecture.

## Build, Test, and Run Commands

### Standard Build Commands
```bash
# Build the project
make build
# or
swift build

# Run in development mode
make run
# or
swift run

# Clean build artifacts
make clean
# or
swift package clean

# Create production app bundle
make release
```

### Testing
```bash
# Run all tests (once test suite is implemented)
swift test

# Run specific test
swift test --filter <TestClassName>.<testMethodName>
# Example: swift test --filter PDFViewModelTests.testLoadPDF

# Run tests with verbose output
swift test --verbose
```

### Manual Testing
Launch app with `make run`, then:
1. Open a PDF file
2. Test text selection and "Add Quote" button (Cmd+Q)
3. Type in the editor panel (center)
4. Verify auto-save works (2-second debounce)
5. Test AI chat:
   - **OpenAI/Anthropic**: Requires API key in settings
   - **OpenCode**: Requires `opencode` CLI installed (e.g., `brew install opencode`)
     - Set provider to "OpenCode" in AI settings
     - Configure binary path (default: `/usr/local/bin/opencode`)
     - Chat normally - OpenCode runs locally via ACP protocol

## Code Style Guidelines

### Philosophy: Minimalism
- **Write minimal code that works**
- Break code into small, focused classes/functions
- Avoid over-engineering and premature abstraction
- Prefer clarity over cleverness

### Import Order
```swift
// 1. System frameworks (alphabetical)
import Combine
import Foundation
import PDFKit
import SwiftUI

// 2. Third-party dependencies (if any)

// 3. Local modules (if any)
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

### Type Annotations
- **Explicit types** when clarity improves readability
```swift
let apiKey: String = ""  // Good for published properties
let count = 0            // OK when type is obvious
```
- **Type inference** for local variables when obvious
- **Always specify** return types for public functions
```swift
func loadPDF(url: URL) throws -> Void  // or omit -> Void
```

### Concurrency (Swift 6)
- **ALL ViewModels MUST use `@MainActor`**
```swift
@MainActor
class PDFViewModel: ObservableObject {
    // ...
}
```
- Use `async/await` for asynchronous operations
- Wrap ViewModel updates in `Task { @MainActor in ... }` when called from delegate methods

### Error Handling
- **Define custom errors** as enums
```swift
enum PDFError: Error {
    case couldNotLoad
    case fileNotFound
    case invalidFormat
}
```
- **Throw errors** from functions that can fail (use `throws`)
- **Handle errors** at appropriate level (ViewModel or View)
- **User-facing errors**: Show alerts with clear messages
```swift
.alert("Error Opening PDF", isPresented: $showingError) {
    Button("OK", role: .cancel) { }
} message: {
    Text(errorMessage)
}
```

### SwiftUI & AppKit Integration
- **NSViewRepresentable**: Use for AppKit views (NSTextView, PDFView)
- **Coordinator**: Use for delegation patterns
```swift
struct EditorPanel: NSViewRepresentable {
    func makeNSView(context: Context) -> NSScrollView { }
    func updateNSView(_ scrollView: NSScrollView, context: Context) { }
    func makeCoordinator() -> Coordinator { }
    
    class Coordinator: NSObject, NSTextViewDelegate { }
}
```
- **First Responder**: Custom NSTextView subclass may be needed for keyboard input
```swift
class EditableTextView: NSTextView {
    override var acceptsFirstResponder: Bool { true }
}
```

### State Management
- **@StateObject**: Create ViewModels (use in App or top-level view)
- **@EnvironmentObject**: Pass ViewModels down the hierarchy
- **@Published**: Properties that trigger view updates
- **@State**: Local view state only (not for business logic)
- **Closures for callbacks**: Pass data up without tight coupling
```swift
var contentDidChange: ((String) -> Void)?
```

### File Organization
```
Sources/PDFScribe/
├── PDFScribeApp.swift          # App entry, creates all @StateObjects
├── Model/                      # Data structures (currently empty)
├── ViewModel/                  # @MainActor ObservableObjects
│   ├── AppViewModel.swift      # App-level state
│   ├── PDFViewModel.swift      # PDF document, selection
│   └── EditorViewModel.swift   # Note content, insertQuote
├── View/
│   ├── MainSplitView.swift     # Root layout, file picker
│   ├── PDF/                    # PDFKit integration
│   ├── Editor/                 # NSTextView wrapper
│   └── Chat/                   # AI interface
└── Services/                   # External services, file I/O
    ├── AIService.swift         # OpenAI/Anthropic API
    └── FileService.swift       # Auto-save, note association
```

## Git Workflow

### Branch Strategy
- **main**: Production-ready code
- **feature/**: New features (`feature/search-functionality`)
- **fix/**: Bug fixes (`fix/editor-typing`)
- **refactor/**: Code improvements without behavior changes

### Commit Messages
- **Format**: `<type>: <description>`
- **Types**: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`
- **Examples**:
  - `fix: Enable keyboard input in editor`
  - `feat: Add search functionality to notes`
  - `refactor: Extract PDF selection logic`

### Pull Requests
1. Create feature branch
2. Make changes and commit
3. Push to origin
4. Create PR with `gh pr create --base main --title "..." --body "..."`
5. Must pass `swift build` before merging
6. Merge with `gh pr merge <PR_NUMBER> --merge --delete-branch`

## Common Patterns

### Loading PDFs
```swift
// Validate file, check size, then load
try pdfViewModel.loadPDF(url: url)
let noteURL = fileService.associateNoteWithPDF(pdfURL: url)
```

### Text Selection to Quote
```swift
// User selects text → currentSelection updates
// User clicks "Add Quote" → pendingQuote set
// MainSplitView observes pendingQuote → calls insertQuote()
```

### Auto-Save
```swift
// EditorViewModel triggers contentDidChange closure
// FileService schedules save with 2s debounce
```

## Security Considerations
- **File size limits**: 100MB for PDFs
- **URL validation**: Check `isFileURL` and file exists
- **API keys**: Store in UserDefaults (NOT in code)
- **Input validation**: Sanitize user input before API calls

## Known Issues & Gotchas
1. **Editor typing bug**: NSTextView may not accept keyboard input if first responder chain is broken
2. **updateNSView guard**: Too restrictive guards can prevent content updates
3. **NotificationCenter leaks**: Observers must be removed in deinit
4. **Quote spam**: Fixed by explicit "Add Quote" button (PR #11)
5. **Symbol effect `.drawOn` invisibility**: `.drawOn.wholeSymbol` with `.repeat(.continuous)` renders as blank. Use `isActive:` with Timer toggle instead. See [.opencode/troubleshooting.md](.opencode/troubleshooting.md#issue-symboleffectdrawonwholesymbol-renders-as-invisibleblank)

## Future Work
- Issue #8: Add search functionality for notes
- Issue #9: Add export functionality (PDF, DOCX)
- CI/CD pipeline (currently manual testing only)
- Unit tests for ViewModels and Services
