import Combine
import SwiftUI

enum SidebarMode {
    case files
    case ai
}

@MainActor
class AppViewModel: ObservableObject {
    @Published var documentTitle: String = "Untitled"
    @Published var projectRootURL: URL?
    @Published var fileStructure: [FileItem] = []
    @Published var selectedFile: FileItem?
    @Published var sidebarMode: SidebarMode = .files
    @Published var recentSessions: [ChatSession] = []
    @Published var currentSession: ChatSession?
    
    private var allFiles: [FileItem] = []
    
    // Load a project directory
    func loadProject(url: URL) {
        // Ensure we have access to the directory (security scoped bookmarks might be needed for real app persistence, 
        // but for now we assume standard access or user selection grants it)
        projectRootURL = url
        documentTitle = url.lastPathComponent
        refreshProject()
    }
    
    // Refresh the file tree
    func refreshProject() {
        guard let root = projectRootURL else { return }
        fileStructure = scanDirectory(at: root)
        allFiles = flattenFileStructure(fileStructure)
    }
    
    // Get all files as a flat list
    func getAllFiles() -> [FileItem] {
        return allFiles
    }
    
    private func flattenFileStructure(_ items: [FileItem]) -> [FileItem] {
        var result: [FileItem] = []
        
        for item in items {
            result.append(item)
            if let children = item.children {
                result.append(contentsOf: flattenFileStructure(children))
            }
        }
        
        // Sort: folders first, then files alphabetically
        return result.sorted { lhs, rhs in
            if lhs.isDirectory && !rhs.isDirectory { return true }
            if !lhs.isDirectory && rhs.isDirectory { return false }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }
    
    // Recursive scan
    private func scanDirectory(at url: URL) -> [FileItem] {
        var items: [FileItem] = []
        
        do {
            let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .nameKey]
            let contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: resourceKeys,
                options: [.skipsHiddenFiles]
            )
            
            for fileURL in contents {
                // Skip the sidecar .md files from the tree to keep it clean? 
                // Or show them? Requirements say "link the note to the document". 
                // Usually better to hide the sidecar file if it's strictly 1:1 managed by the app,
                // but for a generic project tree, maybe show everything.
                // For now, let's filter out the .md files that are associated with PDFs to avoid clutter,
                // OR just show everything. Let's show everything for transparency first, can filter later.
                // Actually, if we want to "reopen the pdf file wont loose the persistent", we probably want to click the PDF
                // and have the app handle loading the MD.
                
                let resources = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                let isDirectory = resources.isDirectory ?? false
                
                if isDirectory {
                    let children = scanDirectory(at: fileURL)
                    items.append(FileItem(url: fileURL, isDirectory: true, children: children))
                } else {
                    items.append(FileItem(url: fileURL, isDirectory: false, children: nil))
                }
            }
        } catch {
            print("Error scanning directory: \(error)")
        }
        
        // Sort: Folders first, then files
        return items.sorted { lhs, rhs in
            if lhs.isDirectory && !rhs.isDirectory { return true }
            if !lhs.isDirectory && rhs.isDirectory { return false }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }
    
    func createFolder(name: String, at parentURL: URL?) {
        let targetDir = parentURL ?? projectRootURL
        guard let dir = targetDir else { return }
        
        let newFolderURL = dir.appendingPathComponent(name)
        do {
            try FileManager.default.createDirectory(at: newFolderURL, withIntermediateDirectories: false)
            refreshProject()
        } catch {
            print("Failed to create folder: \(error)")
        }
    }
    
    func createNewSession() {
        let session = ChatSession(
            id: UUID().uuidString,
            projectPath: projectRootURL?.path ?? "",
            title: "New Thread",
            createdAt: Date(),
            lastActive: Date(),
            messages: [],
            provider: "opencode"
        )
        currentSession = session
        recentSessions.insert(session, at: 0)
    }
    
    func selectSession(_ session: ChatSession) {
        currentSession = session
    }
}
