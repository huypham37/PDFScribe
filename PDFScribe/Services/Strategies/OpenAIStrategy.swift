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
            "temperature": 0.7
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
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
            guard let choices = json?["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw AIError.invalidResponse
            }
            
            return content
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
        throw AIError.serverError("Modes not supported for OpenAI")
    }
}
