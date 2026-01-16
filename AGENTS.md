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
-

## Guidelines when working with Frontend:

- When working with new windows, always provides a wireframes before executing. 
- I ask you to break view into modular components instead putting everything into a single, massive file. 



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
│   │   │       ├── CompactToolCallView.swift
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
│   ├── list-of-animations.md
│   └── nasa-Q1p7bh3SHj8-unsplash.jpg
└── zed/
    ├── CLAUDE.md
    ├── CODE_OF_CONDUCT.md
    ├── CONTRIBUTING.md
    ├── Cargo.lock
    ├── Cargo.toml
    ├── Dockerfile-collab
    ├── Dockerfile-collab.dockerignore
    ├── Dockerfile-cross.dockerignore
    ├── Dockerfile-distros
    ├── Dockerfile-distros.dockerignore
    ├── GEMINI.md
    ├── LICENSE-AGPL
    ├── LICENSE-APACHE
    ├── LICENSE-GPL
    ├── Procfile
    ├── Procfile.all
    ├── Procfile.web
    ├── README.md
    ├── REVIEWERS.conl
    ├── assets/
    │   ├── badge/
    │   │   └── v0.json
    │   ├── fonts/
    │   │   ├── ibm-plex-sans/
    │   │   │   ├── IBMPlexSans-Bold.ttf
    │   │   │   ├── IBMPlexSans-BoldItalic.ttf
    │   │   │   ├── IBMPlexSans-Italic.ttf
    │   │   │   ├── IBMPlexSans-Regular.ttf
    │   │   │   └── license.txt
    │   │   └── lilex/
    │   │       ├── Lilex-Bold.ttf
    │   │       ├── Lilex-BoldItalic.ttf
    │   │       ├── Lilex-Italic.ttf
    │   │       ├── Lilex-Regular.ttf
    │   │       └── OFL.txt
    │   ├── icons/
    │   │   ├── LICENSES
    │   │   ├── ai.svg
    │   │   ├── ai_anthropic.svg
    │   │   ├── ai_bedrock.svg
    │   │   ├── ai_claude.svg
    │   │   ├── ai_deep_seek.svg
    │   │   ├── ai_edit.svg
    │   │   ├── ai_gemini.svg
    │   │   ├── ai_google.svg
    │   │   ├── ai_lm_studio.svg
    │   │   ├── ai_mistral.svg
    │   │   ├── ai_ollama.svg
    │   │   ├── ai_open_ai.svg
    │   │   ├── ai_open_ai_compat.svg
    │   │   ├── ai_open_router.svg
    │   │   ├── ai_v_zero.svg
    │   │   ├── ai_x_ai.svg
    │   │   ├── ai_zed.svg
    │   │   ├── arrow_circle.svg
    │   │   ├── arrow_down.svg
    │   │   ├── arrow_down10.svg
    │   │   ├── arrow_down_right.svg
    │   │   ├── arrow_left.svg
    │   │   ├── arrow_right.svg
    │   │   ├── arrow_right_left.svg
    │   │   ├── arrow_up.svg
    │   │   ├── arrow_up_right.svg
    │   │   ├── at_sign.svg
    │   │   ├── attach.svg
    │   │   ├── audio_off.svg
    │   │   ├── audio_on.svg
    │   │   ├── backspace.svg
    │   │   ├── bell.svg
    │   │   ├── bell_dot.svg
    │   │   ├── bell_off.svg
    │   │   ├── bell_ring.svg
    │   │   ├── binary.svg
    │   │   ├── blocks.svg
    │   │   ├── bolt_filled.svg
    │   │   ├── bolt_outlined.svg
    │   │   ├── book.svg
    │   │   ├── book_copy.svg
    │   │   ├── box.svg
    │   │   ├── case_sensitive.svg
    │   │   ├── chat.svg
    │   │   ├── check.svg
    │   │   ├── check_circle.svg
    │   │   ├── check_double.svg
    │   │   ├── chevron_down.svg
    │   │   ├── chevron_down_up.svg
    │   │   ├── chevron_left.svg
    │   │   ├── chevron_right.svg
    │   │   ├── chevron_up.svg
    │   │   ├── chevron_up_down.svg
    │   │   ├── circle.svg
    │   │   ├── circle_check.svg
    │   │   ├── circle_help.svg
    │   │   ├── close.svg
    │   │   ├── cloud_download.svg
    │   │   ├── code.svg
    │   │   ├── cog.svg
    │   │   ├── command.svg
    │   │   ├── control.svg
    │   │   ├── copilot.svg
    │   │   ├── copilot_disabled.svg
    │   │   ├── copilot_error.svg
    │   │   ├── copilot_init.svg
    │   │   ├── copy.svg
    │   │   ├── countdown_timer.svg
    │   │   ├── crosshair.svg
    │   │   ├── cursor_i_beam.svg
    │   │   ├── dash.svg
    │   │   ├── database_zap.svg
    │   │   ├── debug.svg
    │   │   ├── debug_breakpoint.svg
    │   │   ├── debug_continue.svg
    │   │   ├── debug_detach.svg
    │   │   ├── debug_disabled_breakpoint.svg
    │   │   ├── debug_disabled_log_breakpoint.svg
    │   │   ├── debug_ignore_breakpoints.svg
    │   │   ├── debug_log_breakpoint.svg
    │   │   ├── debug_pause.svg
    │   │   ├── debug_step_into.svg
    │   │   ├── debug_step_out.svg
    │   │   ├── debug_step_over.svg
    │   │   ├── diff.svg
    │   │   ├── disconnected.svg
    │   │   ├── download.svg
    │   │   ├── editor_atom.svg
    │   │   ├── editor_cursor.svg
    │   │   ├── editor_emacs.svg
    │   │   ├── editor_jet_brains.svg
    │   │   ├── editor_sublime.svg
    │   │   ├── editor_vs_code.svg
    │   │   ├── ellipsis.svg
    │   │   ├── ellipsis_vertical.svg
    │   │   ├── envelope.svg
    │   │   ├── eraser.svg
    │   │   ├── escape.svg
    │   │   ├── exit.svg
    │   │   ├── expand_down.svg
    │   │   ├── expand_up.svg
    │   │   ├── expand_vertical.svg
    │   │   ├── eye.svg
    │   │   ├── file.svg
    │   │   ├── file_code.svg
    │   │   ├── file_diff.svg
    │   │   ├── file_doc.svg
    │   │   ├── file_generic.svg
    │   │   ├── file_git.svg
    │   │   ├── file_icons/
    │   │   │   ├── ai.svg
    │   │   │   ├── archive.svg
    │   │   │   ├── astro.svg
    │   │   │   ├── audio.svg
    │   │   │   ├── book.svg
    │   │   │   ├── bun.svg
    │   │   │   ├── c.svg
    │   │   │   ├── cairo.svg
    │   │   │   ├── camera.svg
    │   │   │   ├── chevron_down.svg
    │   │   │   ├── chevron_left.svg
    │   │   │   ├── chevron_right.svg
    │   │   │   ├── chevron_up.svg
    │   │   │   ├── code.svg
    │   │   │   ├── coffeescript.svg
    │   │   │   ├── conversations.svg
    │   │   │   ├── cpp.svg
    │   │   │   ├── css.svg
    │   │   │   ├── dart.svg
    │   │   │   ├── database.svg
    │   │   │   ├── diff.svg
    │   │   │   ├── docker.svg
    │   │   │   ├── elixir.svg
    │   │   │   ├── elm.svg
    │   │   │   ├── erlang.svg
    │   │   │   ├── eslint.svg
    │   │   │   ├── file.svg
    │   │   │   ├── folder.svg
    │   │   │   ├── folder_open.svg
    │   │   │   ├── font.svg
    │   │   │   ├── fsharp.svg
    │   │   │   ├── git.svg
    │   │   │   ├── gleam.svg
    │   │   │   ├── go.svg
    │   │   │   ├── graphql.svg
    │   │   │   ├── hash.svg
    │   │   │   ├── haskell.svg
    │   │   │   ├── hcl.svg
    │   │   │   ├── heroku.svg
    │   │   │   ├── html.svg
    │   │   │   ├── image.svg
    │   │   │   ├── info.svg
    │   │   │   ├── java.svg
    │   │   │   ├── javascript.svg
    │   │   │   ├── julia.svg
    │   │   │   ├── kdl.svg
    │   │   │   ├── kotlin.svg
    │   │   │   ├── lock.svg
    │   │   │   ├── lua.svg
    │   │   │   ├── luau.svg
    │   │   │   ├── magnifying_glass.svg
    │   │   │   ├── metal.svg
    │   │   │   ├── nim.svg
    │   │   │   ├── nix.svg
    │   │   │   ├── notebook.svg
    │   │   │   ├── ocaml.svg
    │   │   │   ├── odin.svg
    │   │   │   ├── package.svg
    │   │   │   ├── phoenix.svg
    │   │   │   ├── php.svg
    │   │   │   ├── plus.svg
    │   │   │   ├── prettier.svg
    │   │   │   ├── prisma.svg
    │   │   │   ├── project.svg
    │   │   │   ├── puppet.svg
    │   │   │   ├── python.svg
    │   │   │   ├── r.svg
    │   │   │   ├── react.svg
    │   │   │   ├── replace.svg
    │   │   │   ├── replace_all.svg
    │   │   │   ├── replace_next.svg
    │   │   │   ├── roc.svg
    │   │   │   ├── ruby.svg
    │   │   │   ├── rust.svg
    │   │   │   ├── sass.svg
    │   │   │   ├── scala.svg
    │   │   │   ├── settings.svg
    │   │   │   ├── surrealql.svg
    │   │   │   ├── swift.svg
    │   │   │   ├── tcl.svg
    │   │   │   ├── terminal.svg
    │   │   │   ├── terraform.svg
    │   │   │   ├── toml.svg
    │   │   │   ├── typescript.svg
    │   │   │   ├── v.svg
    │   │   │   ├── video.svg
    │   │   │   ├── vue.svg
    │   │   │   ├── vyper.svg
    │   │   │   ├── wgsl.svg
    │   │   │   └── zig.svg
    │   │   ├── file_lock.svg
    │   │   ├── file_markdown.svg
    │   │   ├── file_rust.svg
    │   │   ├── file_text_filled.svg
    │   │   ├── file_text_outlined.svg
    │   │   ├── file_toml.svg
    │   │   ├── file_tree.svg
    │   │   ├── filter.svg
    │   │   ├── flame.svg
    │   │   ├── folder.svg
    │   │   ├── folder_open.svg
    │   │   ├── folder_search.svg
    │   │   ├── font.svg
    │   │   ├── font_size.svg
    │   │   ├── font_weight.svg
    │   │   ├── forward_arrow.svg
    │   │   ├── generic_close.svg
    │   │   ├── generic_maximize.svg
    │   │   ├── generic_minimize.svg
    │   │   ├── generic_restore.svg
    │   │   ├── git_branch.svg
    │   │   ├── git_branch_alt.svg
    │   │   ├── git_branch_plus.svg
    │   │   ├── github.svg
    │   │   ├── hash.svg
    │   │   ├── history_rerun.svg
    │   │   ├── image.svg
    │   │   ├── inception.svg
    │   │   ├── indicator.svg
    │   │   ├── info.svg
    │   │   ├── json.svg
    │   │   ├── keyboard.svg
    │   │   ├── knockouts/
    │   │   │   ├── dot_bg.svg
    │   │   │   ├── dot_fg.svg
    │   │   │   ├── triangle_bg.svg
    │   │   │   ├── triangle_fg.svg
    │   │   │   ├── x_bg.svg
    │   │   │   └── x_fg.svg
    │   │   ├── library.svg
    │   │   ├── line_height.svg
    │   │   ├── link.svg
    │   │   ├── linux.svg
    │   │   ├── list_collapse.svg
    │   │   ├── list_filter.svg
    │   │   ├── list_todo.svg
    │   │   ├── list_tree.svg
    │   │   ├── list_x.svg
    │   │   ├── load_circle.svg
    │   │   ├── location_edit.svg
    │   │   ├── lock_outlined.svg
    │   │   ├── magnifying_glass.svg
    │   │   ├── maximize.svg
    │   │   ├── menu.svg
    │   │   ├── menu_alt.svg
    │   │   ├── menu_alt_temp.svg
    │   │   ├── mic.svg
    │   │   ├── mic_mute.svg
    │   │   ├── minimize.svg
    │   │   ├── notepad.svg
    │   │   ├── option.svg
    │   │   ├── page_down.svg
    │   │   ├── page_up.svg
    │   │   ├── paperclip.svg
    │   │   ├── pencil.svg
    │   │   ├── pencil_unavailable.svg
    │   │   ├── person.svg
    │   │   ├── pin.svg
    │   │   ├── play_filled.svg
    │   │   ├── play_outlined.svg
    │   │   ├── plus.svg
    │   │   ├── power.svg
    │   │   ├── public.svg
    │   │   ├── pull_request.svg
    │   │   ├── quote.svg
    │   │   ├── reader.svg
    │   │   ├── refresh_title.svg
    │   │   ├── regex.svg
    │   │   ├── repl_neutral.svg
    │   │   ├── repl_off.svg
    │   │   ├── repl_pause.svg
    │   │   ├── repl_play.svg
    │   │   ├── replace.svg
    │   │   ├── replace_all.svg
    │   │   ├── replace_next.svg
    │   │   ├── reply_arrow_right.svg
    │   │   ├── rerun.svg
    │   │   ├── return.svg
    │   │   ├── rotate_ccw.svg
    │   │   ├── rotate_cw.svg
    │   │   ├── scissors.svg
    │   │   ├── screen.svg
    │   │   ├── select_all.svg
    │   │   ├── send.svg
    │   │   ├── server.svg
    │   │   ├── settings.svg
    │   │   ├── shield_check.svg
    │   │   ├── shift.svg
    │   │   ├── slash.svg
    │   │   ├── sliders.svg
    │   │   ├── space.svg
    │   │   ├── sparkle.svg
    │   │   ├── split.svg
    │   │   ├── split_alt.svg
    │   │   ├── square_dot.svg
    │   │   ├── square_minus.svg
    │   │   ├── square_plus.svg
    │   │   ├── star.svg
    │   │   ├── star_filled.svg
    │   │   ├── stop.svg
    │   │   ├── supermaven.svg
    │   │   ├── supermaven_disabled.svg
    │   │   ├── supermaven_error.svg
    │   │   ├── supermaven_init.svg
    │   │   ├── swatch_book.svg
    │   │   ├── sweep_ai.svg
    │   │   ├── tab.svg
    │   │   ├── terminal.svg
    │   │   ├── terminal_alt.svg
    │   │   ├── terminal_ghost.svg
    │   │   ├── text_snippet.svg
    │   │   ├── text_thread.svg
    │   │   ├── thread.svg
    │   │   ├── thread_from_summary.svg
    │   │   ├── thumbs_down.svg
    │   │   ├── thumbs_up.svg
    │   │   ├── todo_complete.svg
    │   │   ├── todo_pending.svg
    │   │   ├── todo_progress.svg
    │   │   ├── tool_copy.svg
    │   │   ├── tool_delete_file.svg
    │   │   ├── tool_diagnostics.svg
    │   │   ├── tool_folder.svg
    │   │   ├── tool_hammer.svg
    │   │   ├── tool_notification.svg
    │   │   ├── tool_pencil.svg
    │   │   ├── tool_read.svg
    │   │   ├── tool_regex.svg
    │   │   ├── tool_search.svg
    │   │   ├── tool_terminal.svg
    │   │   ├── tool_think.svg
    │   │   ├── tool_web.svg
    │   │   ├── trash.svg
    │   │   ├── triangle.svg
    │   │   ├── triangle_right.svg
    │   │   ├── undo.svg
    │   │   ├── unpin.svg
    │   │   ├── user_check.svg
    │   │   ├── user_group.svg
    │   │   ├── user_round_pen.svg
    │   │   ├── warning.svg
    │   │   ├── whole_word.svg
    │   │   ├── x_circle.svg
    │   │   ├── x_circle_filled.svg
    │   │   ├── zed_agent.svg
    │   │   ├── zed_agent_two.svg
    │   │   ├── zed_assistant.svg
    │   │   ├── zed_burn_mode.svg
    │   │   ├── zed_burn_mode_on.svg
    │   │   ├── zed_predict.svg
    │   │   ├── zed_predict_disabled.svg
    │   │   ├── zed_predict_down.svg
    │   │   ├── zed_predict_error.svg
    │   │   ├── zed_predict_up.svg
    │   │   ├── zed_src_custom.svg
    │   │   └── zed_src_extension.svg
    │   ├── images/
    │   │   ├── acp_grid.svg
    │   │   ├── acp_logo.svg
    │   │   ├── acp_logo_serif.svg
    │   │   ├── ai_grid.svg
    │   │   ├── debugger_grid.svg
    │   │   ├── grid.svg
    │   │   ├── pro_trial_stamp.svg
    │   │   ├── pro_user_stamp.svg
    │   │   ├── zed_logo.svg
    │   │   └── zed_x_copilot.svg
    │   ├── keymaps/
    │   │   ├── default-linux.json
    │   │   ├── default-macos.json
    │   │   ├── default-windows.json
    │   │   ├── initial.json
    │   │   ├── linux/
    │   │   │   ├── atom.json
    │   │   │   ├── cursor.json
    │   │   │   ├── emacs.json
    │   │   │   ├── jetbrains.json
    │   │   │   └── sublime_text.json
    │   │   ├── macos/
    │   │   │   ├── atom.json
    │   │   │   ├── cursor.json
    │   │   │   ├── emacs.json
    │   │   │   ├── jetbrains.json
    │   │   │   ├── sublime_text.json
    │   │   │   └── textmate.json
    │   │   ├── storybook.json
    │   │   └── vim.json
    │   ├── prompts/
    │   │   ├── content_prompt.hbs
    │   │   ├── content_prompt_v2.hbs
    │   │   └── terminal_assistant_prompt.hbs
    │   ├── settings/
    │   │   ├── default.json
    │   │   ├── initial_debug_tasks.json
    │   │   ├── initial_local_debug_tasks.json
    │   │   ├── initial_local_settings.json
    │   │   ├── initial_server_settings.json
    │   │   ├── initial_tasks.json
    │   │   └── initial_user_settings.json
    │   ├── sounds/
    │   │   ├── agent_done.wav
    │   │   ├── guest_joined_call.wav
    │   │   ├── joined_call.wav
    │   │   ├── leave_call.wav
    │   │   ├── mute.wav
    │   │   ├── start_screenshare.wav
    │   │   ├── stop_screenshare.wav
    │   │   └── unmute.wav
    │   └── themes/
    │       ├── LICENSES
    │       ├── ayu/
    │       │   ├── LICENSE
    │       │   └── ayu.json
    │       ├── gruvbox/
    │       │   ├── LICENSE
    │       │   └── gruvbox.json
    │       └── one/
    │           ├── LICENSE
    │           └── one.json
    ├── ci/
    │   └── Dockerfile.namespace
    ├── clippy.toml
    ├── compose.yml
    ├── crates/
    │   ├── acp_thread/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── acp_thread.rs
    │   │       ├── connection.rs
    │   │       ├── diff.rs
    │   │       ├── mention.rs
    │   │       └── terminal.rs
    │   ├── acp_tools/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── acp_tools.rs
    │   ├── action_log/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── action_log.rs
    │   ├── activity_indicator/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── activity_indicator.rs
    │   ├── agent/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── agent.rs
    │   │       ├── db.rs
    │   │       ├── edit_agent/
    │   │       │   ├── create_file_parser.rs
    │   │       │   ├── edit_parser.rs
    │   │       │   ├── evals/
    │   │       │   │   └── fixtures/
    │   │       │   │       ├── add_overwrite_test/
    │   │       │   │       │   └── before.rs
    │   │       │   │       ├── delete_run_git_blame/
    │   │       │   │       │   ├── after.rs
    │   │       │   │       │   └── before.rs
    │   │       │   │       ├── disable_cursor_blinking/
    │   │       │   │       │   ├── before.rs
    │   │       │   │       │   ├── possible-01.diff
    │   │       │   │       │   ├── possible-02.diff
    │   │       │   │       │   ├── possible-03.diff
    │   │       │   │       │   └── possible-04.diff
    │   │       │   │       ├── extract_handle_command_output/
    │   │       │   │       │   ├── before.rs
    │   │       │   │       │   ├── possible-01.diff
    │   │       │   │       │   ├── possible-02.diff
    │   │       │   │       │   ├── possible-03.diff
    │   │       │   │       │   ├── possible-04.diff
    │   │       │   │       │   ├── possible-05.diff
    │   │       │   │       │   ├── possible-06.diff
    │   │       │   │       │   ├── possible-07.diff
    │   │       │   │       │   └── possible-08.diff
    │   │       │   │       ├── from_pixels_constructor/
    │   │       │   │       │   └── before.rs
    │   │       │   │       ├── translate_doc_comments/
    │   │       │   │       │   └── before.rs
    │   │       │   │       ├── use_wasi_sdk_in_compile_parser_to_wasm/
    │   │       │   │       │   └── before.rs
    │   │       │   │       └── zode/
    │   │       │   │           ├── prompt.md
    │   │       │   │           ├── react.py
    │   │       │   │           └── react_test.py
    │   │       │   ├── evals.rs
    │   │       │   └── streaming_fuzzy_matcher.rs
    │   │       ├── edit_agent.rs
    │   │       ├── history_store.rs
    │   │       ├── legacy_thread.rs
    │   │       ├── native_agent_server.rs
    │   │       ├── outline.rs
    │   │       ├── templates/
    │   │       │   ├── create_file_prompt.hbs
    │   │       │   ├── diff_judge.hbs
    │   │       │   ├── edit_file_prompt_diff_fenced.hbs
    │   │       │   ├── edit_file_prompt_xml.hbs
    │   │       │   └── system_prompt.hbs
    │   │       ├── templates.rs
    │   │       ├── tests/
    │   │       │   ├── mod.rs
    │   │       │   └── test_tools.rs
    │   │       ├── thread.rs
    │   │       ├── tools/
    │   │       │   ├── context_server_registry.rs
    │   │       │   ├── copy_path_tool.rs
    │   │       │   ├── create_directory_tool.rs
    │   │       │   ├── delete_path_tool.rs
    │   │       │   ├── diagnostics_tool.rs
    │   │       │   ├── edit_file_tool.rs
    │   │       │   ├── fetch_tool.rs
    │   │       │   ├── find_path_tool.rs
    │   │       │   ├── grep_tool.rs
    │   │       │   ├── list_directory_tool.rs
    │   │       │   ├── move_path_tool.rs
    │   │       │   ├── now_tool.rs
    │   │       │   ├── open_tool.rs
    │   │       │   ├── read_file_tool.rs
    │   │       │   ├── restore_file_from_disk_tool.rs
    │   │       │   ├── save_file_tool.rs
    │   │       │   ├── terminal_tool.rs
    │   │       │   ├── thinking_tool.rs
    │   │       │   └── web_search_tool.rs
    │   │       └── tools.rs
    │   ├── agent_servers/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── acp.rs
    │   │       ├── agent_servers.rs
    │   │       ├── claude.rs
    │   │       ├── codex.rs
    │   │       ├── custom.rs
    │   │       ├── e2e_tests.rs
    │   │       └── gemini.rs
    │   ├── agent_settings/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── agent_profile.rs
    │   │       ├── agent_settings.rs
    │   │       └── prompts/
    │   │           ├── summarize_thread_detailed_prompt.txt
    │   │           └── summarize_thread_prompt.txt
    │   ├── agent_ui/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── acp/
    │   │       │   ├── config_options.rs
    │   │       │   ├── entry_view_state.rs
    │   │       │   ├── message_editor.rs
    │   │       │   ├── mode_selector.rs
    │   │       │   ├── model_selector.rs
    │   │       │   ├── model_selector_popover.rs
    │   │       │   ├── thread_history.rs
    │   │       │   └── thread_view.rs
    │   │       ├── acp.rs
    │   │       ├── agent_configuration/
    │   │       │   ├── add_llm_provider_modal.rs
    │   │       │   ├── configure_context_server_modal.rs
    │   │       │   ├── configure_context_server_tools_modal.rs
    │   │       │   ├── manage_profiles_modal/
    │   │       │   │   └── profile_modal_header.rs
    │   │       │   ├── manage_profiles_modal.rs
    │   │       │   └── tool_picker.rs
    │   │       ├── agent_configuration.rs
    │   │       ├── agent_diff.rs
    │   │       ├── agent_model_selector.rs
    │   │       ├── agent_panel.rs
    │   │       ├── agent_ui.rs
    │   │       ├── buffer_codegen.rs
    │   │       ├── completion_provider.rs
    │   │       ├── context.rs
    │   │       ├── context_server_configuration.rs
    │   │       ├── favorite_models.rs
    │   │       ├── inline_assistant.rs
    │   │       ├── inline_prompt_editor.rs
    │   │       ├── language_model_selector.rs
    │   │       ├── mention_set.rs
    │   │       ├── profile_selector.rs
    │   │       ├── slash_command.rs
    │   │       ├── slash_command_picker.rs
    │   │       ├── terminal_codegen.rs
    │   │       ├── terminal_inline_assistant.rs
    │   │       ├── text_thread_editor.rs
    │   │       ├── ui/
    │   │       │   ├── acp_onboarding_modal.rs
    │   │       │   ├── agent_notification.rs
    │   │       │   ├── burn_mode_tooltip.rs
    │   │       │   ├── claude_code_onboarding_modal.rs
    │   │       │   ├── end_trial_upsell.rs
    │   │       │   ├── hold_for_default.rs
    │   │       │   ├── mention_crease.rs
    │   │       │   ├── model_selector_components.rs
    │   │       │   ├── onboarding_modal.rs
    │   │       │   └── usage_callout.rs
    │   │       └── ui.rs
    │   ├── agent_ui_v2/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── agent_thread_pane.rs
    │   │       ├── agent_ui_v2.rs
    │   │       ├── agents_panel.rs
    │   │       └── thread_history.rs
    │   ├── ai_onboarding/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── agent_api_keys_onboarding.rs
    │   │       ├── agent_panel_onboarding_card.rs
    │   │       ├── agent_panel_onboarding_content.rs
    │   │       ├── ai_onboarding.rs
    │   │       ├── ai_upsell_card.rs
    │   │       ├── edit_prediction_onboarding_content.rs
    │   │       ├── plan_definitions.rs
    │   │       └── young_account_banner.rs
    │   ├── anthropic/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── anthropic.rs
    │   │       └── batches.rs
    │   ├── askpass/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── askpass.rs
    │   │       └── encrypted_password.rs
    │   ├── assets/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── assets.rs
    │   ├── assistant_slash_command/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── assistant_slash_command.rs
    │   │       ├── extension_slash_command.rs
    │   │       ├── slash_command_registry.rs
    │   │       └── slash_command_working_set.rs
    │   ├── assistant_slash_commands/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── assistant_slash_commands.rs
    │   │       ├── cargo_workspace_command.rs
    │   │       ├── context_server_command.rs
    │   │       ├── default_command.rs
    │   │       ├── delta_command.rs
    │   │       ├── diagnostics_command.rs
    │   │       ├── fetch_command.rs
    │   │       ├── file_command.rs
    │   │       ├── now_command.rs
    │   │       ├── prompt_command.rs
    │   │       ├── selection_command.rs
    │   │       ├── streaming_example_command.rs
    │   │       ├── symbols_command.rs
    │   │       └── tab_command.rs
    │   ├── assistant_text_thread/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── assistant_text_thread.rs
    │   │       ├── assistant_text_thread_tests.rs
    │   │       ├── text_thread.rs
    │   │       └── text_thread_store.rs
    │   ├── audio/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── audio.rs
    │   │       ├── audio_settings.rs
    │   │       ├── replays.rs
    │   │       └── rodio_ext.rs
    │   ├── auto_update/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── auto_update.rs
    │   ├── auto_update_helper/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── app-icon.ico
    │   │   ├── build.rs
    │   │   ├── manifest.xml
    │   │   └── src/
    │   │       ├── auto_update_helper.rs
    │   │       ├── dialog.rs
    │   │       └── updater.rs
    │   ├── auto_update_ui/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── auto_update_ui.rs
    │   ├── aws_http_client/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── aws_http_client.rs
    │   ├── bedrock/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── bedrock.rs
    │   │       └── models.rs
    │   ├── breadcrumbs/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── breadcrumbs.rs
    │   ├── buffer_diff/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── buffer_diff.rs
    │   ├── call/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── call.rs
    │   │       ├── call_impl/
    │   │       │   ├── mod.rs
    │   │       │   ├── participant.rs
    │   │       │   └── room.rs
    │   │       └── call_settings.rs
    │   ├── channel/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── channel.rs
    │   │       ├── channel_buffer.rs
    │   │       ├── channel_store/
    │   │       │   └── channel_index.rs
    │   │       ├── channel_store.rs
    │   │       └── channel_store_tests.rs
    │   ├── cli/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── README.md
    │   │   ├── build.rs
    │   │   └── src/
    │   │       ├── cli.rs
    │   │       └── main.rs
    │   ├── client/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── client.rs
    │   │       ├── proxy/
    │   │       │   ├── http_proxy.rs
    │   │       │   └── socks_proxy.rs
    │   │       ├── proxy.rs
    │   │       ├── telemetry/
    │   │       │   └── event_coalescer.rs
    │   │       ├── telemetry.rs
    │   │       ├── test.rs
    │   │       ├── user.rs
    │   │       └── zed_urls.rs
    │   ├── clock/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── clock.rs
    │   │       └── system_clock.rs
    │   ├── cloud_api_client/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-APACHE
    │   │   └── src/
    │   │       ├── cloud_api_client.rs
    │   │       └── websocket.rs
    │   ├── cloud_api_types/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-APACHE
    │   │   └── src/
    │   │       ├── cloud_api_types.rs
    │   │       ├── timestamp.rs
    │   │       └── websocket_protocol.rs
    │   ├── cloud_llm_client/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-APACHE
    │   │   └── src/
    │   │       ├── cloud_llm_client.rs
    │   │       └── predict_edits_v3.rs
    │   ├── codestral/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── codestral.rs
    │   ├── collab/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-AGPL
    │   │   ├── README.md
    │   │   ├── k8s/
    │   │   │   ├── collab.template.yml
    │   │   │   └── environments/
    │   │   │       ├── production.sh
    │   │   │       └── staging.sh
    │   │   ├── migrations/
    │   │   │   └── 20251208000000_test_schema.sql
    │   │   ├── migrations.sqlite/
    │   │   │   └── 20221109000000_test_schema.sql
    │   │   ├── seed/
    │   │   │   └── github_users.json
    │   │   ├── seed.default.json
    │   │   └── src/
    │   │       ├── api/
    │   │       │   ├── contributors.rs
    │   │       │   ├── events.rs
    │   │       │   └── extensions.rs
    │   │       ├── api.rs
    │   │       ├── auth.rs
    │   │       ├── bin/
    │   │       │   └── dotenv.rs
    │   │       ├── completion.rs
    │   │       ├── db/
    │   │       │   ├── ids.rs
    │   │       │   ├── queries/
    │   │       │   │   ├── access_tokens.rs
    │   │       │   │   ├── buffers.rs
    │   │       │   │   ├── channels.rs
    │   │       │   │   ├── contacts.rs
    │   │       │   │   ├── contributors.rs
    │   │       │   │   ├── dev_server_projects.rs
    │   │       │   │   ├── dev_servers.rs
    │   │       │   │   ├── extensions.rs
    │   │       │   │   ├── notifications.rs
    │   │       │   │   ├── projects.rs
    │   │       │   │   ├── rooms.rs
    │   │       │   │   ├── servers.rs
    │   │       │   │   ├── shared_threads.rs
    │   │       │   │   └── users.rs
    │   │       │   ├── queries.rs
    │   │       │   ├── tables/
    │   │       │   │   ├── access_token.rs
    │   │       │   │   ├── buffer.rs
    │   │       │   │   ├── buffer_operation.rs
    │   │       │   │   ├── buffer_snapshot.rs
    │   │       │   │   ├── channel.rs
    │   │       │   │   ├── channel_buffer_collaborator.rs
    │   │       │   │   ├── channel_chat_participant.rs
    │   │       │   │   ├── channel_member.rs
    │   │       │   │   ├── contact.rs
    │   │       │   │   ├── contributor.rs
    │   │       │   │   ├── extension.rs
    │   │       │   │   ├── extension_version.rs
    │   │       │   │   ├── follower.rs
    │   │       │   │   ├── language_server.rs
    │   │       │   │   ├── notification.rs
    │   │       │   │   ├── notification_kind.rs
    │   │       │   │   ├── observed_buffer_edits.rs
    │   │       │   │   ├── project.rs
    │   │       │   │   ├── project_collaborator.rs
    │   │       │   │   ├── project_repository.rs
    │   │       │   │   ├── project_repository_statuses.rs
    │   │       │   │   ├── room.rs
    │   │       │   │   ├── room_participant.rs
    │   │       │   │   ├── server.rs
    │   │       │   │   ├── shared_thread.rs
    │   │       │   │   ├── user.rs
    │   │       │   │   ├── worktree.rs
    │   │       │   │   ├── worktree_diagnostic_summary.rs
    │   │       │   │   ├── worktree_entry.rs
    │   │       │   │   └── worktree_settings_file.rs
    │   │       │   ├── tables.rs
    │   │       │   ├── tests/
    │   │       │   │   ├── buffer_tests.rs
    │   │       │   │   ├── channel_tests.rs
    │   │       │   │   ├── contributor_tests.rs
    │   │       │   │   ├── db_tests.rs
    │   │       │   │   ├── extension_tests.rs
    │   │       │   │   └── migrations.rs
    │   │       │   └── tests.rs
    │   │       ├── db.rs
    │   │       ├── env.rs
    │   │       ├── errors.rs
    │   │       ├── executor.rs
    │   │       ├── lib.rs
    │   │       ├── main.rs
    │   │       ├── rpc/
    │   │       │   └── connection_pool.rs
    │   │       ├── rpc.rs
    │   │       ├── seed.rs
    │   │       ├── tests/
    │   │       │   ├── agent_sharing_tests.rs
    │   │       │   ├── channel_buffer_tests.rs
    │   │       │   ├── channel_guest_tests.rs
    │   │       │   ├── channel_tests.rs
    │   │       │   ├── debug_panel_tests.rs
    │   │       │   ├── editor_tests.rs
    │   │       │   ├── following_tests.rs
    │   │       │   ├── git_tests.rs
    │   │       │   ├── integration_tests.rs
    │   │       │   ├── notification_tests.rs
    │   │       │   ├── random_channel_buffer_tests.rs
    │   │       │   ├── random_project_collaboration_tests.rs
    │   │       │   ├── randomized_test_helpers.rs
    │   │       │   ├── remote_editing_collaboration_tests.rs
    │   │       │   └── test_server.rs
    │   │       └── tests.rs
    │   ├── collab_ui/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── channel_view.rs
    │   │       ├── collab_panel/
    │   │       │   ├── channel_modal.rs
    │   │       │   └── contact_finder.rs
    │   │       ├── collab_panel.rs
    │   │       ├── collab_ui.rs
    │   │       ├── notification_panel.rs
    │   │       ├── notifications/
    │   │       │   ├── collab_notification.rs
    │   │       │   ├── incoming_call_notification.rs
    │   │       │   ├── project_shared_notification.rs
    │   │       │   ├── stories/
    │   │       │   │   └── collab_notification.rs
    │   │       │   └── stories.rs
    │   │       ├── notifications.rs
    │   │       └── panel_settings.rs
    │   ├── collections/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-APACHE
    │   │   └── src/
    │   │       └── collections.rs
    │   ├── command_palette/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── command_palette.rs
    │   │       └── persistence.rs
    │   ├── command_palette_hooks/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── command_palette_hooks.rs
    │   ├── component/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── component.rs
    │   │       └── component_layout.rs
    │   ├── component_preview/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── examples/
    │   │   │   └── component_preview.rs
    │   │   └── src/
    │   │       ├── component_preview.rs
    │   │       ├── component_preview_example.rs
    │   │       └── persistence.rs
    │   ├── context_server/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── client.rs
    │   │       ├── context_server.rs
    │   │       ├── listener.rs
    │   │       ├── protocol.rs
    │   │       ├── test.rs
    │   │       ├── transport/
    │   │       │   ├── http.rs
    │   │       │   └── stdio_transport.rs
    │   │       ├── transport.rs
    │   │       └── types.rs
    │   ├── copilot/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── copilot.rs
    │   │       ├── copilot_chat.rs
    │   │       ├── copilot_edit_prediction_delegate.rs
    │   │       ├── copilot_responses.rs
    │   │       ├── request.rs
    │   │       └── sign_in.rs
    │   ├── crashes/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── crashes.rs
    │   ├── credentials_provider/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── credentials_provider.rs
    │   ├── dap/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── docs/
    │   │   │   └── breakpoints.md
    │   │   └── src/
    │   │       ├── adapters.rs
    │   │       ├── client.rs
    │   │       ├── dap.rs
    │   │       ├── debugger_settings.rs
    │   │       ├── inline_value.rs
    │   │       ├── proto_conversions.rs
    │   │       ├── registry.rs
    │   │       └── transport.rs
    │   ├── dap_adapters/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── codelldb.rs
    │   │       ├── dap_adapters.rs
    │   │       ├── gdb.rs
    │   │       ├── go.rs
    │   │       ├── javascript.rs
    │   │       └── python.rs
    │   ├── db/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── README.md
    │   │   └── src/
    │   │       ├── db.rs
    │   │       ├── kvp.rs
    │   │       └── query.rs
    │   ├── debug_adapter_extension/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── debug_adapter_extension.rs
    │   │       ├── extension_dap_adapter.rs
    │   │       └── extension_locator_adapter.rs
    │   ├── debugger_tools/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── dap_log.rs
    │   │       └── debugger_tools.rs
    │   ├── debugger_ui/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── attach_modal.rs
    │   │       ├── debugger_panel.rs
    │   │       ├── debugger_ui.rs
    │   │       ├── dropdown_menus.rs
    │   │       ├── new_process_modal.rs
    │   │       ├── onboarding_modal.rs
    │   │       ├── persistence.rs
    │   │       ├── session/
    │   │       │   ├── running/
    │   │       │   │   ├── breakpoint_list.rs
    │   │       │   │   ├── console.rs
    │   │       │   │   ├── loaded_source_list.rs
    │   │       │   │   ├── memory_view.rs
    │   │       │   │   ├── module_list.rs
    │   │       │   │   ├── stack_frame_list.rs
    │   │       │   │   └── variable_list.rs
    │   │       │   └── running.rs
    │   │       ├── session.rs
    │   │       ├── stack_trace_view.rs
    │   │       ├── tests/
    │   │       │   ├── attach_modal.rs
    │   │       │   ├── console.rs
    │   │       │   ├── dap_logger.rs
    │   │       │   ├── debugger_panel.rs
    │   │       │   ├── inline_values.rs
    │   │       │   ├── module_list.rs
    │   │       │   ├── new_process_modal.rs
    │   │       │   ├── persistence.rs
    │   │       │   ├── stack_frame_list.rs
    │   │       │   └── variable_list.rs
    │   │       └── tests.rs
    │   ├── deepseek/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── deepseek.rs
    │   ├── denoise/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── README.md
    │   │   ├── examples/
    │   │   │   ├── denoise.rs
    │   │   │   └── enable_disable.rs
    │   │   ├── models/
    │   │   │   ├── model_1_converted_simplified.onnx
    │   │   │   └── model_2_converted_simplified.onnx
    │   │   └── src/
    │   │       ├── engine.rs
    │   │       └── lib.rs
    │   ├── diagnostics/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── buffer_diagnostics.rs
    │   │       ├── diagnostic_renderer.rs
    │   │       ├── diagnostics.rs
    │   │       ├── diagnostics_tests.rs
    │   │       ├── items.rs
    │   │       └── toolbar_controls.rs
    │   ├── docs_preprocessor/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── main.rs
    │   ├── edit_prediction/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── license_examples/
    │   │   │   ├── 0bsd.txt
    │   │   │   ├── apache-2.0-ex0.txt
    │   │   │   ├── apache-2.0-ex1.txt
    │   │   │   ├── apache-2.0-ex2.txt
    │   │   │   ├── apache-2.0-ex3.txt
    │   │   │   ├── apache-2.0-ex4.txt
    │   │   │   ├── bsd-1-clause.txt
    │   │   │   ├── bsd-2-clause-ex0.txt
    │   │   │   ├── bsd-3-clause-ex0.txt
    │   │   │   ├── bsd-3-clause-ex1.txt
    │   │   │   ├── bsd-3-clause-ex2.txt
    │   │   │   ├── bsd-3-clause-ex3.txt
    │   │   │   ├── bsd-3-clause-ex4.txt
    │   │   │   ├── isc.txt
    │   │   │   ├── mit-ex0.txt
    │   │   │   ├── mit-ex1.txt
    │   │   │   ├── mit-ex2.txt
    │   │   │   ├── mit-ex3.txt
    │   │   │   ├── upl-1.0.txt
    │   │   │   └── zlib-ex0.txt
    │   │   ├── license_patterns/
    │   │   │   ├── 0bsd-pattern
    │   │   │   ├── apache-2.0-pattern
    │   │   │   ├── apache-2.0-reference-pattern
    │   │   │   ├── bsd-pattern
    │   │   │   ├── isc-pattern
    │   │   │   ├── mit-pattern
    │   │   │   ├── upl-1.0-pattern
    │   │   │   └── zlib-pattern
    │   │   └── src/
    │   │       ├── capture_example.rs
    │   │       ├── cursor_excerpt.rs
    │   │       ├── edit_prediction.rs
    │   │       ├── edit_prediction_tests.rs
    │   │       ├── example_spec.rs
    │   │       ├── license_detection.rs
    │   │       ├── mercury.rs
    │   │       ├── onboarding_modal.rs
    │   │       ├── open_ai_response.rs
    │   │       ├── prediction.rs
    │   │       ├── sweep_ai.rs
    │   │       ├── udiff.rs
    │   │       ├── zed_edit_prediction_delegate.rs
    │   │       ├── zeta1.rs
    │   │       └── zeta2.rs
    │   ├── edit_prediction_cli/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── build.rs
    │   │   └── src/
    │   │       ├── anthropic_client.rs
    │   │       ├── distill.rs
    │   │       ├── example.rs
    │   │       ├── format_prompt.rs
    │   │       ├── git.rs
    │   │       ├── headless.rs
    │   │       ├── load_project.rs
    │   │       ├── main.rs
    │   │       ├── metrics.rs
    │   │       ├── paths.rs
    │   │       ├── predict.rs
    │   │       ├── progress.rs
    │   │       ├── pull_examples.rs
    │   │       ├── reorder_patch.rs
    │   │       ├── retrieve_context.rs
    │   │       ├── score.rs
    │   │       ├── split_commit.rs
    │   │       ├── split_dataset.rs
    │   │       ├── synthesize.rs
    │   │       └── teacher.prompt.md
    │   ├── edit_prediction_context/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── assemble_excerpts.rs
    │   │       ├── edit_prediction_context.rs
    │   │       ├── edit_prediction_context_tests.rs
    │   │       ├── excerpt.rs
    │   │       └── fake_definition_lsp.rs
    │   ├── edit_prediction_types/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── edit_prediction_types.rs
    │   ├── edit_prediction_ui/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── edit_prediction_button.rs
    │   │       ├── edit_prediction_context_view.rs
    │   │       ├── edit_prediction_ui.rs
    │   │       └── rate_prediction_modal.rs
    │   ├── editor/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── benches/
    │   │   │   ├── display_map.rs
    │   │   │   └── editor_render.rs
    │   │   └── src/
    │   │       ├── actions.rs
    │   │       ├── blink_manager.rs
    │   │       ├── bracket_colorization.rs
    │   │       ├── clangd_ext.rs
    │   │       ├── code_completion_tests.rs
    │   │       ├── code_context_menus.rs
    │   │       ├── display_map/
    │   │       │   ├── block_map.rs
    │   │       │   ├── crease_map.rs
    │   │       │   ├── custom_highlights.rs
    │   │       │   ├── dimensions.rs
    │   │       │   ├── fold_map.rs
    │   │       │   ├── inlay_map.rs
    │   │       │   ├── invisibles.rs
    │   │       │   ├── tab_map.rs
    │   │       │   └── wrap_map.rs
    │   │       ├── display_map.rs
    │   │       ├── edit_prediction_tests.rs
    │   │       ├── editor.rs
    │   │       ├── editor_settings.rs
    │   │       ├── editor_tests.rs
    │   │       ├── element.rs
    │   │       ├── git/
    │   │       │   └── blame.rs
    │   │       ├── git.rs
    │   │       ├── highlight_matching_bracket.rs
    │   │       ├── hover_links.rs
    │   │       ├── hover_popover.rs
    │   │       ├── indent_guides.rs
    │   │       ├── inlays/
    │   │       │   └── inlay_hints.rs
    │   │       ├── inlays.rs
    │   │       ├── items.rs
    │   │       ├── jsx_tag_auto_close.rs
    │   │       ├── linked_editing_ranges.rs
    │   │       ├── lsp_colors.rs
    │   │       ├── lsp_ext.rs
    │   │       ├── mouse_context_menu.rs
    │   │       ├── movement.rs
    │   │       ├── persistence.rs
    │   │       ├── rust_analyzer_ext.rs
    │   │       ├── scroll/
    │   │       │   ├── actions.rs
    │   │       │   ├── autoscroll.rs
    │   │       │   └── scroll_amount.rs
    │   │       ├── scroll.rs
    │   │       ├── selections_collection.rs
    │   │       ├── signature_help.rs
    │   │       ├── split.rs
    │   │       ├── tasks.rs
    │   │       ├── test/
    │   │       │   ├── editor_lsp_test_context.rs
    │   │       │   └── editor_test_context.rs
    │   │       └── test.rs
    │   ├── encoding_selector/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── active_buffer_encoding.rs
    │   │       └── encoding_selector.rs
    │   ├── eval/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── README.md
    │   │   ├── build.rs
    │   │   ├── docs/
    │   │   │   └── explorer.md
    │   │   ├── runner_settings.json
    │   │   └── src/
    │   │       ├── assertions.rs
    │   │       ├── eval.rs
    │   │       ├── example.rs
    │   │       ├── examples/
    │   │       │   ├── add_arg_to_trait_method.rs
    │   │       │   ├── code_block_citations.rs
    │   │       │   ├── comment_translation.rs
    │   │       │   ├── file_change_notification.rs
    │   │       │   ├── file_search.rs
    │   │       │   ├── find_and_replace_diff_card.toml
    │   │       │   ├── grep_params_escapement.rs
    │   │       │   ├── hallucinated_tool_calls.toml
    │   │       │   ├── mod.rs
    │   │       │   ├── no_tools_enabled.toml
    │   │       │   ├── overwrite_file.rs
    │   │       │   ├── planets.rs
    │   │       │   ├── threads/
    │   │       │   │   └── overwrite-file.json
    │   │       │   └── tree_sitter_drop_emscripten_dep.toml
    │   │       ├── explorer.html
    │   │       ├── explorer.rs
    │   │       ├── ids.rs
    │   │       ├── instance.rs
    │   │       ├── judge_diff_prompt.hbs
    │   │       ├── judge_thread_prompt.hbs
    │   │       └── tool_metrics.rs
    │   ├── eval_utils/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── README.md
    │   │   └── src/
    │   │       └── eval_utils.rs
    │   ├── explorer_command_injector/
    │   │   ├── AppxManifest-Nightly.xml
    │   │   ├── AppxManifest-Preview.xml
    │   │   ├── AppxManifest.xml
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── explorer_command_injector.rs
    │   ├── extension/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── capabilities/
    │   │       │   ├── download_file_capability.rs
    │   │       │   ├── npm_install_package_capability.rs
    │   │       │   └── process_exec_capability.rs
    │   │       ├── capabilities.rs
    │   │       ├── extension.rs
    │   │       ├── extension_builder.rs
    │   │       ├── extension_events.rs
    │   │       ├── extension_host_proxy.rs
    │   │       ├── extension_manifest.rs
    │   │       ├── types/
    │   │       │   ├── context_server.rs
    │   │       │   ├── dap.rs
    │   │       │   ├── lsp.rs
    │   │       │   └── slash_command.rs
    │   │       └── types.rs
    │   ├── extension_api/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-APACHE
    │   │   ├── PENDING_CHANGES.md
    │   │   ├── README.md
    │   │   ├── build.rs
    │   │   ├── src/
    │   │   │   ├── extension_api.rs
    │   │   │   ├── http_client.rs
    │   │   │   ├── process.rs
    │   │   │   └── settings.rs
    │   │   └── wit/
    │   │       ├── since_v0.0.1/
    │   │       │   ├── extension.wit
    │   │       │   ├── github.wit
    │   │       │   └── platform.wit
    │   │       ├── since_v0.0.4/
    │   │       │   ├── extension.wit
    │   │       │   ├── github.wit
    │   │       │   └── platform.wit
    │   │       ├── since_v0.0.6/
    │   │       │   ├── extension.wit
    │   │       │   ├── github.wit
    │   │       │   ├── lsp.wit
    │   │       │   ├── nodejs.wit
    │   │       │   ├── platform.wit
    │   │       │   └── settings.rs
    │   │       ├── since_v0.1.0/
    │   │       │   ├── common.wit
    │   │       │   ├── extension.wit
    │   │       │   ├── github.wit
    │   │       │   ├── http-client.wit
    │   │       │   ├── lsp.wit
    │   │       │   ├── nodejs.wit
    │   │       │   ├── platform.wit
    │   │       │   ├── settings.rs
    │   │       │   └── slash-command.wit
    │   │       ├── since_v0.2.0/
    │   │       │   ├── common.wit
    │   │       │   ├── extension.wit
    │   │       │   ├── github.wit
    │   │       │   ├── http-client.wit
    │   │       │   ├── lsp.wit
    │   │       │   ├── nodejs.wit
    │   │       │   ├── platform.wit
    │   │       │   ├── settings.rs
    │   │       │   └── slash-command.wit
    │   │       ├── since_v0.3.0/
    │   │       │   ├── common.wit
    │   │       │   ├── extension.wit
    │   │       │   ├── github.wit
    │   │       │   ├── http-client.wit
    │   │       │   ├── lsp.wit
    │   │       │   ├── nodejs.wit
    │   │       │   ├── platform.wit
    │   │       │   ├── process.wit
    │   │       │   ├── settings.rs
    │   │       │   └── slash-command.wit
    │   │       ├── since_v0.4.0/
    │   │       │   ├── common.wit
    │   │       │   ├── extension.wit
    │   │       │   ├── github.wit
    │   │       │   ├── http-client.wit
    │   │       │   ├── lsp.wit
    │   │       │   ├── nodejs.wit
    │   │       │   ├── platform.wit
    │   │       │   ├── process.wit
    │   │       │   ├── settings.rs
    │   │       │   └── slash-command.wit
    │   │       ├── since_v0.5.0/
    │   │       │   ├── common.wit
    │   │       │   ├── context-server.wit
    │   │       │   ├── extension.wit
    │   │       │   ├── github.wit
    │   │       │   ├── http-client.wit
    │   │       │   ├── lsp.wit
    │   │       │   ├── nodejs.wit
    │   │       │   ├── platform.wit
    │   │       │   ├── process.wit
    │   │       │   ├── settings.rs
    │   │       │   └── slash-command.wit
    │   │       ├── since_v0.6.0/
    │   │       │   ├── common.wit
    │   │       │   ├── context-server.wit
    │   │       │   ├── dap.wit
    │   │       │   ├── extension.wit
    │   │       │   ├── github.wit
    │   │       │   ├── http-client.wit
    │   │       │   ├── lsp.wit
    │   │       │   ├── nodejs.wit
    │   │       │   ├── platform.wit
    │   │       │   ├── process.wit
    │   │       │   ├── settings.rs
    │   │       │   └── slash-command.wit
    │   │       └── since_v0.8.0/
    │   │           ├── common.wit
    │   │           ├── context-server.wit
    │   │           ├── dap.wit
    │   │           ├── extension.wit
    │   │           ├── github.wit
    │   │           ├── http-client.wit
    │   │           ├── lsp.wit
    │   │           ├── nodejs.wit
    │   │           ├── platform.wit
    │   │           ├── process.wit
    │   │           ├── settings.rs
    │   │           └── slash-command.wit
    │   ├── extension_cli/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── main.rs
    │   ├── extension_host/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── benches/
    │   │   │   └── extension_compilation_benchmark.rs
    │   │   ├── build.rs
    │   │   └── src/
    │   │       ├── capability_granter.rs
    │   │       ├── extension_host.rs
    │   │       ├── extension_settings.rs
    │   │       ├── extension_store_test.rs
    │   │       ├── headless_host.rs
    │   │       ├── wasm_host/
    │   │       │   ├── wit/
    │   │       │   │   ├── since_v0_0_1.rs
    │   │       │   │   ├── since_v0_0_4.rs
    │   │       │   │   ├── since_v0_0_6.rs
    │   │       │   │   ├── since_v0_1_0.rs
    │   │       │   │   ├── since_v0_2_0.rs
    │   │       │   │   ├── since_v0_3_0.rs
    │   │       │   │   ├── since_v0_4_0.rs
    │   │       │   │   ├── since_v0_5_0.rs
    │   │       │   │   ├── since_v0_6_0.rs
    │   │       │   │   └── since_v0_8_0.rs
    │   │       │   └── wit.rs
    │   │       └── wasm_host.rs
    │   ├── extensions_ui/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── components/
    │   │       │   └── extension_card.rs
    │   │       ├── components.rs
    │   │       ├── extension_suggest.rs
    │   │       ├── extension_version_selector.rs
    │   │       └── extensions_ui.rs
    │   ├── feature_flags/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── feature_flags.rs
    │   │       └── flags.rs
    │   ├── feedback/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── feedback.rs
    │   ├── file_finder/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── file_finder.rs
    │   │       ├── file_finder_settings.rs
    │   │       ├── file_finder_tests.rs
    │   │       ├── open_path_prompt.rs
    │   │       └── open_path_prompt_tests.rs
    │   ├── file_icons/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── file_icons.rs
    │   ├── fs/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── fake_git_repo.rs
    │   │       ├── fs.rs
    │   │       ├── fs_watcher.rs
    │   │       └── mac_watcher.rs
    │   ├── fs_benchmarks/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── main.rs
    │   ├── fsevent/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── examples/
    │   │   │   └── events.rs
    │   │   └── src/
    │   │       └── fsevent.rs
    │   ├── fuzzy/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── char_bag.rs
    │   │       ├── fuzzy.rs
    │   │       ├── matcher.rs
    │   │       ├── paths.rs
    │   │       └── strings.rs
    │   ├── git/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── src/
    │   │   │   ├── blame.rs
    │   │   │   ├── checkpoint.gitignore
    │   │   │   ├── commit.rs
    │   │   │   ├── git.rs
    │   │   │   ├── hosting_provider.rs
    │   │   │   ├── remote.rs
    │   │   │   ├── repository.rs
    │   │   │   ├── stash.rs
    │   │   │   └── status.rs
    │   │   └── test_data/
    │   │       ├── blame_incremental_complex
    │   │       ├── blame_incremental_not_committed
    │   │       ├── blame_incremental_simple
    │   │       └── golden/
    │   │           ├── blame_incremental_complex.json
    │   │           ├── blame_incremental_not_committed.json
    │   │           └── blame_incremental_simple.json
    │   ├── git_hosting_providers/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── git_hosting_providers.rs
    │   │       ├── providers/
    │   │       │   ├── bitbucket.rs
    │   │       │   ├── chromium.rs
    │   │       │   ├── forgejo.rs
    │   │       │   ├── gitea.rs
    │   │       │   ├── gitee.rs
    │   │       │   ├── github.rs
    │   │       │   ├── gitlab.rs
    │   │       │   └── sourcehut.rs
    │   │       ├── providers.rs
    │   │       └── settings.rs
    │   ├── git_ui/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── askpass_modal.rs
    │   │       ├── blame_ui.rs
    │   │       ├── branch_picker.rs
    │   │       ├── clone.rs
    │   │       ├── commit_message_prompt.txt
    │   │       ├── commit_modal.rs
    │   │       ├── commit_tooltip.rs
    │   │       ├── commit_view.rs
    │   │       ├── conflict_view.rs
    │   │       ├── file_diff_view.rs
    │   │       ├── file_history_view.rs
    │   │       ├── git_panel.rs
    │   │       ├── git_panel_settings.rs
    │   │       ├── git_ui.rs
    │   │       ├── onboarding.rs
    │   │       ├── picker_prompt.rs
    │   │       ├── project_diff.rs
    │   │       ├── remote_output.rs
    │   │       ├── repository_selector.rs
    │   │       ├── stash_picker.rs
    │   │       ├── text_diff_view.rs
    │   │       └── worktree_picker.rs
    │   ├── go_to_line/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── cursor_position.rs
    │   │       └── go_to_line.rs
    │   ├── google_ai/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── google_ai.rs
    │   ├── gpui/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-APACHE
    │   │   ├── README.md
    │   │   ├── build.rs
    │   │   ├── docs/
    │   │   │   ├── contexts.md
    │   │   │   └── key_dispatch.md
    │   │   ├── examples/
    │   │   │   ├── animation.rs
    │   │   │   ├── data_table.rs
    │   │   │   ├── drag_drop.rs
    │   │   │   ├── focus_visible.rs
    │   │   │   ├── gif_viewer.rs
    │   │   │   ├── gradient.rs
    │   │   │   ├── grid_layout.rs
    │   │   │   ├── hello_world.rs
    │   │   │   ├── image/
    │   │   │   │   ├── app-icon.png
    │   │   │   │   ├── arrow_circle.svg
    │   │   │   │   ├── black-cat-typing.gif
    │   │   │   │   ├── color.svg
    │   │   │   │   └── image.rs
    │   │   │   ├── image_gallery.rs
    │   │   │   ├── image_loading.rs
    │   │   │   ├── input.rs
    │   │   │   ├── layer_shell.rs
    │   │   │   ├── mouse_pressure.rs
    │   │   │   ├── on_window_close_quit.rs
    │   │   │   ├── opacity.rs
    │   │   │   ├── ownership_post.rs
    │   │   │   ├── painting.rs
    │   │   │   ├── paths_bench.rs
    │   │   │   ├── pattern.rs
    │   │   │   ├── popover.rs
    │   │   │   ├── scrollable.rs
    │   │   │   ├── set_menus.rs
    │   │   │   ├── shadow.rs
    │   │   │   ├── svg/
    │   │   │   │   ├── dragon.svg
    │   │   │   │   └── svg.rs
    │   │   │   ├── tab_stop.rs
    │   │   │   ├── testing.rs
    │   │   │   ├── text.rs
    │   │   │   ├── text_layout.rs
    │   │   │   ├── text_wrapper.rs
    │   │   │   ├── tree.rs
    │   │   │   ├── uniform_list.rs
    │   │   │   ├── window.rs
    │   │   │   ├── window_positioning.rs
    │   │   │   └── window_shadow.rs
    │   │   ├── resources/
    │   │   │   └── windows/
    │   │   │       ├── gpui.manifest.xml
    │   │   │       └── gpui.rc
    │   │   ├── src/
    │   │   │   ├── _ownership_and_data_flow.rs
    │   │   │   ├── action.rs
    │   │   │   ├── app/
    │   │   │   │   ├── async_context.rs
    │   │   │   │   ├── context.rs
    │   │   │   │   ├── entity_map.rs
    │   │   │   │   ├── test_context.rs
    │   │   │   │   └── visual_test_context.rs
    │   │   │   ├── app.rs
    │   │   │   ├── arena.rs
    │   │   │   ├── asset_cache.rs
    │   │   │   ├── assets.rs
    │   │   │   ├── bounds_tree.rs
    │   │   │   ├── color.rs
    │   │   │   ├── colors.rs
    │   │   │   ├── element.rs
    │   │   │   ├── elements/
    │   │   │   │   ├── anchored.rs
    │   │   │   │   ├── animation.rs
    │   │   │   │   ├── canvas.rs
    │   │   │   │   ├── deferred.rs
    │   │   │   │   ├── div.rs
    │   │   │   │   ├── image_cache.rs
    │   │   │   │   ├── img.rs
    │   │   │   │   ├── list.rs
    │   │   │   │   ├── mod.rs
    │   │   │   │   ├── surface.rs
    │   │   │   │   ├── svg.rs
    │   │   │   │   ├── text.rs
    │   │   │   │   └── uniform_list.rs
    │   │   │   ├── executor.rs
    │   │   │   ├── geometry.rs
    │   │   │   ├── global.rs
    │   │   │   ├── gpui.rs
    │   │   │   ├── input.rs
    │   │   │   ├── inspector.rs
    │   │   │   ├── interactive.rs
    │   │   │   ├── key_dispatch.rs
    │   │   │   ├── keymap/
    │   │   │   │   ├── binding.rs
    │   │   │   │   └── context.rs
    │   │   │   ├── keymap.rs
    │   │   │   ├── path_builder.rs
    │   │   │   ├── platform/
    │   │   │   │   ├── app_menu.rs
    │   │   │   │   ├── blade/
    │   │   │   │   │   ├── apple_compat.rs
    │   │   │   │   │   ├── blade_atlas.rs
    │   │   │   │   │   ├── blade_context.rs
    │   │   │   │   │   ├── blade_renderer.rs
    │   │   │   │   │   └── shaders.wgsl
    │   │   │   │   ├── blade.rs
    │   │   │   │   ├── keyboard.rs
    │   │   │   │   ├── keystroke.rs
    │   │   │   │   ├── linux/
    │   │   │   │   │   ├── dispatcher.rs
    │   │   │   │   │   ├── headless/
    │   │   │   │   │   │   └── client.rs
    │   │   │   │   │   ├── headless.rs
    │   │   │   │   │   ├── keyboard.rs
    │   │   │   │   │   ├── platform.rs
    │   │   │   │   │   ├── text_system.rs
    │   │   │   │   │   ├── wayland/
    │   │   │   │   │   │   ├── client.rs
    │   │   │   │   │   │   ├── clipboard.rs
    │   │   │   │   │   │   ├── cursor.rs
    │   │   │   │   │   │   ├── display.rs
    │   │   │   │   │   │   ├── layer_shell.rs
    │   │   │   │   │   │   ├── serial.rs
    │   │   │   │   │   │   └── window.rs
    │   │   │   │   │   ├── wayland.rs
    │   │   │   │   │   ├── x11/
    │   │   │   │   │   │   ├── client.rs
    │   │   │   │   │   │   ├── clipboard.rs
    │   │   │   │   │   │   ├── display.rs
    │   │   │   │   │   │   ├── event.rs
    │   │   │   │   │   │   ├── window.rs
    │   │   │   │   │   │   └── xim_handler.rs
    │   │   │   │   │   ├── x11.rs
    │   │   │   │   │   └── xdg_desktop_portal.rs
    │   │   │   │   ├── linux.rs
    │   │   │   │   ├── mac/
    │   │   │   │   │   ├── dispatch.h
    │   │   │   │   │   ├── dispatcher.rs
    │   │   │   │   │   ├── display.rs
    │   │   │   │   │   ├── display_link.rs
    │   │   │   │   │   ├── events.rs
    │   │   │   │   │   ├── keyboard.rs
    │   │   │   │   │   ├── metal_atlas.rs
    │   │   │   │   │   ├── metal_renderer.rs
    │   │   │   │   │   ├── open_type.rs
    │   │   │   │   │   ├── pasteboard.rs
    │   │   │   │   │   ├── platform.rs
    │   │   │   │   │   ├── screen_capture.rs
    │   │   │   │   │   ├── shaders.metal
    │   │   │   │   │   ├── status_item.rs
    │   │   │   │   │   ├── text_system.rs
    │   │   │   │   │   ├── window.rs
    │   │   │   │   │   └── window_appearance.rs
    │   │   │   │   ├── mac.rs
    │   │   │   │   ├── scap_screen_capture.rs
    │   │   │   │   ├── test/
    │   │   │   │   │   ├── dispatcher.rs
    │   │   │   │   │   ├── display.rs
    │   │   │   │   │   ├── platform.rs
    │   │   │   │   │   └── window.rs
    │   │   │   │   ├── test.rs
    │   │   │   │   ├── windows/
    │   │   │   │   │   ├── alpha_correction.hlsl
    │   │   │   │   │   ├── clipboard.rs
    │   │   │   │   │   ├── color_text_raster.hlsl
    │   │   │   │   │   ├── destination_list.rs
    │   │   │   │   │   ├── direct_write.rs
    │   │   │   │   │   ├── directx_atlas.rs
    │   │   │   │   │   ├── directx_devices.rs
    │   │   │   │   │   ├── directx_renderer.rs
    │   │   │   │   │   ├── dispatcher.rs
    │   │   │   │   │   ├── display.rs
    │   │   │   │   │   ├── events.rs
    │   │   │   │   │   ├── keyboard.rs
    │   │   │   │   │   ├── platform.rs
    │   │   │   │   │   ├── shaders.hlsl
    │   │   │   │   │   ├── system_settings.rs
    │   │   │   │   │   ├── util.rs
    │   │   │   │   │   ├── vsync.rs
    │   │   │   │   │   ├── window.rs
    │   │   │   │   │   └── wrapper.rs
    │   │   │   │   └── windows.rs
    │   │   │   ├── platform.rs
    │   │   │   ├── prelude.rs
    │   │   │   ├── profiler.rs
    │   │   │   ├── queue.rs
    │   │   │   ├── scene.rs
    │   │   │   ├── shared_string.rs
    │   │   │   ├── shared_uri.rs
    │   │   │   ├── style.rs
    │   │   │   ├── styled.rs
    │   │   │   ├── subscription.rs
    │   │   │   ├── svg_renderer.rs
    │   │   │   ├── tab_stop.rs
    │   │   │   ├── taffy.rs
    │   │   │   ├── test.rs
    │   │   │   ├── text_system/
    │   │   │   │   ├── font_fallbacks.rs
    │   │   │   │   ├── font_features.rs
    │   │   │   │   ├── line.rs
    │   │   │   │   ├── line_layout.rs
    │   │   │   │   └── line_wrapper.rs
    │   │   │   ├── text_system.rs
    │   │   │   ├── util.rs
    │   │   │   ├── view.rs
    │   │   │   ├── window/
    │   │   │   │   └── prompts.rs
    │   │   │   └── window.rs
    │   │   └── tests/
    │   │       └── action_macros.rs
    │   ├── gpui_macros/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-APACHE
    │   │   ├── src/
    │   │   │   ├── derive_action.rs
    │   │   │   ├── derive_app_context.rs
    │   │   │   ├── derive_inspector_reflection.rs
    │   │   │   ├── derive_into_element.rs
    │   │   │   ├── derive_render.rs
    │   │   │   ├── derive_visual_context.rs
    │   │   │   ├── gpui_macros.rs
    │   │   │   ├── register_action.rs
    │   │   │   ├── styles.rs
    │   │   │   └── test.rs
    │   │   └── tests/
    │   │       ├── derive_context.rs
    │   │       ├── derive_inspector_reflection.rs
    │   │       └── render_test.rs
    │   ├── gpui_tokio/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-APACHE
    │   │   └── src/
    │   │       └── gpui_tokio.rs
    │   ├── html_to_markdown/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-APACHE
    │   │   └── src/
    │   │       ├── html_element.rs
    │   │       ├── html_to_markdown.rs
    │   │       ├── markdown.rs
    │   │       ├── markdown_writer.rs
    │   │       ├── structure/
    │   │       │   └── wikipedia.rs
    │   │       └── structure.rs
    │   ├── http_client/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-APACHE
    │   │   └── src/
    │   │       ├── async_body.rs
    │   │       ├── github.rs
    │   │       ├── github_download.rs
    │   │       └── http_client.rs
    │   ├── http_client_tls/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-APACHE
    │   │   └── src/
    │   │       └── http_client_tls.rs
    │   ├── icons/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── README.md
    │   │   └── src/
    │   │       └── icons.rs
    │   ├── image_viewer/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── image_info.rs
    │   │       ├── image_viewer.rs
    │   │       └── image_viewer_settings.rs
    │   ├── inspector_ui/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── README.md
    │   │   ├── build.rs
    │   │   └── src/
    │   │       ├── div_inspector.rs
    │   │       ├── inspector.rs
    │   │       └── inspector_ui.rs
    │   ├── install_cli/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── install_cli.rs
    │   │       ├── install_cli_binary.rs
    │   │       └── register_zed_scheme.rs
    │   ├── journal/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── journal.rs
    │   ├── json_schema_store/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── json_schema_store.rs
    │   │       └── schemas/
    │   │           ├── package.json
    │   │           └── tsconfig.json
    │   ├── keymap_editor/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── action_completion_provider.rs
    │   │       ├── keymap_editor.rs
    │   │       └── ui_components/
    │   │           ├── keystroke_input.rs
    │   │           └── mod.rs
    │   ├── language/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── build.rs
    │   │   └── src/
    │   │       ├── buffer/
    │   │       │   └── row_chunk.rs
    │   │       ├── buffer.rs
    │   │       ├── buffer_tests.rs
    │   │       ├── diagnostic_set.rs
    │   │       ├── highlight_map.rs
    │   │       ├── language.rs
    │   │       ├── language_registry.rs
    │   │       ├── language_settings.rs
    │   │       ├── manifest.rs
    │   │       ├── outline.rs
    │   │       ├── proto.rs
    │   │       ├── syntax_map/
    │   │       │   └── syntax_map_tests.rs
    │   │       ├── syntax_map.rs
    │   │       ├── task_context.rs
    │   │       ├── text_diff.rs
    │   │       └── toolchain.rs
    │   ├── language_extension/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── extension_lsp_adapter.rs
    │   │       └── language_extension.rs
    │   ├── language_model/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── api_key.rs
    │   │       ├── fake_provider.rs
    │   │       ├── language_model.rs
    │   │       ├── model/
    │   │       │   ├── cloud_model.rs
    │   │       │   └── mod.rs
    │   │       ├── rate_limiter.rs
    │   │       ├── registry.rs
    │   │       ├── request.rs
    │   │       ├── role.rs
    │   │       ├── telemetry.rs
    │   │       └── tool_schema.rs
    │   ├── language_models/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── extension.rs
    │   │       ├── language_models.rs
    │   │       ├── provider/
    │   │       │   ├── anthropic.rs
    │   │       │   ├── bedrock.rs
    │   │       │   ├── cloud.rs
    │   │       │   ├── copilot_chat.rs
    │   │       │   ├── deepseek.rs
    │   │       │   ├── google.rs
    │   │       │   ├── lmstudio.rs
    │   │       │   ├── mistral.rs
    │   │       │   ├── ollama.rs
    │   │       │   ├── open_ai.rs
    │   │       │   ├── open_ai_compatible.rs
    │   │       │   ├── open_router.rs
    │   │       │   ├── vercel.rs
    │   │       │   └── x_ai.rs
    │   │       ├── provider.rs
    │   │       └── settings.rs
    │   ├── language_onboarding/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── python.rs
    │   ├── language_selector/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── active_buffer_language.rs
    │   │       └── language_selector.rs
    │   ├── language_tools/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── key_context_view.rs
    │   │       ├── language_tools.rs
    │   │       ├── lsp_button.rs
    │   │       ├── lsp_log_view.rs
    │   │       ├── lsp_log_view_tests.rs
    │   │       └── syntax_tree_view.rs
    │   ├── languages/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── bash/
    │   │       │   ├── brackets.scm
    │   │       │   ├── config.toml
    │   │       │   ├── highlights.scm
    │   │       │   ├── indents.scm
    │   │       │   ├── injections.scm
    │   │       │   ├── overrides.scm
    │   │       │   ├── redactions.scm
    │   │       │   └── textobjects.scm
    │   │       ├── bash.rs
    │   │       ├── c/
    │   │       │   ├── brackets.scm
    │   │       │   ├── config.toml
    │   │       │   ├── highlights.scm
    │   │       │   ├── imports.scm
    │   │       │   ├── indents.scm
    │   │       │   ├── injections.scm
    │   │       │   ├── outline.scm
    │   │       │   ├── overrides.scm
    │   │       │   ├── runnables.scm
    │   │       │   └── textobjects.scm
    │   │       ├── c.rs
    │   │       ├── cpp/
    │   │       │   ├── brackets.scm
    │   │       │   ├── config.toml
    │   │       │   ├── highlights.scm
    │   │       │   ├── imports.scm
    │   │       │   ├── indents.scm
    │   │       │   ├── injections.scm
    │   │       │   ├── outline.scm
    │   │       │   ├── overrides.scm
    │   │       │   └── textobjects.scm
    │   │       ├── cpp.rs
    │   │       ├── css/
    │   │       │   ├── brackets.scm
    │   │       │   ├── config.toml
    │   │       │   ├── highlights.scm
    │   │       │   ├── indents.scm
    │   │       │   ├── injections.scm
    │   │       │   ├── outline.scm
    │   │       │   ├── overrides.scm
    │   │       │   └── textobjects.scm
    │   │       ├── css.rs
    │   │       ├── diff/
    │   │       │   ├── config.toml
    │   │       │   ├── highlights.scm
    │   │       │   └── injections.scm
    │   │       ├── eslint.rs
    │   │       ├── gitcommit/
    │   │       │   ├── config.toml
    │   │       │   ├── highlights.scm
    │   │       │   └── injections.scm
    │   │       ├── go/
    │   │       │   ├── brackets.scm
    │   │       │   ├── config.toml
    │   │       │   ├── debugger.scm
    │   │       │   ├── highlights.scm
    │   │       │   ├── imports.scm
    │   │       │   ├── indents.scm
    │   │       │   ├── injections.scm
    │   │       │   ├── outline.scm
    │   │       │   ├── overrides.scm
    │   │       │   ├── runnables.scm
    │   │       │   └── textobjects.scm
    │   │       ├── go.rs
    │   │       ├── gomod/
    │   │       │   ├── config.toml
    │   │       │   ├── highlights.scm
    │   │       │   ├── injections.scm
    │   │       │   └── structure.scm
    │   │       ├── gowork/
    │   │       │   ├── config.toml
    │   │       │   ├── highlights.scm
    │   │       │   └── injections.scm
    │   │       ├── javascript/
    │   │       │   ├── brackets.scm
    │   │       │   ├── config.toml
    │   │       │   ├── contexts.scm
    │   │       │   ├── debugger.scm
    │   │       │   ├── highlights.scm
    │   │       │   ├── imports.scm
    │   │       │   ├── indents.scm
    │   │       │   ├── injections.scm
    │   │       │   ├── outline.scm
    │   │       │   ├── overrides.scm
    │   │       │   ├── runnables.scm
    │   │       │   └── textobjects.scm
    │   │       ├── jsdoc/
    │   │       │   ├── brackets.scm
    │   │       │   ├── config.toml
    │   │       │   └── highlights.scm
    │   │       ├── json/
    │   │       │   ├── brackets.scm
    │   │       │   ├── config.toml
    │   │       │   ├── highlights.scm
    │   │       │   ├── indents.scm
    │   │       │   ├── outline.scm
    │   │       │   ├── overrides.scm
    │   │       │   ├── redactions.scm
    │   │       │   ├── runnables.scm
    │   │       │   └── textobjects.scm
    │   │       ├── json.rs
    │   │       ├── jsonc/
    │   │       │   ├── brackets.scm
    │   │       │   ├── config.toml
    │   │       │   ├── highlights.scm
    │   │       │   ├── indents.scm
    │   │       │   ├── injections.scm
    │   │       │   ├── outline.scm
    │   │       │   ├── overrides.scm
    │   │       │   ├── redactions.scm
    │   │       │   └── textobjects.scm
    │   │       ├── lib.rs
    │   │       ├── markdown/
    │   │       │   ├── brackets.scm
    │   │       │   ├── config.toml
    │   │       │   ├── highlights.scm
    │   │       │   ├── indents.scm
    │   │       │   ├── injections.scm
    │   │       │   ├── outline.scm
    │   │       │   └── textobjects.scm
    │   │       ├── markdown-inline/
    │   │       │   ├── config.toml
    │   │       │   ├── highlights.scm
    │   │       │   └── injections.scm
    │   │       ├── package_json.rs
    │   │       ├── python/
    │   │       │   ├── brackets.scm
    │   │       │   ├── config.toml
    │   │       │   ├── debugger.scm
    │   │       │   ├── highlights.scm
    │   │       │   ├── imports.scm
    │   │       │   ├── indents.scm
    │   │       │   ├── injections.scm
    │   │       │   ├── outline.scm
    │   │       │   ├── overrides.scm
    │   │       │   ├── runnables.scm
    │   │       │   └── textobjects.scm
    │   │       ├── python.rs
    │   │       ├── regex/
    │   │       │   ├── brackets.scm
    │   │       │   ├── config.toml
    │   │       │   └── highlights.scm
    │   │       ├── rust/
    │   │       │   ├── brackets.scm
    │   │       │   ├── config.toml
    │   │       │   ├── debugger.scm
    │   │       │   ├── highlights.scm
    │   │       │   ├── imports.scm
    │   │       │   ├── indents.scm
    │   │       │   ├── injections.scm
    │   │       │   ├── outline.scm
    │   │       │   ├── overrides.scm
    │   │       │   ├── runnables.scm
    │   │       │   └── textobjects.scm
    │   │       ├── rust.rs
    │   │       ├── tailwind.rs
    │   │       ├── tailwindcss.rs
    │   │       ├── tsx/
    │   │       │   ├── brackets.scm
    │   │       │   ├── config.toml
    │   │       │   ├── debugger.scm
    │   │       │   ├── highlights.scm
    │   │       │   ├── imports.scm
    │   │       │   ├── indents.scm
    │   │       │   ├── injections.scm
    │   │       │   ├── outline.scm
    │   │       │   ├── overrides.scm
    │   │       │   ├── runnables.scm
    │   │       │   └── textobjects.scm
    │   │       ├── typescript/
    │   │       │   ├── brackets.scm
    │   │       │   ├── config.toml
    │   │       │   ├── debugger.scm
    │   │       │   ├── highlights.scm
    │   │       │   ├── imports.scm
    │   │       │   ├── indents.scm
    │   │       │   ├── injections.scm
    │   │       │   ├── outline.scm
    │   │       │   ├── overrides.scm
    │   │       │   ├── runnables.scm
    │   │       │   └── textobjects.scm
    │   │       ├── typescript.rs
    │   │       ├── vtsls.rs
    │   │       ├── yaml/
    │   │       │   ├── brackets.scm
    │   │       │   ├── config.toml
    │   │       │   ├── highlights.scm
    │   │       │   ├── injections.scm
    │   │       │   ├── outline.scm
    │   │       │   ├── overrides.scm
    │   │       │   ├── redactions.scm
    │   │       │   └── textobjects.scm
    │   │       ├── yaml.rs
    │   │       └── zed-keybind-context/
    │   │           ├── brackets.scm
    │   │           ├── config.toml
    │   │           └── highlights.scm
    │   ├── line_ending_selector/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── line_ending_indicator.rs
    │   │       └── line_ending_selector.rs
    │   ├── livekit_api/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── build.rs
    │   │   ├── src/
    │   │   │   ├── livekit_api.rs
    │   │   │   ├── proto.rs
    │   │   │   └── token.rs
    │   │   └── vendored/
    │   │       └── protocol/
    │   │           ├── README.md
    │   │           ├── livekit_analytics.proto
    │   │           ├── livekit_egress.proto
    │   │           ├── livekit_ingress.proto
    │   │           ├── livekit_internal.proto
    │   │           ├── livekit_models.proto
    │   │           ├── livekit_room.proto
    │   │           ├── livekit_rpc_internal.proto
    │   │           ├── livekit_rtc.proto
    │   │           └── livekit_webhook.proto
    │   ├── livekit_client/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── examples/
    │   │   │   └── test_app.rs
    │   │   └── src/
    │   │       ├── lib.rs
    │   │       ├── livekit_client/
    │   │       │   ├── playback/
    │   │       │   │   └── source.rs
    │   │       │   └── playback.rs
    │   │       ├── livekit_client.rs
    │   │       ├── mock_client/
    │   │       │   ├── participant.rs
    │   │       │   ├── publication.rs
    │   │       │   └── track.rs
    │   │       ├── mock_client.rs
    │   │       ├── record.rs
    │   │       ├── remote_video_track_view.rs
    │   │       └── test.rs
    │   ├── lmstudio/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── lmstudio.rs
    │   ├── lsp/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── input_handler.rs
    │   │       └── lsp.rs
    │   ├── markdown/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── examples/
    │   │   │   ├── markdown.rs
    │   │   │   └── markdown_as_child.rs
    │   │   └── src/
    │   │       ├── markdown.rs
    │   │       ├── parser.rs
    │   │       └── path_range.rs
    │   ├── markdown_preview/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── markdown_elements.rs
    │   │       ├── markdown_minifier.rs
    │   │       ├── markdown_parser.rs
    │   │       ├── markdown_preview.rs
    │   │       ├── markdown_preview_view.rs
    │   │       └── markdown_renderer.rs
    │   ├── media/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-APACHE
    │   │   ├── build.rs
    │   │   └── src/
    │   │       ├── bindings.h
    │   │       ├── bindings.rs
    │   │       └── media.rs
    │   ├── menu/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── menu.rs
    │   ├── migrator/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── migrations/
    │   │       │   ├── m_2025_01_02/
    │   │       │   │   └── settings.rs
    │   │       │   ├── m_2025_01_29/
    │   │       │   │   ├── keymap.rs
    │   │       │   │   └── settings.rs
    │   │       │   ├── m_2025_01_30/
    │   │       │   │   ├── keymap.rs
    │   │       │   │   └── settings.rs
    │   │       │   ├── m_2025_03_03/
    │   │       │   │   └── keymap.rs
    │   │       │   ├── m_2025_03_06/
    │   │       │   │   └── keymap.rs
    │   │       │   ├── m_2025_03_29/
    │   │       │   │   └── settings.rs
    │   │       │   ├── m_2025_04_15/
    │   │       │   │   ├── keymap.rs
    │   │       │   │   └── settings.rs
    │   │       │   ├── m_2025_04_21/
    │   │       │   │   └── settings.rs
    │   │       │   ├── m_2025_04_23/
    │   │       │   │   └── settings.rs
    │   │       │   ├── m_2025_05_05/
    │   │       │   │   └── settings.rs
    │   │       │   ├── m_2025_05_08/
    │   │       │   │   └── settings.rs
    │   │       │   ├── m_2025_05_29/
    │   │       │   │   └── settings.rs
    │   │       │   ├── m_2025_06_16/
    │   │       │   │   └── settings.rs
    │   │       │   ├── m_2025_06_25/
    │   │       │   │   └── settings.rs
    │   │       │   ├── m_2025_06_27/
    │   │       │   │   └── settings.rs
    │   │       │   ├── m_2025_07_08/
    │   │       │   │   └── settings.rs
    │   │       │   ├── m_2025_10_01/
    │   │       │   │   └── settings.rs
    │   │       │   ├── m_2025_10_02/
    │   │       │   │   └── settings.rs
    │   │       │   ├── m_2025_10_03/
    │   │       │   │   └── settings.rs
    │   │       │   ├── m_2025_10_16/
    │   │       │   │   └── settings.rs
    │   │       │   ├── m_2025_10_17/
    │   │       │   │   └── settings.rs
    │   │       │   ├── m_2025_10_21/
    │   │       │   │   └── settings.rs
    │   │       │   ├── m_2025_11_12/
    │   │       │   │   └── settings.rs
    │   │       │   ├── m_2025_11_20/
    │   │       │   │   └── settings.rs
    │   │       │   ├── m_2025_11_25/
    │   │       │   │   └── settings.rs
    │   │       │   ├── m_2025_12_01/
    │   │       │   │   └── settings.rs
    │   │       │   ├── m_2025_12_08/
    │   │       │   │   └── keymap.rs
    │   │       │   └── m_2025_12_15/
    │   │       │       └── settings.rs
    │   │       ├── migrations.rs
    │   │       ├── migrator.rs
    │   │       ├── patterns/
    │   │       │   ├── keymap.rs
    │   │       │   └── settings.rs
    │   │       └── patterns.rs
    │   ├── miniprofiler_ui/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── miniprofiler_ui.rs
    │   ├── mistral/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── mistral.rs
    │   ├── multi_buffer/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── anchor.rs
    │   │       ├── multi_buffer.rs
    │   │       ├── multi_buffer_tests.rs
    │   │       ├── path_key.rs
    │   │       └── transaction.rs
    │   ├── nc/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── nc.rs
    │   ├── net/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── async_net.rs
    │   │       ├── listener.rs
    │   │       ├── net.rs
    │   │       ├── socket.rs
    │   │       ├── stream.rs
    │   │       └── util.rs
    │   ├── node_runtime/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── node_runtime.rs
    │   ├── notifications/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── notification_store.rs
    │   │       ├── notifications.rs
    │   │       └── status_toast.rs
    │   ├── ollama/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── ollama.rs
    │   ├── onboarding/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── base_keymap_picker.rs
    │   │       ├── basics_page.rs
    │   │       ├── multibuffer_hint.rs
    │   │       ├── onboarding.rs
    │   │       └── theme_preview.rs
    │   ├── open_ai/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── open_ai.rs
    │   ├── open_router/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── open_router.rs
    │   ├── outline/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── outline.rs
    │   ├── outline_panel/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── outline_panel.rs
    │   │       └── outline_panel_settings.rs
    │   ├── panel/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── panel.rs
    │   ├── paths/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── paths.rs
    │   ├── picker/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── head.rs
    │   │       ├── highlighted_match_with_paths.rs
    │   │       ├── picker.rs
    │   │       └── popover_menu.rs
    │   ├── prettier/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── prettier.rs
    │   │       └── prettier_server.js
    │   ├── project/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── agent_server_store.rs
    │   │       ├── buffer_store.rs
    │   │       ├── color_extractor.rs
    │   │       ├── connection_manager.rs
    │   │       ├── context_server_store/
    │   │       │   ├── extension.rs
    │   │       │   └── registry.rs
    │   │       ├── context_server_store.rs
    │   │       ├── debounced_delay.rs
    │   │       ├── debugger/
    │   │       │   ├── breakpoint_store.rs
    │   │       │   ├── dap_command.rs
    │   │       │   ├── dap_store.rs
    │   │       │   ├── locators/
    │   │       │   │   ├── cargo.rs
    │   │       │   │   ├── go.rs
    │   │       │   │   ├── node.rs
    │   │       │   │   └── python.rs
    │   │       │   ├── locators.rs
    │   │       │   ├── memory.rs
    │   │       │   ├── session.rs
    │   │       │   └── test.rs
    │   │       ├── debugger.rs
    │   │       ├── environment.rs
    │   │       ├── git_store/
    │   │       │   ├── branch_diff.rs
    │   │       │   ├── conflict_set.rs
    │   │       │   ├── git_traversal.rs
    │   │       │   └── pending_op.rs
    │   │       ├── git_store.rs
    │   │       ├── image_store.rs
    │   │       ├── lsp_command/
    │   │       │   └── signature_help.rs
    │   │       ├── lsp_command.rs
    │   │       ├── lsp_store/
    │   │       │   ├── clangd_ext.rs
    │   │       │   ├── inlay_hint_cache.rs
    │   │       │   ├── json_language_server_ext.rs
    │   │       │   ├── log_store.rs
    │   │       │   ├── lsp_ext_command.rs
    │   │       │   ├── rust_analyzer_ext.rs
    │   │       │   └── vue_language_server_ext.rs
    │   │       ├── lsp_store.rs
    │   │       ├── manifest_tree/
    │   │       │   ├── manifest_store.rs
    │   │       │   ├── path_trie.rs
    │   │       │   └── server_tree.rs
    │   │       ├── manifest_tree.rs
    │   │       ├── persistence.rs
    │   │       ├── prettier_store.rs
    │   │       ├── project.rs
    │   │       ├── project_search.rs
    │   │       ├── project_settings.rs
    │   │       ├── project_tests.rs
    │   │       ├── search.rs
    │   │       ├── search_history.rs
    │   │       ├── task_inventory.rs
    │   │       ├── task_store.rs
    │   │       ├── telemetry_snapshot.rs
    │   │       ├── terminals.rs
    │   │       ├── toolchain_store.rs
    │   │       ├── trusted_worktrees.rs
    │   │       ├── worktree_store.rs
    │   │       ├── x.py
    │   │       └── yarn.rs
    │   ├── project_benchmarks/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── main.rs
    │   ├── project_panel/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── benches/
    │   │   │   ├── linux_repo_snapshot.txt
    │   │   │   └── sorting.rs
    │   │   └── src/
    │   │       ├── project_panel.rs
    │   │       ├── project_panel_settings.rs
    │   │       ├── project_panel_tests.rs
    │   │       └── utils.rs
    │   ├── project_symbols/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── project_symbols.rs
    │   ├── prompt_store/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── prompt_store.rs
    │   │       └── prompts.rs
    │   ├── proto/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── build.rs
    │   │   ├── proto/
    │   │   │   ├── ai.proto
    │   │   │   ├── app.proto
    │   │   │   ├── buf.yaml
    │   │   │   ├── buffer.proto
    │   │   │   ├── call.proto
    │   │   │   ├── channel.proto
    │   │   │   ├── core.proto
    │   │   │   ├── debugger.proto
    │   │   │   ├── git.proto
    │   │   │   ├── image.proto
    │   │   │   ├── lsp.proto
    │   │   │   ├── notification.proto
    │   │   │   ├── task.proto
    │   │   │   ├── toolchain.proto
    │   │   │   ├── worktree.proto
    │   │   │   └── zed.proto
    │   │   └── src/
    │   │       ├── error.rs
    │   │       ├── macros.rs
    │   │       ├── proto.rs
    │   │       └── typed_envelope.rs
    │   ├── recent_projects/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── dev_container.rs
    │   │       ├── dev_container_suggest.rs
    │   │       ├── disconnected_overlay.rs
    │   │       ├── recent_projects.rs
    │   │       ├── remote_connections.rs
    │   │       ├── remote_servers.rs
    │   │       ├── ssh_config.rs
    │   │       └── wsl_picker.rs
    │   ├── refineable/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-APACHE
    │   │   ├── derive_refineable/
    │   │   │   ├── Cargo.toml
    │   │   │   ├── LICENSE-APACHE
    │   │   │   └── src/
    │   │   │       └── derive_refineable.rs
    │   │   └── src/
    │   │       └── refineable.rs
    │   ├── release_channel/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── lib.rs
    │   ├── remote/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── json_log.rs
    │   │       ├── protocol.rs
    │   │       ├── proxy.rs
    │   │       ├── remote.rs
    │   │       ├── remote_client.rs
    │   │       ├── transport/
    │   │       │   ├── docker.rs
    │   │       │   ├── mock.rs
    │   │       │   ├── ssh.rs
    │   │       │   └── wsl.rs
    │   │       └── transport.rs
    │   ├── remote_server/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── build.rs
    │   │   └── src/
    │   │       ├── headless_project.rs
    │   │       ├── main.rs
    │   │       ├── remote_editing_tests.rs
    │   │       ├── remote_server.rs
    │   │       └── unix.rs
    │   ├── repl/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── components/
    │   │       │   ├── kernel_list_item.rs
    │   │       │   └── kernel_options.rs
    │   │       ├── components.rs
    │   │       ├── jupyter_settings.rs
    │   │       ├── kernels/
    │   │       │   ├── mod.rs
    │   │       │   ├── native_kernel.rs
    │   │       │   └── remote_kernels.rs
    │   │       ├── notebook/
    │   │       │   ├── cell.rs
    │   │       │   └── notebook_ui.rs
    │   │       ├── notebook.rs
    │   │       ├── outputs/
    │   │       │   ├── image.rs
    │   │       │   ├── markdown.rs
    │   │       │   ├── plain.rs
    │   │       │   ├── table.rs
    │   │       │   └── user_error.rs
    │   │       ├── outputs.rs
    │   │       ├── repl.rs
    │   │       ├── repl_editor.rs
    │   │       ├── repl_sessions_ui.rs
    │   │       ├── repl_settings.rs
    │   │       ├── repl_store.rs
    │   │       └── session.rs
    │   ├── reqwest_client/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-APACHE
    │   │   └── src/
    │   │       └── reqwest_client.rs
    │   ├── rich_text/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── rich_text.rs
    │   ├── rope/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── benches/
    │   │   │   └── rope_benchmark.rs
    │   │   └── src/
    │   │       ├── chunk.rs
    │   │       ├── offset_utf16.rs
    │   │       ├── point.rs
    │   │       ├── point_utf16.rs
    │   │       ├── rope.rs
    │   │       └── unclipped.rs
    │   ├── rpc/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── auth.rs
    │   │       ├── conn.rs
    │   │       ├── extension.rs
    │   │       ├── macros.rs
    │   │       ├── message_stream.rs
    │   │       ├── notification.rs
    │   │       ├── peer.rs
    │   │       ├── proto_client.rs
    │   │       └── rpc.rs
    │   ├── rules_library/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── rules_library.rs
    │   ├── scheduler/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-APACHE
    │   │   └── src/
    │   │       ├── clock.rs
    │   │       ├── executor.rs
    │   │       ├── scheduler.rs
    │   │       ├── test_scheduler.rs
    │   │       └── tests.rs
    │   ├── schema_generator/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── README.md
    │   │   └── src/
    │   │       └── main.rs
    │   ├── search/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── buffer_search/
    │   │       │   └── registrar.rs
    │   │       ├── buffer_search.rs
    │   │       ├── project_search.rs
    │   │       ├── search.rs
    │   │       ├── search_bar.rs
    │   │       └── search_status_button.rs
    │   ├── session/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── session.rs
    │   ├── settings/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── base_keymap_setting.rs
    │   │       ├── editable_setting_control.rs
    │   │       ├── fallible_options.rs
    │   │       ├── keymap_file.rs
    │   │       ├── merge_from.rs
    │   │       ├── serde_helper.rs
    │   │       ├── settings.rs
    │   │       ├── settings_content/
    │   │       │   ├── agent.rs
    │   │       │   ├── editor.rs
    │   │       │   ├── extension.rs
    │   │       │   ├── language.rs
    │   │       │   ├── language_model.rs
    │   │       │   ├── project.rs
    │   │       │   ├── terminal.rs
    │   │       │   ├── theme.rs
    │   │       │   └── workspace.rs
    │   │       ├── settings_content.rs
    │   │       ├── settings_file.rs
    │   │       ├── settings_store.rs
    │   │       └── vscode_import.rs
    │   ├── settings_json/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── settings_json.rs
    │   ├── settings_macros/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── settings_macros.rs
    │   ├── settings_profile_selector/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── settings_profile_selector.rs
    │   ├── settings_ui/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── components/
    │   │       │   ├── dropdown.rs
    │   │       │   ├── font_picker.rs
    │   │       │   ├── icon_theme_picker.rs
    │   │       │   ├── input_field.rs
    │   │       │   ├── section_items.rs
    │   │       │   └── theme_picker.rs
    │   │       ├── components.rs
    │   │       ├── page_data.rs
    │   │       ├── pages/
    │   │       │   └── edit_prediction_provider_setup.rs
    │   │       ├── pages.rs
    │   │       └── settings_ui.rs
    │   ├── snippet/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── snippet.rs
    │   ├── snippet_provider/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── extension_snippet.rs
    │   │       ├── format.rs
    │   │       ├── lib.rs
    │   │       └── registry.rs
    │   ├── snippets_ui/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── snippets_ui.rs
    │   ├── sqlez/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── bindable.rs
    │   │       ├── connection.rs
    │   │       ├── domain.rs
    │   │       ├── lib.rs
    │   │       ├── migrations.rs
    │   │       ├── savepoint.rs
    │   │       ├── statement.rs
    │   │       ├── thread_safe_connection.rs
    │   │       ├── typed_statements.rs
    │   │       └── util.rs
    │   ├── sqlez_macros/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── sqlez_macros.rs
    │   ├── story/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── story.rs
    │   ├── storybook/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── build.rs
    │   │   ├── docs/
    │   │   │   └── thoughts.md
    │   │   └── src/
    │   │       ├── actions.rs
    │   │       ├── app_menus.rs
    │   │       ├── assets.rs
    │   │       ├── stories/
    │   │       │   ├── auto_height_editor.rs
    │   │       │   ├── cursor.rs
    │   │       │   ├── focus.rs
    │   │       │   ├── indent_guides.rs
    │   │       │   ├── kitchen_sink.rs
    │   │       │   ├── overflow_scroll.rs
    │   │       │   ├── picker.rs
    │   │       │   ├── scroll.rs
    │   │       │   ├── text.rs
    │   │       │   ├── viewport_units.rs
    │   │       │   └── with_rem_size.rs
    │   │       ├── stories.rs
    │   │       ├── story_selector.rs
    │   │       └── storybook.rs
    │   ├── streaming_diff/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── streaming_diff.rs
    │   ├── sum_tree/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-APACHE
    │   │   └── src/
    │   │       ├── cursor.rs
    │   │       ├── sum_tree.rs
    │   │       └── tree_map.rs
    │   ├── supermaven/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── messages.rs
    │   │       ├── supermaven.rs
    │   │       └── supermaven_edit_prediction_delegate.rs
    │   ├── supermaven_api/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── supermaven_api.rs
    │   ├── svg_preview/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── svg_preview.rs
    │   │       └── svg_preview_view.rs
    │   ├── system_specs/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── system_specs.rs
    │   ├── tab_switcher/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── tab_switcher.rs
    │   │       └── tab_switcher_tests.rs
    │   ├── task/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── src/
    │   │   │   ├── adapter_schema.rs
    │   │   │   ├── debug_format.rs
    │   │   │   ├── serde_helpers.rs
    │   │   │   ├── static_source.rs
    │   │   │   ├── task.rs
    │   │   │   ├── task_template.rs
    │   │   │   ├── vscode_debug_format.rs
    │   │   │   └── vscode_format.rs
    │   │   └── test_data/
    │   │       ├── rust-analyzer.json
    │   │       └── typescript.json
    │   ├── tasks_ui/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── modal.rs
    │   │       └── tasks_ui.rs
    │   ├── telemetry/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── telemetry.rs
    │   ├── telemetry_events/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── telemetry_events.rs
    │   ├── terminal/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── mappings/
    │   │       │   ├── colors.rs
    │   │       │   ├── keys.rs
    │   │       │   ├── mod.rs
    │   │       │   └── mouse.rs
    │   │       ├── pty_info.rs
    │   │       ├── terminal.rs
    │   │       ├── terminal_hyperlinks.rs
    │   │       └── terminal_settings.rs
    │   ├── terminal_view/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── README.md
    │   │   ├── scripts/
    │   │   │   ├── print256color.sh
    │   │   │   └── truecolor.sh
    │   │   └── src/
    │   │       ├── persistence.rs
    │   │       ├── terminal_element.rs
    │   │       ├── terminal_panel.rs
    │   │       ├── terminal_path_like_target.rs
    │   │       ├── terminal_scrollbar.rs
    │   │       ├── terminal_slash_command.rs
    │   │       └── terminal_view.rs
    │   ├── text/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── anchor.rs
    │   │       ├── locator.rs
    │   │       ├── network.rs
    │   │       ├── operation_queue.rs
    │   │       ├── patch.rs
    │   │       ├── selection.rs
    │   │       ├── subscription.rs
    │   │       ├── tests.rs
    │   │       ├── text.rs
    │   │       └── undo_map.rs
    │   ├── theme/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── default_colors.rs
    │   │       ├── fallback_themes.rs
    │   │       ├── font_family_cache.rs
    │   │       ├── icon_theme.rs
    │   │       ├── icon_theme_schema.rs
    │   │       ├── registry.rs
    │   │       ├── scale.rs
    │   │       ├── schema.rs
    │   │       ├── settings.rs
    │   │       ├── styles/
    │   │       │   ├── accents.rs
    │   │       │   ├── colors.rs
    │   │       │   ├── players.rs
    │   │       │   ├── status.rs
    │   │       │   ├── syntax.rs
    │   │       │   └── system.rs
    │   │       ├── styles.rs
    │   │       └── theme.rs
    │   ├── theme_extension/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── theme_extension.rs
    │   ├── theme_importer/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── README.md
    │   │   └── src/
    │   │       ├── color.rs
    │   │       ├── main.rs
    │   │       ├── vscode/
    │   │       │   ├── converter.rs
    │   │       │   ├── syntax.rs
    │   │       │   └── theme.rs
    │   │       └── vscode.rs
    │   ├── theme_selector/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── icon_theme_selector.rs
    │   │       └── theme_selector.rs
    │   ├── time_format/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── time_format.rs
    │   ├── title_bar/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── build.rs
    │   │   └── src/
    │   │       ├── application_menu.rs
    │   │       ├── collab.rs
    │   │       ├── onboarding_banner.rs
    │   │       ├── platform_title_bar.rs
    │   │       ├── platforms/
    │   │       │   ├── platform_linux.rs
    │   │       │   ├── platform_mac.rs
    │   │       │   └── platform_windows.rs
    │   │       ├── platforms.rs
    │   │       ├── stories/
    │   │       │   └── application_menu.rs
    │   │       ├── stories.rs
    │   │       ├── system_window_tabs.rs
    │   │       ├── title_bar.rs
    │   │       └── title_bar_settings.rs
    │   ├── toolchain_selector/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── active_toolchain.rs
    │   │       └── toolchain_selector.rs
    │   ├── ui/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── component_prelude.rs
    │   │       ├── components/
    │   │       │   ├── ai/
    │   │       │   │   ├── configured_api_card.rs
    │   │       │   │   └── copilot_configuration_callout.rs
    │   │       │   ├── ai.rs
    │   │       │   ├── avatar.rs
    │   │       │   ├── banner.rs
    │   │       │   ├── button/
    │   │       │   │   ├── button.rs
    │   │       │   │   ├── button_icon.rs
    │   │       │   │   ├── button_like.rs
    │   │       │   │   ├── button_link.rs
    │   │       │   │   ├── copy_button.rs
    │   │       │   │   ├── icon_button.rs
    │   │       │   │   ├── split_button.rs
    │   │       │   │   └── toggle_button.rs
    │   │       │   ├── button.rs
    │   │       │   ├── callout.rs
    │   │       │   ├── chip.rs
    │   │       │   ├── content_group.rs
    │   │       │   ├── context_menu.rs
    │   │       │   ├── data_table.rs
    │   │       │   ├── diff_stat.rs
    │   │       │   ├── disclosure.rs
    │   │       │   ├── divider.rs
    │   │       │   ├── dropdown_menu.rs
    │   │       │   ├── facepile.rs
    │   │       │   ├── group.rs
    │   │       │   ├── icon/
    │   │       │   │   ├── decorated_icon.rs
    │   │       │   │   └── icon_decoration.rs
    │   │       │   ├── icon.rs
    │   │       │   ├── image.rs
    │   │       │   ├── indent_guides.rs
    │   │       │   ├── indicator.rs
    │   │       │   ├── keybinding.rs
    │   │       │   ├── keybinding_hint.rs
    │   │       │   ├── label/
    │   │       │   │   ├── highlighted_label.rs
    │   │       │   │   ├── label.rs
    │   │       │   │   ├── label_like.rs
    │   │       │   │   ├── loading_label.rs
    │   │       │   │   └── spinner_label.rs
    │   │       │   ├── label.rs
    │   │       │   ├── list/
    │   │       │   │   ├── list.rs
    │   │       │   │   ├── list_bullet_item.rs
    │   │       │   │   ├── list_header.rs
    │   │       │   │   ├── list_item.rs
    │   │       │   │   ├── list_separator.rs
    │   │       │   │   └── list_sub_header.rs
    │   │       │   ├── list.rs
    │   │       │   ├── modal.rs
    │   │       │   ├── navigable.rs
    │   │       │   ├── notification/
    │   │       │   │   └── alert_modal.rs
    │   │       │   ├── notification.rs
    │   │       │   ├── popover.rs
    │   │       │   ├── popover_menu.rs
    │   │       │   ├── progress/
    │   │       │   │   └── progress_bar.rs
    │   │       │   ├── progress.rs
    │   │       │   ├── radio.rs
    │   │       │   ├── right_click_menu.rs
    │   │       │   ├── scrollbar.rs
    │   │       │   ├── settings_container.rs
    │   │       │   ├── settings_group.rs
    │   │       │   ├── stack.rs
    │   │       │   ├── sticky_items.rs
    │   │       │   ├── stories/
    │   │       │   │   └── context_menu.rs
    │   │       │   ├── stories.rs
    │   │       │   ├── tab.rs
    │   │       │   ├── tab_bar.rs
    │   │       │   ├── thread_item.rs
    │   │       │   ├── toggle.rs
    │   │       │   ├── tooltip.rs
    │   │       │   └── tree_view_item.rs
    │   │       ├── components.rs
    │   │       ├── prelude.rs
    │   │       ├── styles/
    │   │       │   ├── animation.rs
    │   │       │   ├── appearance.rs
    │   │       │   ├── color.rs
    │   │       │   ├── elevation.rs
    │   │       │   ├── platform.rs
    │   │       │   ├── severity.rs
    │   │       │   ├── spacing.rs
    │   │       │   ├── typography.rs
    │   │       │   └── units.rs
    │   │       ├── styles.rs
    │   │       ├── traits/
    │   │       │   ├── animation_ext.rs
    │   │       │   ├── clickable.rs
    │   │       │   ├── disableable.rs
    │   │       │   ├── fixed.rs
    │   │       │   ├── styled_ext.rs
    │   │       │   ├── toggleable.rs
    │   │       │   ├── transformable.rs
    │   │       │   └── visible_on_hover.rs
    │   │       ├── traits.rs
    │   │       ├── ui.rs
    │   │       ├── utils/
    │   │       │   ├── apca_contrast.rs
    │   │       │   ├── color_contrast.rs
    │   │       │   ├── corner_solver.rs
    │   │       │   ├── format_distance.rs
    │   │       │   ├── search_input.rs
    │   │       │   └── with_rem_size.rs
    │   │       └── utils.rs
    │   ├── ui_input/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── input_field.rs
    │   │       ├── number_field.rs
    │   │       └── ui_input.rs
    │   ├── ui_macros/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── derive_register_component.rs
    │   │       ├── dynamic_spacing.rs
    │   │       └── ui_macros.rs
    │   ├── ui_prompt/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── ui_prompt.rs
    │   ├── util/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-APACHE
    │   │   └── src/
    │   │       ├── arc_cow.rs
    │   │       ├── archive.rs
    │   │       ├── command.rs
    │   │       ├── fs.rs
    │   │       ├── markdown.rs
    │   │       ├── paths.rs
    │   │       ├── process.rs
    │   │       ├── redact.rs
    │   │       ├── rel_path.rs
    │   │       ├── schemars.rs
    │   │       ├── serde.rs
    │   │       ├── shell.rs
    │   │       ├── shell_builder.rs
    │   │       ├── shell_env.rs
    │   │       ├── size.rs
    │   │       ├── test/
    │   │       │   ├── assertions.rs
    │   │       │   └── marked_text.rs
    │   │       ├── test.rs
    │   │       ├── time.rs
    │   │       └── util.rs
    │   ├── util_macros/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-APACHE
    │   │   └── src/
    │   │       └── util_macros.rs
    │   ├── vercel/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── vercel.rs
    │   ├── vim/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── README.md
    │   │   ├── src/
    │   │   │   ├── change_list.rs
    │   │   │   ├── command.rs
    │   │   │   ├── digraph/
    │   │   │   │   └── default.rs
    │   │   │   ├── digraph.rs
    │   │   │   ├── helix/
    │   │   │   │   ├── boundary.rs
    │   │   │   │   ├── duplicate.rs
    │   │   │   │   ├── object.rs
    │   │   │   │   ├── paste.rs
    │   │   │   │   ├── select.rs
    │   │   │   │   └── surround.rs
    │   │   │   ├── helix.rs
    │   │   │   ├── indent.rs
    │   │   │   ├── insert.rs
    │   │   │   ├── mode_indicator.rs
    │   │   │   ├── motion.rs
    │   │   │   ├── normal/
    │   │   │   │   ├── change.rs
    │   │   │   │   ├── convert.rs
    │   │   │   │   ├── delete.rs
    │   │   │   │   ├── increment.rs
    │   │   │   │   ├── mark.rs
    │   │   │   │   ├── paste.rs
    │   │   │   │   ├── repeat.rs
    │   │   │   │   ├── scroll.rs
    │   │   │   │   ├── search.rs
    │   │   │   │   ├── substitute.rs
    │   │   │   │   ├── toggle_comments.rs
    │   │   │   │   └── yank.rs
    │   │   │   ├── normal.rs
    │   │   │   ├── object.rs
    │   │   │   ├── replace.rs
    │   │   │   ├── rewrap.rs
    │   │   │   ├── state.rs
    │   │   │   ├── surrounds.rs
    │   │   │   ├── test/
    │   │   │   │   ├── neovim_backed_test_context.rs
    │   │   │   │   ├── neovim_connection.rs
    │   │   │   │   └── vim_test_context.rs
    │   │   │   ├── test.rs
    │   │   │   ├── vim.rs
    │   │   │   └── visual.rs
    │   │   └── test_data/
    │   │       ├── neovim_backed_test_context_works.json
    │   │       ├── test_a.json
    │   │       ├── test_around_containing_word_indent.json
    │   │       ├── test_b.json
    │   │       ├── test_backspace.json
    │   │       ├── test_backspace_non_ascii_bol.json
    │   │       ├── test_backwards_n.json
    │   │       ├── test_blackhole_register.json
    │   │       ├── test_builtin_marks.json
    │   │       ├── test_capital_f_and_capital_t.json
    │   │       ├── test_caret_mark.json
    │   │       ├── test_cc.json
    │   │       ├── test_cgn_nomatch.json
    │   │       ├── test_cgn_repeat.json
    │   │       ├── test_change_0.json
    │   │       ├── test_change_b.json
    │   │       ├── test_change_backspace.json
    │   │       ├── test_change_case.json
    │   │       ├── test_change_case_motion.json
    │   │       ├── test_change_case_motion_object.json
    │   │       ├── test_change_cc.json
    │   │       ├── test_change_e.json
    │   │       ├── test_change_end_of_document.json
    │   │       ├── test_change_end_of_line.json
    │   │       ├── test_change_gg.json
    │   │       ├── test_change_h.json
    │   │       ├── test_change_j.json
    │   │       ├── test_change_k.json
    │   │       ├── test_change_l.json
    │   │       ├── test_change_list_delete.json
    │   │       ├── test_change_list_insert.json
    │   │       ├── test_change_paragraph.json
    │   │       ├── test_change_paragraph_object.json
    │   │       ├── test_change_paragraph_object_with_soft_wrap.json
    │   │       ├── test_change_rot13_motion.json
    │   │       ├── test_change_rot13_object.json
    │   │       ├── test_change_sentence_object.json
    │   │       ├── test_change_surrounding_character_objects.json
    │   │       ├── test_change_w.json
    │   │       ├── test_change_word_object.json
    │   │       ├── test_clear_counts.json
    │   │       ├── test_comma_semicolon.json
    │   │       ├── test_comma_w.json
    │   │       ├── test_command_basics.json
    │   │       ├── test_command_g_normal.json
    │   │       ├── test_command_goto.json
    │   │       ├── test_command_matching_lines.json
    │   │       ├── test_command_ranges.json
    │   │       ├── test_command_replace.json
    │   │       ├── test_command_search.json
    │   │       ├── test_command_visual_replace.json
    │   │       ├── test_convert_to_lower_case.json
    │   │       ├── test_convert_to_rot13.json
    │   │       ├── test_convert_to_upper_case.json
    │   │       ├── test_ctrl_d_u.json
    │   │       ├── test_ctrl_f_b.json
    │   │       ├── test_ctrl_o_dot.json
    │   │       ├── test_ctrl_o_position.json
    │   │       ├── test_ctrl_o_visual.json
    │   │       ├── test_ctrl_v.json
    │   │       ├── test_ctrl_v_control.json
    │   │       ├── test_ctrl_v_escape.json
    │   │       ├── test_ctrl_w_override.json
    │   │       ├── test_ctrl_y_e.json
    │   │       ├── test_d_search.json
    │   │       ├── test_dd.json
    │   │       ├── test_dd_then_paste_without_trailing_newline.json
    │   │       ├── test_del_marks.json
    │   │       ├── test_delete_0.json
    │   │       ├── test_delete_b.json
    │   │       ├── test_delete_end_of_document.json
    │   │       ├── test_delete_end_of_line.json
    │   │       ├── test_delete_end_of_paragraph.json
    │   │       ├── test_delete_gg.json
    │   │       ├── test_delete_h.json
    │   │       ├── test_delete_j.json
    │   │       ├── test_delete_k.json
    │   │       ├── test_delete_key_can_remove_last_character.json
    │   │       ├── test_delete_l.json
    │   │       ├── test_delete_left.json
    │   │       ├── test_delete_next_word_end.json
    │   │       ├── test_delete_paragraph.json
    │   │       ├── test_delete_paragraph_motion.json
    │   │       ├── test_delete_paragraph_object.json
    │   │       ├── test_delete_paragraph_object_with_soft_wrap.json
    │   │       ├── test_delete_paragraph_whitespace.json
    │   │       ├── test_delete_sentence.json
    │   │       ├── test_delete_sentence_object.json
    │   │       ├── test_delete_surrounding_character_objects.json
    │   │       ├── test_delete_to_adjacent_character.json
    │   │       ├── test_delete_to_end_of_line.json
    │   │       ├── test_delete_to_line.json
    │   │       ├── test_delete_unmatched_brace.json
    │   │       ├── test_delete_w.json
    │   │       ├── test_delete_with_counts.json
    │   │       ├── test_delete_word_object.json
    │   │       ├── test_dgn_repeat.json
    │   │       ├── test_digraph_find.json
    │   │       ├── test_digraph_insert_mode.json
    │   │       ├── test_digraph_insert_multicursor.json
    │   │       ├── test_digraph_keymap_conflict.json
    │   │       ├── test_digraph_replace.json
    │   │       ├── test_digraph_replace_mode.json
    │   │       ├── test_dot_mark.json
    │   │       ├── test_dot_repeat.json
    │   │       ├── test_dw_eol.json
    │   │       ├── test_end_of_document.json
    │   │       ├── test_end_of_line_downward.json
    │   │       ├── test_end_of_line_with_neovim.json
    │   │       ├── test_end_of_line_with_vertical_motion.json
    │   │       ├── test_end_of_word.json
    │   │       ├── test_enter.json
    │   │       ├── test_enter_visual_line_mode.json
    │   │       ├── test_enter_visual_mode.json
    │   │       ├── test_escape_while_waiting.json
    │   │       ├── test_f_and_t.json
    │   │       ├── test_find_multibyte.json
    │   │       ├── test_folds.json
    │   │       ├── test_folds_panic.json
    │   │       ├── test_forced_motion_delete_to_end_of_line.json
    │   │       ├── test_forced_motion_delete_to_middle_of_line.json
    │   │       ├── test_forced_motion_delete_to_start_of_line.json
    │   │       ├── test_forced_motion_yank.json
    │   │       ├── test_gg.json
    │   │       ├── test_gi.json
    │   │       ├── test_gn.json
    │   │       ├── test_go_to_percentage.json
    │   │       ├── test_gq.json
    │   │       ├── test_gv.json
    │   │       ├── test_h.json
    │   │       ├── test_h_through_unicode.json
    │   │       ├── test_horizontal_scroll.json
    │   │       ├── test_inclusive_to_exclusive_delete.json
    │   │       ├── test_increment.json
    │   │       ├── test_increment_bin_wrapping_and_padding.json
    │   │       ├── test_increment_hex_casing.json
    │   │       ├── test_increment_hex_wrapping_and_padding.json
    │   │       ├── test_increment_inline.json
    │   │       ├── test_increment_radix.json
    │   │       ├── test_increment_sign_change.json
    │   │       ├── test_increment_sign_change_with_leading_zeros.json
    │   │       ├── test_increment_steps.json
    │   │       ├── test_increment_visual_partial_number.json
    │   │       ├── test_increment_with_changing_leading_zeros.json
    │   │       ├── test_increment_with_dot.json
    │   │       ├── test_increment_with_leading_zeros.json
    │   │       ├── test_increment_with_leading_zeros_and_zero.json
    │   │       ├── test_increment_with_two_dots.json
    │   │       ├── test_increment_wrapping.json
    │   │       ├── test_increment_zero_leading_zeros.json
    │   │       ├── test_indent_gv.json
    │   │       ├── test_insert_ctrl_r.json
    │   │       ├── test_insert_ctrl_y.json
    │   │       ├── test_insert_empty_line.json
    │   │       ├── test_insert_end_of_line.json
    │   │       ├── test_insert_first_non_whitespace.json
    │   │       ├── test_insert_line_above.json
    │   │       ├── test_insert_with_counts.json
    │   │       ├── test_insert_with_repeat.json
    │   │       ├── test_j.json
    │   │       ├── test_jk.json
    │   │       ├── test_jk_max_count.json
    │   │       ├── test_join_lines.json
    │   │       ├── test_jump_list.json
    │   │       ├── test_jump_to_end.json
    │   │       ├── test_jump_to_first_non_whitespace.json
    │   │       ├── test_jump_to_line_boundaries.json
    │   │       ├── test_k.json
    │   │       ├── test_l.json
    │   │       ├── test_lowercase_marks.json
    │   │       ├── test_lt_gt_marks.json
    │   │       ├── test_marks.json
    │   │       ├── test_matching.json
    │   │       ├── test_matching_braces_in_tag.json
    │   │       ├── test_matching_nested_brackets.json
    │   │       ├── test_matching_tags.json
    │   │       ├── test_minibrackets_trailing_space.json
    │   │       ├── test_named_registers.json
    │   │       ├── test_neovim.json
    │   │       ├── test_next_line_start.json
    │   │       ├── test_next_word_end_newline_last_char.json
    │   │       ├── test_normal_command.json
    │   │       ├── test_numbered_registers.json
    │   │       ├── test_o.json
    │   │       ├── test_o_comment.json
    │   │       ├── test_offsets.json
    │   │       ├── test_p_g_v_y.json
    │   │       ├── test_paragraph_multi_delete.json
    │   │       ├── test_paragraph_object_with_landing_positions_not_at_beginning_of_line.json
    │   │       ├── test_paragraphs_dont_wrap.json
    │   │       ├── test_paste.json
    │   │       ├── test_paste_count.json
    │   │       ├── test_paste_visual.json
    │   │       ├── test_paste_visual_block.json
    │   │       ├── test_percent.json
    │   │       ├── test_percent_in_comment.json
    │   │       ├── test_period_mark.json
    │   │       ├── test_plus_minus.json
    │   │       ├── test_previous_word_end.json
    │   │       ├── test_quote_mark.json
    │   │       ├── test_r.json
    │   │       ├── test_record_replay.json
    │   │       ├── test_record_replay_count.json
    │   │       ├── test_record_replay_dot.json
    │   │       ├── test_record_replay_interleaved.json
    │   │       ├── test_record_replay_of_dot.json
    │   │       ├── test_record_replay_recursion.json
    │   │       ├── test_remap_adjacent_dog_cat.json
    │   │       ├── test_remap_nested_pineapple.json
    │   │       ├── test_remap_recursion.json
    │   │       ├── test_repeat_clear_count.json
    │   │       ├── test_repeat_clear_repeat.json
    │   │       ├── test_repeat_grouping_41735.json
    │   │       ├── test_repeat_motion_counts.json
    │   │       ├── test_repeat_over_blur.json
    │   │       ├── test_repeat_visual.json
    │   │       ├── test_repeated_cb.json
    │   │       ├── test_repeated_ce.json
    │   │       ├── test_repeated_cj.json
    │   │       ├── test_repeated_cl.json
    │   │       ├── test_repeated_word.json
    │   │       ├── test_replace_g.json
    │   │       ├── test_replace_mode.json
    │   │       ├── test_replace_mode_repeat.json
    │   │       ├── test_replace_mode_undo.json
    │   │       ├── test_replace_mode_with_counts.json
    │   │       ├── test_replace_n.json
    │   │       ├── test_replace_with_range.json
    │   │       ├── test_replace_with_range_at_start.json
    │   │       ├── test_scroll_beyond_last_line.json
    │   │       ├── test_scroll_jumps.json
    │   │       ├── test_search_skipping.json
    │   │       ├── test_selection_goal.json
    │   │       ├── test_sentence_backwards.json
    │   │       ├── test_sentence_forwards.json
    │   │       ├── test_shift_y.json
    │   │       ├── test_singleline_surrounding_character_objects.json
    │   │       ├── test_singleline_surrounding_character_objects_with_escape.json
    │   │       ├── test_space_non_ascii.json
    │   │       ├── test_space_non_ascii_eol.json
    │   │       ├── test_space_only_ascii_eol.json
    │   │       ├── test_special_registers.json
    │   │       ├── test_start_end_of_paragraph.json
    │   │       ├── test_substitute_line.json
    │   │       ├── test_temporary_mode.json
    │   │       ├── test_undo.json
    │   │       ├── test_undo_last_line.json
    │   │       ├── test_undo_last_line_newline.json
    │   │       ├── test_undo_last_line_newline_many_changes.json
    │   │       ├── test_undo_repeated_insert.json
    │   │       ├── test_unmatched_backward.json
    │   │       ├── test_unmatched_backward_markdown.json
    │   │       ├── test_unmatched_forward.json
    │   │       ├── test_unmatched_forward_markdown.json
    │   │       ├── test_v2ap.json
    │   │       ├── test_v_search.json
    │   │       ├── test_v_search_aa.json
    │   │       ├── test_visual_block_insert.json
    │   │       ├── test_visual_block_issue_2123.json
    │   │       ├── test_visual_block_mode.json
    │   │       ├── test_visual_block_mode_down_right.json
    │   │       ├── test_visual_block_mode_other_end.json
    │   │       ├── test_visual_block_mode_shift_other_end.json
    │   │       ├── test_visual_block_mode_up_left.json
    │   │       ├── test_visual_block_search.json
    │   │       ├── test_visual_block_wrapping_selection.json
    │   │       ├── test_visual_change.json
    │   │       ├── test_visual_delete.json
    │   │       ├── test_visual_line_change.json
    │   │       ├── test_visual_line_delete.json
    │   │       ├── test_visual_match_eol.json
    │   │       ├── test_visual_mode_insert_before_after.json
    │   │       ├── test_visual_object.json
    │   │       ├── test_visual_object_expands.json
    │   │       ├── test_visual_paragraph_object.json
    │   │       ├── test_visual_paragraph_object_with_soft_wrap.json
    │   │       ├── test_visual_sentence_object.json
    │   │       ├── test_visual_shift_d.json
    │   │       ├── test_visual_star_hash.json
    │   │       ├── test_visual_word_object.json
    │   │       ├── test_visual_yank.json
    │   │       ├── test_w.json
    │   │       ├── test_window_bottom.json
    │   │       ├── test_window_middle.json
    │   │       ├── test_window_top.json
    │   │       ├── test_word_object_with_count.json
    │   │       ├── test_wrapped_delete_end_document.json
    │   │       ├── test_wrapped_lines.json
    │   │       ├── test_wrapped_motions.json
    │   │       ├── test_x.json
    │   │       ├── test_yank_line_with_trailing_newline.json
    │   │       ├── test_yank_line_without_trailing_newline.json
    │   │       ├── test_yank_multiline_without_trailing_newline.json
    │   │       ├── test_yank_paragraph_with_paste.json
    │   │       └── test_zero.json
    │   ├── vim_mode_setting/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── vim_mode_setting.rs
    │   ├── watch/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-APACHE
    │   │   └── src/
    │   │       ├── error.rs
    │   │       └── watch.rs
    │   ├── web_search/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── web_search.rs
    │   ├── web_search_providers/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── cloud.rs
    │   │       └── web_search_providers.rs
    │   ├── which_key/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── which_key.rs
    │   │       ├── which_key_modal.rs
    │   │       └── which_key_settings.rs
    │   ├── workspace/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── dock.rs
    │   │       ├── history_manager.rs
    │   │       ├── invalid_item_view.rs
    │   │       ├── item.rs
    │   │       ├── modal_layer.rs
    │   │       ├── notifications.rs
    │   │       ├── pane.rs
    │   │       ├── pane_group.rs
    │   │       ├── path_list.rs
    │   │       ├── persistence/
    │   │       │   └── model.rs
    │   │       ├── persistence.rs
    │   │       ├── searchable.rs
    │   │       ├── security_modal.rs
    │   │       ├── shared_screen.rs
    │   │       ├── status_bar.rs
    │   │       ├── tasks.rs
    │   │       ├── theme_preview.rs
    │   │       ├── toast_layer.rs
    │   │       ├── toolbar.rs
    │   │       ├── utility_pane.rs
    │   │       ├── welcome.rs
    │   │       ├── workspace.rs
    │   │       └── workspace_settings.rs
    │   ├── worktree/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       ├── ignore.rs
    │   │       ├── worktree.rs
    │   │       ├── worktree_settings.rs
    │   │       └── worktree_tests.rs
    │   ├── worktree_benchmarks/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── main.rs
    │   ├── x_ai/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── x_ai.rs
    │   ├── zed/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── RELEASE_CHANNEL
    │   │   ├── build.rs
    │   │   ├── contents/
    │   │   │   ├── dev/
    │   │   │   │   └── embedded.provisionprofile
    │   │   │   ├── nightly/
    │   │   │   │   └── embedded.provisionprofile
    │   │   │   ├── preview/
    │   │   │   │   └── embedded.provisionprofile
    │   │   │   └── stable/
    │   │   │       └── embedded.provisionprofile
    │   │   ├── resources/
    │   │   │   ├── Document.icns
    │   │   │   ├── app-icon-dev.png
    │   │   │   ├── app-icon-dev@2x.png
    │   │   │   ├── app-icon-nightly.png
    │   │   │   ├── app-icon-nightly@2x.png
    │   │   │   ├── app-icon-preview.png
    │   │   │   ├── app-icon-preview@2x.png
    │   │   │   ├── app-icon.png
    │   │   │   ├── app-icon@2x.png
    │   │   │   ├── flatpak/
    │   │   │   │   ├── manifest-template.json
    │   │   │   │   ├── release-info/
    │   │   │   │   │   ├── dev
    │   │   │   │   │   ├── nightly
    │   │   │   │   │   ├── preview
    │   │   │   │   │   └── stable
    │   │   │   │   └── zed.metainfo.xml.in
    │   │   │   ├── info/
    │   │   │   │   ├── DocumentTypes.plist
    │   │   │   │   ├── Permissions.plist
    │   │   │   │   └── SupportedPlatforms.plist
    │   │   │   ├── snap/
    │   │   │   │   └── snapcraft.yaml.in
    │   │   │   ├── windows/
    │   │   │   │   ├── app-icon-dev.ico
    │   │   │   │   ├── app-icon-nightly.ico
    │   │   │   │   ├── app-icon-preview.ico
    │   │   │   │   ├── app-icon.ico
    │   │   │   │   ├── bin/
    │   │   │   │   │   └── x64/
    │   │   │   │   │       └── OpenConsole.exe
    │   │   │   │   ├── messages/
    │   │   │   │   │   ├── Default.zh-cn.isl
    │   │   │   │   │   ├── en.isl
    │   │   │   │   │   └── zh-cn.isl
    │   │   │   │   ├── sign.ps1
    │   │   │   │   ├── zed.iss
    │   │   │   │   └── zed.sh
    │   │   │   ├── zed.desktop.in
    │   │   │   └── zed.entitlements
    │   │   └── src/
    │   │       ├── main.rs
    │   │       ├── reliability.rs
    │   │       ├── visual_test_runner.rs
    │   │       ├── zed/
    │   │       │   ├── app_menus.rs
    │   │       │   ├── edit_prediction_registry.rs
    │   │       │   ├── mac_only_instance.rs
    │   │       │   ├── migrate.rs
    │   │       │   ├── open_listener.rs
    │   │       │   ├── open_url_modal.rs
    │   │       │   ├── quick_action_bar/
    │   │       │   │   ├── preview.rs
    │   │       │   │   └── repl_menu.rs
    │   │       │   ├── quick_action_bar.rs
    │   │       │   ├── visual_tests.rs
    │   │       │   └── windows_only_instance.rs
    │   │       └── zed.rs
    │   ├── zed_actions/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── lib.rs
    │   ├── zed_env_vars/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── zed_env_vars.rs
    │   ├── zeta_prompt/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── zeta_prompt.rs
    │   ├── zlog/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   ├── README.md
    │   │   └── src/
    │   │       ├── env_config.rs
    │   │       ├── filter.rs
    │   │       ├── sink.rs
    │   │       └── zlog.rs
    │   ├── zlog_settings/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-GPL
    │   │   └── src/
    │   │       └── zlog_settings.rs
    │   ├── ztracing/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-AGPL
    │   │   ├── LICENSE-APACHE
    │   │   ├── LICENSE-GPL
    │   │   ├── build.rs
    │   │   └── src/
    │   │       └── lib.rs
    │   └── ztracing_macro/
    │       ├── Cargo.toml
    │       ├── LICENSE-AGPL
    │       ├── LICENSE-APACHE
    │       ├── LICENSE-GPL
    │       └── src/
    │           └── lib.rs
    ├── debug.plist
    ├── default.nix
    ├── docker-compose.sql
    ├── docs/
    │   ├── AGENTS.md
    │   ├── README.md
    │   ├── book.toml
    │   ├── src/
    │   │   ├── SUMMARY.md
    │   │   ├── ai/
    │   │   │   ├── agent-panel.md
    │   │   │   ├── agent-settings.md
    │   │   │   ├── ai-improvement.md
    │   │   │   ├── billing.md
    │   │   │   ├── configuration.md
    │   │   │   ├── edit-prediction.md
    │   │   │   ├── external-agents.md
    │   │   │   ├── inline-assistant.md
    │   │   │   ├── llm-providers.md
    │   │   │   ├── mcp.md
    │   │   │   ├── models.md
    │   │   │   ├── overview.md
    │   │   │   ├── plans-and-usage.md
    │   │   │   ├── privacy-and-security.md
    │   │   │   ├── rules.md
    │   │   │   ├── subscription.md
    │   │   │   ├── text-threads.md
    │   │   │   └── tools.md
    │   │   ├── all-actions.md
    │   │   ├── authentication.md
    │   │   ├── collaboration/
    │   │   │   ├── channels.md
    │   │   │   ├── contacts-and-private-calls.md
    │   │   │   └── overview.md
    │   │   ├── command-line-interface.md
    │   │   ├── command-palette.md
    │   │   ├── completions.md
    │   │   ├── configuring-languages.md
    │   │   ├── configuring-zed.md
    │   │   ├── debugger.md
    │   │   ├── dev-containers.md
    │   │   ├── development/
    │   │   │   ├── debuggers.md
    │   │   │   ├── debugging-crashes.md
    │   │   │   ├── freebsd.md
    │   │   │   ├── glossary.md
    │   │   │   ├── linux.md
    │   │   │   ├── macos.md
    │   │   │   ├── release-notes.md
    │   │   │   └── windows.md
    │   │   ├── development.md
    │   │   ├── diagnostics.md
    │   │   ├── environment.md
    │   │   ├── extensions/
    │   │   │   ├── agent-servers.md
    │   │   │   ├── capabilities.md
    │   │   │   ├── debugger-extensions.md
    │   │   │   ├── developing-extensions.md
    │   │   │   ├── icon-themes.md
    │   │   │   ├── installing-extensions.md
    │   │   │   ├── languages.md
    │   │   │   ├── mcp-extensions.md
    │   │   │   ├── slash-commands.md
    │   │   │   └── themes.md
    │   │   ├── extensions.md
    │   │   ├── getting-started.md
    │   │   ├── git.md
    │   │   ├── globs.md
    │   │   ├── helix.md
    │   │   ├── icon-themes.md
    │   │   ├── installation.md
    │   │   ├── key-bindings.md
    │   │   ├── languages/
    │   │   │   ├── ansible.md
    │   │   │   ├── asciidoc.md
    │   │   │   ├── astro.md
    │   │   │   ├── bash.md
    │   │   │   ├── biome.md
    │   │   │   ├── c.md
    │   │   │   ├── clojure.md
    │   │   │   ├── cpp.md
    │   │   │   ├── csharp.md
    │   │   │   ├── css.md
    │   │   │   ├── dart.md
    │   │   │   ├── deno.md
    │   │   │   ├── diff.md
    │   │   │   ├── docker.md
    │   │   │   ├── elixir.md
    │   │   │   ├── elm.md
    │   │   │   ├── emmet.md
    │   │   │   ├── erlang.md
    │   │   │   ├── fish.md
    │   │   │   ├── gdscript.md
    │   │   │   ├── gleam.md
    │   │   │   ├── glsl.md
    │   │   │   ├── go.md
    │   │   │   ├── groovy.md
    │   │   │   ├── haskell.md
    │   │   │   ├── helm.md
    │   │   │   ├── html.md
    │   │   │   ├── java.md
    │   │   │   ├── javascript.md
    │   │   │   ├── json.md
    │   │   │   ├── jsonnet.md
    │   │   │   ├── julia.md
    │   │   │   ├── kotlin.md
    │   │   │   ├── lua.md
    │   │   │   ├── luau.md
    │   │   │   ├── makefile.md
    │   │   │   ├── markdown.md
    │   │   │   ├── nim.md
    │   │   │   ├── ocaml.md
    │   │   │   ├── opentofu.md
    │   │   │   ├── php.md
    │   │   │   ├── powershell.md
    │   │   │   ├── prisma.md
    │   │   │   ├── proto.md
    │   │   │   ├── purescript.md
    │   │   │   ├── python.md
    │   │   │   ├── r.md
    │   │   │   ├── racket.md
    │   │   │   ├── rego.md
    │   │   │   ├── roc.md
    │   │   │   ├── rst.md
    │   │   │   ├── ruby.md
    │   │   │   ├── rust.md
    │   │   │   ├── scala.md
    │   │   │   ├── scheme.md
    │   │   │   ├── sh.md
    │   │   │   ├── sql.md
    │   │   │   ├── svelte.md
    │   │   │   ├── swift.md
    │   │   │   ├── tailwindcss.md
    │   │   │   ├── terraform.md
    │   │   │   ├── toml.md
    │   │   │   ├── typescript.md
    │   │   │   ├── uiua.md
    │   │   │   ├── vue.md
    │   │   │   ├── xml.md
    │   │   │   ├── yaml.md
    │   │   │   ├── yara.md
    │   │   │   ├── yarn.md
    │   │   │   └── zig.md
    │   │   ├── languages.md
    │   │   ├── linux.md
    │   │   ├── migrate/
    │   │   │   ├── _research-notes.md
    │   │   │   ├── intellij.md
    │   │   │   ├── pycharm.md
    │   │   │   ├── rustrover.md
    │   │   │   ├── vs-code.md
    │   │   │   └── webstorm.md
    │   │   ├── multibuffers.md
    │   │   ├── outline-panel.md
    │   │   ├── performance.md
    │   │   ├── quick-start.md
    │   │   ├── remote-development.md
    │   │   ├── repl.md
    │   │   ├── snippets.md
    │   │   ├── tab-switcher.md
    │   │   ├── tasks.md
    │   │   ├── telemetry.md
    │   │   ├── themes.md
    │   │   ├── toolchains.md
    │   │   ├── troubleshooting.md
    │   │   ├── uninstall.md
    │   │   ├── update.md
    │   │   ├── vim.md
    │   │   ├── visual-customization.md
    │   │   ├── windows.md
    │   │   └── worktree-trust.md
    │   └── theme/
    │       ├── css/
    │       │   ├── chrome.css
    │       │   ├── general.css
    │       │   └── variables.css
    │       ├── favicon.png
    │       ├── fonts/
    │       │   ├── Lora.var.woff2
    │       │   ├── fonts.css
    │       │   └── iAWriterQuattroS-Regular.woff2
    │       ├── highlight.css
    │       ├── index.hbs
    │       ├── page-toc.css
    │       ├── page-toc.js
    │       ├── plugins.css
    │       └── plugins.js
    ├── extensions/
    │   ├── EXTRACTION.md
    │   ├── README.md
    │   ├── glsl/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-APACHE
    │   │   ├── extension.toml
    │   │   ├── languages/
    │   │   │   └── glsl/
    │   │   │       ├── brackets.scm
    │   │   │       ├── config.toml
    │   │   │       └── highlights.scm
    │   │   └── src/
    │   │       └── glsl.rs
    │   ├── html/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-APACHE
    │   │   ├── extension.toml
    │   │   ├── languages/
    │   │   │   └── html/
    │   │   │       ├── brackets.scm
    │   │   │       ├── config.toml
    │   │   │       ├── highlights.scm
    │   │   │       ├── indents.scm
    │   │   │       ├── injections.scm
    │   │   │       ├── outline.scm
    │   │   │       └── overrides.scm
    │   │   └── src/
    │   │       └── html.rs
    │   ├── proto/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-APACHE
    │   │   ├── extension.toml
    │   │   ├── languages/
    │   │   │   └── proto/
    │   │   │       ├── config.toml
    │   │   │       ├── highlights.scm
    │   │   │       ├── indents.scm
    │   │   │       ├── outline.scm
    │   │   │       └── textobjects.scm
    │   │   └── src/
    │   │       ├── language_servers/
    │   │       │   ├── buf.rs
    │   │       │   ├── protobuf_language_server.rs
    │   │       │   ├── protols.rs
    │   │       │   └── util.rs
    │   │       ├── language_servers.rs
    │   │       └── proto.rs
    │   ├── slash-commands-example/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-APACHE
    │   │   ├── README.md
    │   │   ├── extension.toml
    │   │   └── src/
    │   │       └── slash_commands_example.rs
    │   ├── test-extension/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-APACHE
    │   │   ├── README.md
    │   │   ├── extension.toml
    │   │   ├── languages/
    │   │   │   └── gleam/
    │   │   │       ├── config.toml
    │   │   │       ├── highlights.scm
    │   │   │       ├── indents.scm
    │   │   │       └── outline.scm
    │   │   └── src/
    │   │       └── test_extension.rs
    │   └── workflows/
    │       ├── run_tests.yml
    │       └── shared/
    │           ├── bump_version.yml
    │           └── release_version.yml
    ├── flake.lock
    ├── flake.nix
    ├── legal/
    │   ├── privacy-policy.md
    │   ├── subprocessors.md
    │   ├── terms.md
    │   └── third-party-terms.md
    ├── livekit.yaml
    ├── lychee.toml
    ├── nix/
    │   ├── build.nix
    │   └── shell.nix
    ├── plans/
    │   ├── agent-panel-image-visual-test.md
    │   └── visual-test-improvements.md
    ├── renovate.json
    ├── rust-toolchain.toml
    ├── script/
    │   ├── analyze_highlights.py
    │   ├── bootstrap
    │   ├── bootstrap.ps1
    │   ├── build-docker
    │   ├── bump-extension-cli
    │   ├── bump-gpui-version
    │   ├── bump-nightly
    │   ├── bump-zed-minor-versions
    │   ├── bump-zed-patch-version
    │   ├── bundle-freebsd
    │   ├── bundle-linux
    │   ├── bundle-mac
    │   ├── bundle-windows.ps1
    │   ├── check-keymaps
    │   ├── check-licenses
    │   ├── check-links
    │   ├── check-todos
    │   ├── cherry-pick
    │   ├── clear-target-dir-if-larger-than
    │   ├── clear-target-dir-if-larger-than.ps1
    │   ├── clippy
    │   ├── clippy.ps1
    │   ├── collab-flamegraph
    │   ├── crate-dep-graph
    │   ├── create-draft-release
    │   ├── danger/
    │   │   ├── dangerfile.ts
    │   │   ├── package.json
    │   │   └── pnpm-lock.yaml
    │   ├── debug-cli
    │   ├── deploy-collab
    │   ├── determine-release-channel
    │   ├── determine-release-channel.ps1
    │   ├── digital-ocean-db.sh
    │   ├── download-wasi-sdk
    │   ├── draft-release-notes
    │   ├── drop-test-dbs
    │   ├── exit-ci-if-dev-drive-is-full.ps1
    │   ├── flatpak/
    │   │   ├── bundle-flatpak
    │   │   ├── convert-release-notes.py
    │   │   └── deps
    │   ├── freebsd
    │   ├── generate-action-metadata
    │   ├── generate-licenses
    │   ├── generate-licenses-csv
    │   ├── generate-licenses.ps1
    │   ├── generate-terms-rtf
    │   ├── get-crate-version
    │   ├── get-crate-version.ps1
    │   ├── get-pull-requests-since
    │   ├── get-release-notes-since
    │   ├── get-released-version
    │   ├── github-clean-issue-types.py
    │   ├── github-label-issues-to-triage.py
    │   ├── github-pr-status
    │   ├── histogram
    │   ├── import-themes
    │   ├── install-cmake
    │   ├── install-linux
    │   ├── install-mold
    │   ├── install-rustup.ps1
    │   ├── install-wild
    │   ├── install.sh
    │   ├── kube-shell
    │   ├── language-extension-version
    │   ├── lib/
    │   │   ├── blob-store.ps1
    │   │   ├── blob-store.sh
    │   │   ├── bump-version.sh
    │   │   ├── deploy-helpers.sh
    │   │   ├── squawk.toml
    │   │   └── workspace.ps1
    │   ├── licenses/
    │   │   ├── template.csv.hbs
    │   │   ├── template.md.hbs
    │   │   └── zed-licenses.toml
    │   ├── linux
    │   ├── metal-debug
    │   ├── mitm-proxy.sh
    │   ├── new-crate
    │   ├── prettier
    │   ├── prompts
    │   ├── randomized-test-ci
    │   ├── randomized-test-minimize
    │   ├── remote-server
    │   ├── reset_db
    │   ├── run-local-minio
    │   ├── run-unit-evals
    │   ├── seed-db
    │   ├── setup-dev-driver.ps1
    │   ├── shellcheck-scripts
    │   ├── snap-build
    │   ├── snap-try
    │   ├── squawk
    │   ├── storybook
    │   ├── terms/
    │   │   ├── terms.json
    │   │   └── terms.rtf
    │   ├── triage_watcher.jl
    │   ├── trigger-release
    │   ├── uninstall.sh
    │   ├── update-json-schemas
    │   ├── update_top_ranking_issues/
    │   │   ├── main.py
    │   │   ├── pyproject.toml
    │   │   ├── pyrightconfig.json
    │   │   └── uv.lock
    │   ├── upload-extension-cli
    │   ├── upload-nightly
    │   ├── upload-nightly.ps1
    │   ├── verify-macos-document-icon
    │   ├── what-is-deployed
    │   └── zed-local
    ├── shell.nix
    ├── tooling/
    │   ├── perf/
    │   │   ├── Cargo.toml
    │   │   ├── LICENSE-APACHE
    │   │   └── src/
    │   │       ├── implementation.rs
    │   │       ├── lib.rs
    │   │       └── main.rs
    │   └── xtask/
    │       ├── Cargo.toml
    │       ├── LICENSE-GPL
    │       └── src/
    │           ├── main.rs
    │           ├── tasks/
    │           │   ├── clippy.rs
    │           │   ├── licenses.rs
    │           │   ├── package_conformity.rs
    │           │   ├── publish_gpui.rs
    │           │   ├── workflows/
    │           │   │   ├── after_release.rs
    │           │   │   ├── autofix_pr.rs
    │           │   │   ├── bump_patch_version.rs
    │           │   │   ├── cherry_pick.rs
    │           │   │   ├── compare_perf.rs
    │           │   │   ├── danger.rs
    │           │   │   ├── extension_bump.rs
    │           │   │   ├── extension_release.rs
    │           │   │   ├── extension_tests.rs
    │           │   │   ├── extension_workflow_rollout.rs
    │           │   │   ├── extensions/
    │           │   │   │   ├── bump_version.rs
    │           │   │   │   ├── release_version.rs
    │           │   │   │   └── run_tests.rs
    │           │   │   ├── extensions.rs
    │           │   │   ├── nix_build.rs
    │           │   │   ├── release.rs
    │           │   │   ├── release_nightly.rs
    │           │   │   ├── run_agent_evals.rs
    │           │   │   ├── run_bundling.rs
    │           │   │   ├── run_tests.rs
    │           │   │   ├── runners.rs
    │           │   │   ├── steps.rs
    │           │   │   └── vars.rs
    │           │   └── workflows.rs
    │           ├── tasks.rs
    │           └── workspace.rs
    └── typos.toml
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



