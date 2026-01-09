import SwiftUI
import AppKit

@main
struct PDFScribeApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var pdfViewModel = PDFViewModel()
    @StateObject private var editorViewModel = EditorViewModel()
    @StateObject private var fileService = FileService()
    @StateObject private var aiService = AIService()
    @StateObject private var aiViewModel: AIViewModel
    
    init() {
        let appVM = AppViewModel()
        let pdfVM = PDFViewModel()
        let editorVM = EditorViewModel()
        let fileSvc = FileService()
        let service = AIService()
        let aiVM = AIViewModel(aiService: service)
        
        _appViewModel = StateObject(wrappedValue: appVM)
        _pdfViewModel = StateObject(wrappedValue: pdfVM)
        _editorViewModel = StateObject(wrappedValue: editorVM)
        _fileService = StateObject(wrappedValue: fileSvc)
        _aiService = StateObject(wrappedValue: service)
        _aiViewModel = StateObject(wrappedValue: aiVM)
        
        // Set cross-references after initialization
        Task { @MainActor in
            service.appViewModel = appVM
            service.fileService = fileSvc
            aiVM.editorViewModel = editorVM
            aiVM.pdfViewModel = pdfVM
            aiVM.fileService = fileSvc
        }
        
        // Bring app to foreground
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup {
            MainSplitView()
                .environmentObject(appViewModel)
                .environmentObject(pdfViewModel)
                .environmentObject(editorViewModel)
                .environmentObject(aiViewModel)
                .environmentObject(fileService)
        }
        .windowStyle(.titleBar)
    }
}
