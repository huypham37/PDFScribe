import Foundation
import SwiftUI

struct ToolCall: Identifiable {
    let id: String
    var name: String           // Raw tool name (e.g., "read", "bash", "glob")
    var query: String          // What the tool is doing (file path, command, etc.)
    var status: Status
    var toolType: ToolType
    var startTime: Date
    var endTime: Date?
    
    enum Status {
        case running      // Tool is executing
        case completed
        case failed
        case cancelled
    }
    
    enum ToolType {
        case search      // glob, grep
        case code        // bash
        case file        // read, write, edit
        case web         // webfetch
        case delegate    // task (sub-agent)
        case unknown
    }
    
    init(id: String, name: String, query: String, status: Status = .running, toolType: ToolType = .unknown) {
        self.id = id
        self.name = name
        self.query = query
        self.status = status
        self.toolType = toolType
        self.startTime = Date()
        self.endTime = nil
    }
    

    
    var elapsedTime: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
    
    var elapsedTimeString: String {
        String(format: "%.1fs", elapsedTime)
    }
}

// MARK: - Tool Metadata
extension ToolCall {
    struct ToolMeta {
        let displayName: String
        let iconName: String    // SF Symbol name
        let color: Color
    }
    
    static let toolMetaMap: [String: ToolMeta] = [
        // File operations
        "read": ToolMeta(displayName: "Read File", iconName: "doc.text", color: .blue),
        "write": ToolMeta(displayName: "Write File", iconName: "doc.badge.plus", color: .green),
        "edit": ToolMeta(displayName: "Edit File", iconName: "pencil", color: .orange),
        
        // Code execution
        "bash": ToolMeta(displayName: "Run Command", iconName: "terminal", color: .purple),
        
        // Search
        "glob": ToolMeta(displayName: "Find Files", iconName: "magnifyingglass", color: .blue),
        "grep": ToolMeta(displayName: "Search Code", iconName: "text.magnifyingglass", color: .blue),
        
        // Web
        "webfetch": ToolMeta(displayName: "Web Fetch", iconName: "globe", color: .orange),
        "web-search": ToolMeta(displayName: "Web Search", iconName: "safari", color: .orange),
        
        // Delegation
        "task": ToolMeta(displayName: "Sub-Agent", iconName: "person.2.circle", color: .indigo),
        
        // Discard
        "discard": ToolMeta(displayName: "Discard", iconName: "trash", color: .red),
        "extract": ToolMeta(displayName: "Extract", iconName: "doc.text.magnifyingglass", color: .purple),
    ]
    
    var metadata: ToolMeta {
        ToolCall.toolMetaMap[name] ?? ToolMeta(displayName: name.capitalized, iconName: "gearshape", color: .gray)
    }
    
    static func inferToolType(from name: String) -> ToolType {
        switch name {
        case "glob", "grep": return .search
        case "bash": return .code
        case "read", "write", "edit": return .file
        case "webfetch", "web-search": return .web
        case "task": return .delegate
        default: return .unknown
        }
    }
}
