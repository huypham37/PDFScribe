import SwiftUI
import PDFKit

enum PDFError: Error {
    case couldNotLoad
    case fileNotFound
    case invalidFormat
}

@MainActor
class PDFViewModel: ObservableObject {
    @Published var document: PDFDocument?
    @Published var selectedText: String?
    @Published var errorMessage: String?
    
    func loadPDF(url: URL) throws {
        guard let pdf = PDFDocument(url: url) else {
            throw PDFError.couldNotLoad
        }
        self.document = pdf
        self.errorMessage = nil
    }
}
