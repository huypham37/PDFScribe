import Foundation

struct StoredMessage: Codable, Identifiable {
    let id: String
    let role: String // "user" or "assistant"
    let content: String
    let timestamp: Date
    
    init(id: String = UUID().uuidString, role: String, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

struct ChatSession: Codable, Identifiable {
    let id: String // Our own UUID, not provider-specific
    let projectPath: String
    var title: String
    let createdAt: Date
    var lastActive: Date
    var messages: [StoredMessage]
    var provider: String // "openai", "anthropic", "opencode"
    
    // Identifiable conformance
    var uid: String { id }
    
    init(id: String = UUID().uuidString, projectPath: String, title: String, createdAt: Date = Date(), lastActive: Date = Date(), messages: [StoredMessage] = [], provider: String) {
        self.id = id
        self.projectPath = projectPath
        self.title = title
        self.createdAt = createdAt
        self.lastActive = lastActive
        self.messages = messages
        self.provider = provider
    }
}

struct ChatHistory: Codable {
    var sessions: [ChatSession]
}
