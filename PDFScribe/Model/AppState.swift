import Foundation

/// Represents the application state to be persisted across launches
struct AppState: Codable {
    var projectDirectoryPath: String?
    var pdfFilePath: String?
    var noteFilePath: String?
    var lastSidebarMode: String? // "files" or "ai"
    
    /// Convert to URL objects
    var projectDirectoryURL: URL? {
        guard let path = projectDirectoryPath else { return nil }
        return URL(fileURLWithPath: path)
    }
    
    var pdfFileURL: URL? {
        guard let path = pdfFilePath else { return nil }
        return URL(fileURLWithPath: path)
    }
    
    var noteFileURL: URL? {
        guard let path = noteFilePath else { return nil }
        return URL(fileURLWithPath: path)
    }
    
    /// Initialize with URL objects
    init(projectDirectory: URL? = nil, pdfFile: URL? = nil, noteFile: URL? = nil, sidebarMode: SidebarMode = .files) {
        self.projectDirectoryPath = projectDirectory?.path
        self.pdfFilePath = pdfFile?.path
        self.noteFilePath = noteFile?.path
        self.lastSidebarMode = sidebarMode == .ai ? "ai" : "files"
    }
    
    /// Empty state
    static var empty: AppState {
        AppState()
    }
}
