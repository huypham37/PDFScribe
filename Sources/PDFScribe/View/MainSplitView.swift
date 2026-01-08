import SwiftUI

struct MainSplitView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var pdfViewModel = PDFViewModel()
    @StateObject private var editorViewModel = EditorViewModel()

    var body: some View {
        HSplitView {
            // PDF Area
            VStack {
                if pdfViewModel.document != nil {
                    PDFPanel(viewModel: pdfViewModel)
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
            AIPanel()
                .frame(width: 300)
                .frame(maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 1000, minHeight: 600)
        .onReceive(pdfViewModel.$selectedText) { text in
            if let text = text, !text.isEmpty {
                editorViewModel.insertQuote(text: text, pageNumber: 1)
                pdfViewModel.selectedText = nil
            }
        }
    }
    
    private func openPDF() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            pdfViewModel.loadPDF(url: url)
            appViewModel.documentTitle = url.deletingPathExtension().lastPathComponent
        }
    }
}
