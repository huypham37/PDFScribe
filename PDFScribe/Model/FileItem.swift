import Foundation

struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let isDirectory: Bool
    var children: [FileItem]?
    
    var name: String {
        url.lastPathComponent
    }
    
    var iconName: String {
        if isDirectory {
            return "folder"
        } else {
            return url.pathExtension.lowercased() == "pdf" ? "doc.text" : "doc"
        }
    }
    
    // Helper to sort: Folders first, then files alphabetically
    static func < (lhs: FileItem, rhs: FileItem) -> Bool {
        if lhs.isDirectory && !rhs.isDirectory {
            return true
        } else if !lhs.isDirectory && rhs.isDirectory {
            return false
        } else {
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }
}
