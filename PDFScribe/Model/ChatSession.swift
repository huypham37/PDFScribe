import Foundation

struct ChatSession: Codable, Identifiable {
    let id: String // The OpenCode sessionId
    let projectPath: String
    var title: String
    let createdAt: Date
    var lastActive: Date
    
    // Identifiable conformance
    var uid: String { id }
}

struct ChatHistory: Codable {
    var sessions: [ChatSession]
}
