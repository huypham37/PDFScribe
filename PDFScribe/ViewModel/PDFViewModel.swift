import Combine
import SwiftUI
import PDFKit

enum PDFError: Error {
    case couldNotLoad
    case fileNotFound
    case invalidFormat
}

struct PDFSelection {
    let text: String
    let pageNumber: Int
}

@MainActor
class PDFViewModel: ObservableObject {
    @Published var document: PDFDocument?
    @Published var currentPDFURL: URL?
    @Published var currentSelection: PDFSelection?  // Current selection (updates during drag)
    @Published var pendingQuote: PDFSelection?      // Quote to be inserted (set by button click)
    @Published var errorMessage: String?
    @Published var currentPage: Int = 0
    @Published var totalPages: Int = 0
    
    var hasSelection: Bool {
        guard let selection = currentSelection else { return false }
        return !selection.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func addQuote() {
        guard let selection = currentSelection,
              !selection.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        pendingQuote = selection
    }
    
    func loadPDF(url: URL) throws {
        guard let pdf = PDFDocument(url: url) else {
            throw PDFError.couldNotLoad
        }
        self.document = pdf
        self.currentPDFURL = url
        self.totalPages = pdf.pageCount
        self.currentPage = 1
        self.errorMessage = nil
    }
}
