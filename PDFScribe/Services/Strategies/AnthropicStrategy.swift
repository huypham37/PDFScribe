import Foundation

class AnthropicStrategy: AIProviderStrategy {
    private let apiKey: String
    private let endpoint = "https://api.anthropic.com/v1/messages"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func send(message: String, context: [AIMessage]) async throws -> String {
        guard !apiKey.isEmpty else {
            throw AIError.invalidAPIKey
        }
        
        guard let url = URL(string: endpoint) else {
            throw AIError.invalidResponse
        }
        
        var messages = context.map { ["role": $0.role, "content": $0.content] }
        messages.append(["role": "user", "content": message])
        
        let requestBody: [String: Any] = [
            "model": "claude-3-5-sonnet-20241022",
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
}
