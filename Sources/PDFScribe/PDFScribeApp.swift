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
        let service = AIService()
        _aiService = StateObject(wrappedValue: service)
        _aiViewModel = StateObject(wrappedValue: AIViewModel(aiService: service))
        
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
