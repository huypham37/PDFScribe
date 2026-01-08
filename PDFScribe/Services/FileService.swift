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
}
