# PDFScribe

A native macOS application for reading PDFs with integrated note-taking and AI assistance.

## Features

- **PDF Viewer**: Native PDFKit integration for smooth PDF rendering
- **Markdown Editor**: Real-time note-taking with auto-quote functionality
- **Auto-Quote**: Highlight text in PDF and it automatically appears in your notes with citation
- **AI Sidebar**: Chat interface for quick AI assistance (integration ready)

## Requirements

- macOS 12.0 or later
- Swift 6.0+

## Development

```bash
# Build the project
make build

# Run in development mode
make run

# Create production app bundle
make release

# Clean build artifacts
make clean
```

## Usage

1. Run `make run` or open the built app
2. Click "Open PDF" to load a PDF file
3. Highlight text in the PDF - it will automatically be quoted in the editor
4. Take notes in the middle panel
5. Use the AI sidebar for assistance (API integration required)

## Architecture

The app follows MVVM architecture:
- **Models**: Data structures
- **ViewModels**: Business logic and state management
- **Views**: SwiftUI views and AppKit wrappers

## Project Structure

```
Sources/PDFScribe/
├── PDFScribeApp.swift       # App entry point
├── Model/                   # Data models
├── ViewModel/               # View models
│   ├── AppViewModel.swift
│   ├── PDFViewModel.swift
│   └── EditorViewModel.swift
├── View/
│   ├── MainSplitView.swift  # Main layout
│   ├── PDF/                 # PDF viewer components
│   ├── Editor/              # Editor components
│   └── Chat/                # AI chat components
└── Services/                # External services (API, etc.)
```

## License

MIT
