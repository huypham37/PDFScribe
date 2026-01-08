import SwiftUI

struct ProjectSidebarView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var pdfViewModel: PDFViewModel
    @EnvironmentObject var editorViewModel: EditorViewModel
    @EnvironmentObject var aiViewModel: AIViewModel
    @EnvironmentObject var fileService: FileService
    
    var body: some View {
        Group {
            if appViewModel.sidebarMode == .files {
                fileListView
            } else {
                AIPanel(viewModel: aiViewModel)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: { appViewModel.sidebarMode = .files }) {
                    Label("Files", systemImage: "list.bullet")
                }
                .help("Files")
                
                Button(action: { appViewModel.sidebarMode = .ai }) {
                    Label("AI", systemImage: "sparkles")
                }
                .help("AI Assistant")
            }
        }
    }
    
    private var fileListView: some View {
        List(appViewModel.fileStructure, children: \.children) { item in
            FileRowView(item: item, onSelect: openFile)
        }
        .listStyle(.sidebar)
    }
    
    private func openFile(_ item: FileItem) {
        guard item.url.pathExtension.lowercased() == "pdf" else { return }
        
        appViewModel.selectedFile = item
        do {
            try pdfViewModel.loadPDF(url: item.url)
            
            let noteURL = fileService.associateNoteWithPDF(pdfURL: item.url)
            if let content = fileService.loadNote(from: noteURL) {
                editorViewModel.loadContent(content)
            } else {
                editorViewModel.loadContent("")
            }
            
            appViewModel.documentTitle = item.name
        } catch {
            print("Error opening file: \(error)")
        }
    }
}

// MARK: - File Row View
private struct FileRowView: View {
    let item: FileItem
    let onSelect: (FileItem) -> Void
    
    var body: some View {
        Label {
            Text(item.name)
                .font(.system(size: 13))
        } icon: {
            Image(systemName: item.iconName)
                .foregroundColor(item.isDirectory ? Color("SlateIndigo") : .secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !item.isDirectory {
                onSelect(item)
            }
        }
    }
}
