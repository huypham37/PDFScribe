import SwiftUI
import PDFKit

class PDFViewModel: ObservableObject {
    @Published var document: PDFDocument?
    @Published var selectedText: String?
    
    func loadPDF(url: URL) {
        if let pdf = PDFDocument(url: url) {
            self.document = pdf
        }
    }
}
