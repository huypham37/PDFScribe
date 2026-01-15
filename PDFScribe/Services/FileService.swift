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
            return ChatHistory(sessions: [])
        }
    }
    
    func saveChatHistory(_ history: ChatHistory) {
        do {
            let data = try JSONEncoder().encode(history)
            try data.write(to: historyURL)
        } catch {
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
        var history = loadChatHistory()
        if let index = history.sessions.firstIndex(where: { $0.id == session.id }) {
            history.sessions[index] = session
        } else {
            history.sessions.append(session)
        }
        saveChatHistory(history)
    }
    
    func addMessageToSession(sessionId: String, message: StoredMessage) {
        var history = loadChatHistory()
        guard let index = history.sessions.firstIndex(where: { $0.id == sessionId }) else {
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
    
    func getRecentSessions(for projectPath: String, limit: Int = 5) -> [ChatSession] {
        let history = loadChatHistory()
        return history.sessions
            .filter { $0.projectPath == projectPath }
            .sorted { $0.lastActive > $1.lastActive }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - App State Persistence
    
    private var appStateURL: URL {
        let folder = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/share/pdfscribe", isDirectory: true)
        
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        
        return folder.appendingPathComponent("appstate.json")
    }
    
    func loadAppState() -> AppState {
        guard FileManager.default.fileExists(atPath: appStateURL.path) else {
            return .empty
        }
        
        do {
            let data = try Data(contentsOf: appStateURL)
            let state = try JSONDecoder().decode(AppState.self, from: data)
            return state
        } catch {
            return .empty
        }
    }
    
    func saveAppState(_ state: AppState) {
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: appStateURL)
        } catch {
        }
    }
}

