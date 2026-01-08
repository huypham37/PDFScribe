import Combine
import SwiftUI

@MainActor
class EditorViewModel: ObservableObject {
    @Published var content: String = "" {
        didSet {
            if content != oldValue {
                contentDidChange?(content)
            }
        }
    }
    
    var contentDidChange: ((String) -> Void)?
    
    func insertQuote(text: String, pageNumber: Int) {
        // Sanitize text by escaping special characters
        let sanitizedText = text.replacingOccurrences(of: "\"", with: "\\\"")
        let quote = "> \"\(sanitizedText)\" [Page \(pageNumber)]\n\n"
        content += quote
    }
    
    func loadContent(_ newContent: String) {
        content = newContent
    }
}
