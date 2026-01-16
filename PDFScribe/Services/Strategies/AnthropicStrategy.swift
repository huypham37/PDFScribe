import Foundation

class AnthropicStrategy: AIProviderStrategy {
    private let apiKey: String
    private let endpoint = "https://api.anthropic.com/v1/messages"
    private var selectedModel: AIModel
    
    private let models: [AIModel] = [
        AIModel(id: "claude-3-5-sonnet-20241022", name: "Claude 3.5 Sonnet", provider: .anthropic),
        AIModel(id: "claude-3-5-haiku-20241022", name: "Claude 3.5 Haiku", provider: .anthropic),
        AIModel(id: "claude-3-opus-20240229", name: "Claude 3 Opus", provider: .anthropic)
    ]
    
    init(apiKey: String) {
        self.apiKey = apiKey
        self.selectedModel = models[0]
    }
    
    func sendStream(message: String, context: AIContext) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    guard !self.apiKey.isEmpty else {
                        continuation.finish(throwing: AIError.invalidAPIKey)
                        return
                    }
                    
                    guard let url = URL(string: self.endpoint) else {
                        continuation.finish(throwing: AIError.invalidResponse)
                        return
                    }
                    
                    var messages = context.messages.map { ["role": $0.role, "content": $0.content] }
                    messages.append(["role": "user", "content": message])
                    
                    let requestBody: [String: Any] = [
                        "model": self.selectedModel.id,
                        "messages": messages,
                        "max_tokens": 4096,
                        "stream": true
                    ]
                    
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue(self.apiKey, forHTTPHeaderField: "x-api-key")
                    request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                    
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: AIError.invalidResponse)
                        return
                    }
                    
                    guard httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: AIError.serverError("HTTP \(httpResponse.statusCode)"))
                        return
                    }
                    
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let jsonString = String(line.dropFirst(6))
                            if let data = jsonString.data(using: .utf8),
                               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let type = json["type"] as? String {
                                if type == "content_block_delta",
                                   let delta = json["delta"] as? [String: Any],
                                   let text = delta["text"] as? String {
                                    continuation.yield(text)
                                } else if type == "message_stop" {
                                    break
                                }
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func availableModels() -> [AIModel] {
        return models
    }
    
    func availableModes() -> [AIMode] {
        return []
    }
    
    func currentModel() -> AIModel? {
        return selectedModel
    }
    
    func currentMode() -> AIMode? {
        return nil
    }
    
    func selectModel(_ model: AIModel) async throws {
        guard models.contains(where: { $0.id == model.id }) else {
            throw AIError.serverError("Model \(model.id) not available")
        }
        selectedModel = model
    }
    
    func selectMode(_ mode: AIMode) async throws {
        throw AIError.serverError("Modes not supported for Anthropic")
    }
    
    func cancel() {
        // Anthropic uses URLSession which doesn't provide easy cancellation
        // The Task cancellation in AIViewModel will handle stream termination
    }
}
