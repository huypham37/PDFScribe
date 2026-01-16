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
    func sendStream(message: String, context: AIContext) -> AsyncThrowingStream<String, Error>
    func availableModels() -> [AIModel]
    func availableModes() -> [AIMode]
    func currentModel() -> AIModel?
    func currentMode() -> AIMode?
    func selectModel(_ model: AIModel) async throws
    func selectMode(_ mode: AIMode) async throws
    func cancel() // Cancel the current request
}
