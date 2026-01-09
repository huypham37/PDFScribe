# ACTIVE MEMORY: Quote-to-PDF Navigation Feature

## Description
Implement clickable quotes in the editor that navigate to the corresponding page in the PDF and highlight the quoted text.

**User Requirements:**
- When user clicks on a quote in the edit view, PDF should navigate to the correct page
- The quoted text should be highlighted in the PDF
- Quote format: `> "quoted text" [Page X]`

## Progress Log

### [2026-01-09] Session: Planning & Design
**Work Completed:**
- Created git worktree at `../PDFScribe-quote-navigation` on branch `feature/quote-navigation`
- Explored codebase architecture to understand:
  - Editor: Plain NSTextView wrapped in EditorPanel.swift (NSViewRepresentable)
  - Quotes: Stored as plain text `> "quoted text" [Page X]` with escaped quotes
  - PDF: Uses PDFKit's PDFView with basic next/previous navigation
  - Pattern: MVVM with MainSplitView coordinating between ViewModels via @Published properties
- Clarified requirements with user:
  - Click target: Entire quote line (not just [Page X])
  - Highlighting: Temporary selection via PDFKit (non-permanent)
  - Error handling: Navigate to page only if text not found
- Designed minimal implementation plan (~60 lines, 4 files)
- Created detailed implementation plan at `/Users/mac/.claude/plans/sparkling-spinning-sketch.md`

**Implementation Approach:**
1. **EditorViewModel.swift**: Add QuoteInfo struct, parseQuote() method with regex, @Published requestedNavigation property
2. **EditorPanel.swift**: Override mouseDown() in EditableTextView to detect clicks on quote lines
3. **PDFViewModel.swift**: Add navigateToQuote() method using PDFPage.selection(for:) API
4. **MainSplitView.swift**: Add .onReceive() observer to coordinate Editor→PDF navigation (mirrors existing pendingQuote pattern)

**Key Technical Decisions:**
- Use mouseDown() override (not link attributes or gesture recognizers) for simplicity
- Regex pattern: `#"^>\s*"(.+)"\s*\[Page\s+(\d+)\]$"#`
- Unescape quotes (`\"` → `"`) before PDF search
- Graceful degradation: if text not found, navigate to page only (no error alerts)

**Critical Files:**
- PDFScribe/View/Editor/EditorPanel.swift (click detection)
- PDFScribe/ViewModel/EditorViewModel.swift (quote parsing)
- PDFScribe/ViewModel/PDFViewModel.swift (PDF navigation + highlighting)
- PDFScribe/View/MainSplitView.swift (coordination)

**Next Steps:**
1. Exit plan mode and get user approval
2. Implement changes in the worktree at `../PDFScribe-quote-navigation`
3. Test with various quote formats
4. Handle edge cases (invalid pages, text not found, escaped quotes)
5. Create PR when ready

**Status:** ✅ Planning complete, awaiting approval to implement
