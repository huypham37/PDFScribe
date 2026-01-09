import Foundation
import Combine

@MainActor
class FileService: ObservableObject {
    @Published var currentNoteURL: URL?
    @Published var autoSaveEnabled: Bool = true
    
    private var saveDebouncer: AnyCancellable?
    
    func associateNoteWithPDF(pdfURL: URL) -> URL {
        let noteURL = pdfURL.deletingPathExtension().appendingPathExtension("md")
        currentNoteURL = noteURL
        return noteURL
    }
    
    func loadNote(from url: URL) -> String? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        
        return try? String(contentsOf: url, encoding: .utf8)
    }
    
    func saveNote(content: String, to url: URL) throws {
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
    
    func scheduleAutoSave(content: String, debounceInterval: TimeInterval = 2.0) {
        guard autoSaveEnabled, let url = currentNoteURL else { return }
        
        saveDebouncer?.cancel()
        saveDebouncer = Just(content)
        .delay(for: .seconds(debounceInterval), scheduler: RunLoop.main)
        .sink { [weak self] content in
            try? self?.saveNote(content: content, to: url)
        }
    }
    
    // MARK: - Centralized Session History
    
    private var historyURL: URL {
        let folder = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/share/pdfscribe", isDirectory: true)
        
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        
        return folder.appendingPathComponent("history.json")
    }
    
    func loadChatHistory() -> ChatHistory {
        guard FileManager.default.fileExists(atPath: historyURL.path) else {
            return ChatHistory(sessions: [])
        }
        
        do {
            let data = try Data(contentsOf: historyURL)
            return try JSONDecoder().decode(ChatHistory.self, from: data)
        } catch {
            print("Failed to load chat history: \(error)")
            return ChatHistory(sessions: [])
        }
    }
    
    func saveChatHistory(_ history: ChatHistory) {
        print("💾 FileService: Saving history with \(history.sessions.count) session(s) to \(historyURL.path)")
        do {
            let data = try JSONEncoder().encode(history)
            try data.write(to: historyURL)
            print("✅ FileService: History saved successfully")
        } catch {
            print("❌ FileService: Failed to save chat history: \(error)")
        }
    }
    
    func getMostRecentSessionId(for projectPath: String) -> String? {
        let history = loadChatHistory()
        return history.sessions
            .filter { $0.projectPath == projectPath }
            .sorted { $0.lastActive > $1.lastActive }
            .first?
            .id
    }
    
    func addOrUpdateSession(_ session: ChatSession) {
        print("📝 FileService: Adding/updating session \(session.id) with title '\(session.title)'")
        var history = loadChatHistory()
        if let index = history.sessions.firstIndex(where: { $0.id == session.id }) {
            print("   Updating existing session at index \(index)")
            history.sessions[index] = session
        } else {
            print("   Adding new session")
            history.sessions.append(session)
        }
        saveChatHistory(history)
    }
    
    func addMessageToSession(sessionId: String, message: StoredMessage) {
        var history = loadChatHistory()
        guard let index = history.sessions.firstIndex(where: { $0.id == sessionId }) else {
            print("⚠️ FileService: Session \(sessionId) not found when adding message")
            return
        }
        
        history.sessions[index].messages.append(message)
        history.sessions[index].lastActive = Date()
        saveChatHistory(history)
    }
    
    func getSessionMessages(sessionId: String) -> [StoredMessage] {
        let history = loadChatHistory()
        return history.sessions.first(where: { $0.id == sessionId })?.messages ?? []
    }
    
    func getMostRecentSession(for projectPath: String) -> ChatSession? {
        let history = loadChatHistory()
        return history.sessions
            .filter { $0.projectPath == projectPath }
            .sorted { $0.lastActive > $1.lastActive }
            .first
    }
}

