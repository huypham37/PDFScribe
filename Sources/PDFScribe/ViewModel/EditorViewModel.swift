import SwiftUI

@MainActor
class EditorViewModel: ObservableObject {
    @Published var content: String = ""
    
    func insertQuote(text: String, pageNumber: Int) {
        // Sanitize text by escaping special characters
        let sanitizedText = text.replacingOccurrences(of: "\"", with: "\\\"")
        let quote = "> \"\(sanitizedText)\" [Page \(pageNumber)]\n\n"
        content += quote
    }
}
