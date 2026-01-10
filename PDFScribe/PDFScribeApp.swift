import SwiftUI
import AppKit

@main
struct PDFScribeApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var fileService = FileService()
    @StateObject private var aiService = AIService()
    @StateObject private var aiViewModel: AIViewModel
    
    init() {
        let appVM = AppViewModel()
        let fileSvc = FileService()
        let service = AIService()
        let aiVM = AIViewModel(aiService: service)
        
        _appViewModel = StateObject(wrappedValue: appVM)
        _fileService = StateObject(wrappedValue: fileSvc)
        _aiService = StateObject(wrappedValue: service)
        _aiViewModel = StateObject(wrappedValue: aiVM)
        
        // Set cross-references after initialization
        Task { @MainActor in
            service.appViewModel = appVM
            service.fileService = fileSvc
            aiVM.appViewModel = appVM
            aiVM.fileService = fileSvc
            
            // Load saved app state and restore last session
            let savedState = fileSvc.loadAppState()
            
            // Restore project directory
            if let projectURL = savedState.projectDirectoryURL,
               FileManager.default.fileExists(atPath: projectURL.path) {
                appVM.loadProject(url: projectURL)
            }
            
            // Restore sidebar mode (default to AI mode)
            if let mode = savedState.lastSidebarMode {
                appVM.sidebarMode = mode == "ai" ? .ai : .files
            } else {
                appVM.sidebarMode = .ai
            }
        }
        
        // Bring app to foreground
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup {
            MainSplitView()
                .environmentObject(appViewModel)
                .environmentObject(aiViewModel)
                .environmentObject(fileService)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(after: .newItem) {
                SettingsLink {
                    Text("Settings...")
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        
        Settings {
            AISettingsView(aiService: aiService)
        }
    }
}
