import Foundation
import PDFKit
import AppKit

class ReportExportService {
    
    // MARK: - Export to Markdown
    static func exportToMarkdown(session: ChatSession, messages: [StoredMessage]) -> String {
        var markdown = ""
        
        // Header
        markdown += "# \(session.title)\n\n"
        
        // Metadata
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        let dateString = formatter.string(from: session.createdAt)
        
        markdown += "**Date:** \(dateString)\n\n"
        markdown += "**Sections:** \(messages.count / 2)\n\n"
        markdown += "---\n\n"
        
        // Content sections
        for (index, stride) in Array(stride(from: 0, to: messages.count, by: 2)).enumerated() {
            if stride < messages.count {
                let query = messages[stride]
                let sectionNumber = index + 1
                
                markdown += "## \(sectionNumber). \(query.content)\n\n"
                
                if stride + 1 < messages.count {
                    let response = messages[stride + 1]
                    markdown += "\(response.content)\n\n"
                }
                
                markdown += "---\n\n"
            }
        }
        
        return markdown
    }
    
    // MARK: - Save Markdown to File
    static func saveMarkdown(content: String, filename: String, to directory: URL) throws -> URL {
        let fileURL = directory.appendingPathComponent("\(filename).md")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    // MARK: - Export to PDF
    static func exportToPDF(session: ChatSession, messages: [StoredMessage]) -> Data? {
        // Create attributed string for PDF
        let attributedString = createAttributedString(session: session, messages: messages)
        
        // Create PDF
        let pdfData = NSMutableData()
        
        // Page setup
        let pageWidth: CGFloat = 612  // 8.5 inches
        let pageHeight: CGFloat = 792  // 11 inches
        let margin: CGFloat = 72  // 1 inch margins
        
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else {
            return nil
        }
        
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        guard let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return nil
        }
        
        let textRect = CGRect(x: margin, y: margin, width: pageWidth - 2 * margin, height: pageHeight - 2 * margin)
        
        pdfContext.beginPDFPage(nil)
        
        // Draw the attributed string
        attributedString.draw(in: textRect)
        
        pdfContext.endPDFPage()
        pdfContext.closePDF()
        
        return pdfData as Data
    }
    
    // MARK: - Save PDF to File
    static func savePDF(data: Data, filename: String, to directory: URL) throws -> URL {
        let fileURL = directory.appendingPathComponent("\(filename).pdf")
        try data.write(to: fileURL)
        return fileURL
    }
    
    // MARK: - Create Attributed String for PDF
    private static func createAttributedString(session: ChatSession, messages: [StoredMessage]) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Palatino-Bold", size: 32) ?? NSFont.boldSystemFont(ofSize: 32),
            .foregroundColor: NSColor.textColor
        ]
        result.append(NSAttributedString(string: "\(session.title)\n\n", attributes: titleAttributes))
        
        // Metadata
        let metadataAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        let dateString = formatter.string(from: session.createdAt)
        
        result.append(NSAttributedString(string: "Date: \(dateString)\n", attributes: metadataAttributes))
        result.append(NSAttributedString(string: "Sections: \(messages.count / 2)\n\n", attributes: metadataAttributes))
        
        // Divider
        result.append(NSAttributedString(string: "────────────────────────────────\n\n", attributes: metadataAttributes))
        
        // Content sections
        let headingAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Palatino-Bold", size: 20) ?? NSFont.boldSystemFont(ofSize: 20),
            .foregroundColor: NSColor.textColor
        ]
        
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Palatino", size: 13) ?? NSFont.systemFont(ofSize: 13),
            .foregroundColor: NSColor.textColor
        ]
        
        for (index, stride) in Array(stride(from: 0, to: messages.count, by: 2)).enumerated() {
            if stride < messages.count {
                let query = messages[stride]
                let sectionNumber = index + 1
                
                result.append(NSAttributedString(string: "\n\(sectionNumber). \(query.content)\n\n", attributes: headingAttributes))
                
                if stride + 1 < messages.count {
                    let response = messages[stride + 1]
                    result.append(NSAttributedString(string: "\(response.content)\n\n", attributes: bodyAttributes))
                }
            }
        }
        
        return result
    }
}
