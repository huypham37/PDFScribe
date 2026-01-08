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
    
    func send(message: String, context: AIContext) async throws -> String {
        guard !apiKey.isEmpty else {
            throw AIError.invalidAPIKey
        }
        
        guard let url = URL(string: endpoint) else {
            throw AIError.invalidResponse
        }
        
        var messages = context.messages.map { ["role": $0.role, "content": $0.content] }
        messages.append(["role": "user", "content": message])
        
        let requestBody: [String: Any] = [
            "model": selectedModel.id,
            "messages": messages,
            "max_tokens": 4096
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw AIError.serverError(errorMessage)
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let content = json?["content"] as? [[String: Any]],
                  let firstContent = content.first,
                  let text = firstContent["text"] as? String else {
                throw AIError.invalidResponse
            }
            
            return text
        } catch let error as AIError {
            throw error
        } catch {
            throw AIError.networkError(error)
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
}
