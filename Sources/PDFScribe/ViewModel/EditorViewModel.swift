import SwiftUI

class EditorViewModel: ObservableObject {
    @Published var content: String = ""
    
    func insertQuote(text: String, pageNumber: Int) {
        let quote = "> \"\(text)\" [Page \(pageNumber)]\n\n"
        content += quote
    }
}
