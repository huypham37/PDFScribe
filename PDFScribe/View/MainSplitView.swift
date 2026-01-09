import SwiftUI
import PDFKit
import UniformTypeIdentifiers

// MARK: - Backward Compatibility Extension for Liquid Glass
extension View {
    @ViewBuilder
    func glassBackground() -> some View {
        if #available(macOS 26.0, *) {
            // When macOS 26 is available, use Liquid Glass
            // self.glassEffect()
            self.background(.ultraThinMaterial) // Placeholder until macOS 26
        } else {
            self.background(.ultraThinMaterial)
        }
    }
}

struct MainSplitView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var pdfViewModel: PDFViewModel
    @EnvironmentObject var editorViewModel: EditorViewModel
    @EnvironmentObject var aiViewModel: AIViewModel
    @EnvironmentObject var fileService: FileService
    
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var pdfViewInstance: PDFView?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar - Project Browser (will auto-get Liquid Glass on macOS 26)
            // Expand width when in AI mode for better chat experience
            ProjectSidebarView()
                .navigationSplitViewColumnWidth(
                    min: appViewModel.sidebarMode == .ai ? 400 : 200,
                    ideal: appViewModel.sidebarMode == .ai ? 500 : 240,
                    max: appViewModel.sidebarMode == .ai ? 600 : 300
                )
        } detail: {
            // Content - Editor + PDF Viewer (swapped positions)
            HStack(spacing: 0) {
                // Editor Area - PaperWhite background (now on left/center)
                EditorPanel(viewModel: editorViewModel)
                    .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color("PaperWhite"))

                // PDF Area (now on right)
                VStack(spacing: 0) {
                    if pdfViewModel.document != nil {
                        PDFControlBar(viewModel: pdfViewModel, pdfView: pdfViewInstance)
                        PDFPanel(viewModel: pdfViewModel, pdfViewInstance: $pdfViewInstance)
                    } else {
                        emptyStateView
                    }
                }
                .frame(minWidth: 350, maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationSplitViewStyle(.prominentDetail)
        .frame(minWidth: 1000, minHeight: 600)
        .toolbar {
            // File actions
            ToolbarItem(placement: .navigation) {
                Button(action: openProjectFolder) {
                    Label("Open Project", systemImage: "folder")
                }
            }
            ToolbarItem(placement: .navigation) {
                Button(action: openPDF) {
                    Label("Open PDF", systemImage: "doc.text")
                }
            }
            ToolbarItem(placement: .navigation) {
                Button(action: saveNote) {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .keyboardShortcut("s", modifiers: .command)
                .help("Save Note (⌘S)")
            }
        }
        .onReceive(pdfViewModel.$pendingQuote) { selection in
            if let selection = selection, !selection.text.isEmpty {
                editorViewModel.insertQuote(text: selection.text, pageNumber: selection.pageNumber)
                pdfViewModel.pendingQuote = nil
            }
        }
        .onAppear {
            setupAutoSave()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Text("PDFScribe")
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .foregroundColor(.primary)
            
            Text("Open a project folder or PDF to begin")
                .font(.system(size: 15, design: .default))
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                Button(action: openProjectFolder) {
                    Label("Open Project", systemImage: "folder")
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("SlateIndigo"))
                
                Button(action: openPDF) {
                    Label("Open PDF", systemImage: "doc.text")
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    private func openProjectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Open Project"
        
        guard panel.runModal() == .OK, let url = panel.url else { return }
        
        appViewModel.loadProject(url: url)
    }
    
    private func openPDF() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        
        guard panel.runModal() == .OK, let url = panel.url else { return }
        
        loadPDF(url: url)
    }
    
    private func loadPDF(url: URL) {
        guard url.isFileURL else {
            showError("Invalid file URL")
            return
        }
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            showError("File does not exist")
            return
        }
        
        // Check file size (limit to 100MB)
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? UInt64 {
                let maxSize: UInt64 = 100 * 1024 * 1024
                guard fileSize < maxSize else {
                    showError("File is too large. Maximum size is 100MB")
                    return
                }
            }
        } catch {
            showError("Could not read file attributes: \(error.localizedDescription)")
            return
        }
        
        do {
            try pdfViewModel.loadPDF(url: url)
            appViewModel.documentTitle = url.deletingPathExtension().lastPathComponent
            
            let noteURL = fileService.associateNoteWithPDF(pdfURL: url)
            if let noteContent = fileService.loadNote(from: noteURL) {
                editorViewModel.loadContent(noteContent)
            } else {
                editorViewModel.loadContent("")
            }
        } catch {
            showError("Could not load PDF: \(error.localizedDescription)")
        }
    }
    
    private func setupAutoSave() {
        editorViewModel.contentDidChange = { [weak fileService] content in
            fileService?.scheduleAutoSave(content: content)
        }
    }
    
    private func saveNote() {
        guard let url = fileService.currentNoteURL else { return }
        do {
            try fileService.saveNote(content: editorViewModel.content, to: url)
        } catch {
            showError("Could not save note: \(error.localizedDescription)")
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}
