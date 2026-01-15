import Foundation

class OpenAIStrategy: AIProviderStrategy {
    private let apiKey: String
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    private var selectedModel: AIModel
    
    private let models: [AIModel] = [
        AIModel(id: "gpt-4o", name: "GPT-4o", provider: .openai),
        AIModel(id: "gpt-4o-mini", name: "GPT-4o Mini", provider: .openai),
        AIModel(id: "gpt-4-turbo", name: "GPT-4 Turbo", provider: .openai),
        AIModel(id: "gpt-4", name: "GPT-4", provider: .openai)
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
                        "temperature": 0.7,
                        "stream": true
                    ]
                    
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization")
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
                            if jsonString == "[DONE]" {
                                break
                            }
                            if let data = jsonString.data(using: .utf8),
                               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let choices = json["choices"] as? [[String: Any]],
                               let delta = choices.first?["delta"] as? [String: Any],
                               let content = delta["content"] as? String {
                                continuation.yield(content)
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
        throw AIError.serverError("Modes not supported for OpenAI")
    }
}
