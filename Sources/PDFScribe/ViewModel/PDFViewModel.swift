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
    @Published var selectedText: PDFSelection?
    @Published var errorMessage: String?
    @Published var currentPage: Int = 0
    @Published var totalPages: Int = 0
    
    func loadPDF(url: URL) throws {
        guard let pdf = PDFDocument(url: url) else {
            throw PDFError.couldNotLoad
        }
        self.document = pdf
        self.totalPages = pdf.pageCount
        self.currentPage = 1
        self.errorMessage = nil
    }
}
