import Foundation

protocol AIProviderStrategy {
    func send(message: String, context: [AIMessage]) async throws -> String
}
