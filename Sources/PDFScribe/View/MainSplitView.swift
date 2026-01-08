import SwiftUI
import PDFKit

struct MainSplitView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var pdfViewModel: PDFViewModel
    @EnvironmentObject var editorViewModel: EditorViewModel
    @EnvironmentObject var aiViewModel: AIViewModel
    @EnvironmentObject var fileService: FileService
    
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var pdfViewInstance: PDFView?

    var body: some View {
        HSplitView {
            // PDF Area
            VStack(spacing: 0) {
                if pdfViewModel.document != nil {
                    PDFControlBar(viewModel: pdfViewModel, pdfView: pdfViewInstance)
                    PDFPanel(viewModel: pdfViewModel, pdfViewInstance: $pdfViewInstance)
                } else {
                    VStack {
                        Text("PDF Viewer")
                            .font(.title)
                            .foregroundColor(.secondary)
                        Button("Open PDF") {
                            openPDF()
                        }
                    }
                }
            }
            .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.controlBackgroundColor))

            // Editor Area
            EditorPanel(viewModel: editorViewModel)
                .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.textBackgroundColor))
            
            // AI Sidebar Area
            AIPanel(viewModel: aiViewModel)
                .frame(width: 300)
                .frame(maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 1000, minHeight: 600)
        .onReceive(pdfViewModel.$pendingQuote) { selection in
            if let selection = selection, !selection.text.isEmpty {
                editorViewModel.insertQuote(text: selection.text, pageNumber: selection.pageNumber)
                pdfViewModel.pendingQuote = nil
            }
        }
        .onAppear {
            setupAutoSave()
        }
        .alert("Error Opening PDF", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func openPDF() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        
        guard panel.runModal() == .OK, let url = panel.url else { return }
        
        // Validate file
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
                let maxSize: UInt64 = 100 * 1024 * 1024 // 100MB
                guard fileSize < maxSize else {
                    showError("File is too large. Maximum size is 100MB")
                    return
                }
            }
        } catch {
            showError("Could not read file attributes: \(error.localizedDescription)")
            return
        }
        
        // Load PDF
        do {
            try pdfViewModel.loadPDF(url: url)
            appViewModel.documentTitle = url.deletingPathExtension().lastPathComponent
            
            // Associate and load note file
            let noteURL = fileService.associateNoteWithPDF(pdfURL: url)
            if let noteContent = fileService.loadNote(from: noteURL) {
                editorViewModel.loadContent(noteContent)
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
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}
