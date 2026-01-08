import Foundation

struct AIContext {
    let messages: [AIMessage]
    let currentFile: URL?
    let currentFileContent: String?
    let selection: String?
    let pdfURL: URL?
    let pdfSelection: String?
    let pdfPage: Int?
    let referencedFiles: [URL]
}

protocol AIProviderStrategy {
    func send(message: String, context: AIContext) async throws -> String
}
