import Foundation

class MockAIStrategy: AIProviderStrategy {
    private var selectedModel: AIModel?
    private var selectedMode: AIMode?
    private var typingSpeed: TypingSpeed
    
    init(typingSpeed: TypingSpeed = .normal) {
        self.typingSpeed = typingSpeed
        self.selectedModel = availableModels().first
        self.selectedMode = availableModes().first
    }
    
    func sendStream(message: String, context: AIContext) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                // Generate a realistic mock response
                let response = generateMockResponse(for: message)
                
                // Stream character by character with typing delay
                for char in response {
                    try? await Task.sleep(nanoseconds: typingSpeed.nanoseconds)
                    continuation.yield(String(char))
                }
                
                continuation.finish()
            }
        }
    }
    
    func availableModels() -> [AIModel] {
        return [
            AIModel(id: "mock-fast", name: "Mock Fast", provider: .mock),
            AIModel(id: "mock-standard", name: "Mock Standard", provider: .mock),
            AIModel(id: "mock-advanced", name: "Mock Advanced", provider: .mock)
        ]
    }
    
    func availableModes() -> [AIMode] {
        return [
            AIMode(id: "mock-chat", name: "Chat", description: "Mock chat mode"),
            AIMode(id: "mock-research", name: "Research", description: "Mock research mode"),
            AIMode(id: "mock-code", name: "Code", description: "Mock code mode")
        ]
    }
    
    func currentModel() -> AIModel? {
        return selectedModel
    }
    
    func currentMode() -> AIMode? {
        return selectedMode
    }
    
    func selectModel(_ model: AIModel) async throws {
        selectedModel = model
    }
    
    func selectMode(_ mode: AIMode) async throws {
        selectedMode = mode
    }
    
    // MARK: - Private Helpers
    
    private func generateMockResponse(for message: String) -> String {
        let lowercaseMessage = message.lowercased()
        
        // Provide contextual responses based on keywords
        if lowercaseMessage.contains("hello") || lowercaseMessage.contains("hi") {
            return "Hello! I'm a mock AI assistant. How can I help you test the application today?"
        }
        
        if lowercaseMessage.contains("test") {
            return """
            This is a **mock response** for testing purposes [1]. Here are some features being tested:
            
            - Streaming text rendering [2]
            - Auto-scroll behavior [3]
            - Markdown formatting support
            - Message history
            - Inline citation badges [1][2][3]
            
            The mock service simulates real AI responses without API costs [1]!
            
            [1]: https://developer.apple.com/documentation/swiftui
            [2]: https://www.swift.org/documentation/
            [3]: https://github.com/apple/swift
            """
        }
        
        if lowercaseMessage.contains("code") {
            return """
            Here's a sample code snippet for testing:
            
            ```swift
            func greet(name: String) -> String {
                return "Hello, \\(name)!"
            }
            
            let message = greet(name: "World")
            print(message)
            ```
            
            This demonstrates **code block rendering** in the mock response.
            """
        }
        
        if lowercaseMessage.contains("list") {
            return """
            Here's a mock list response:
            
            1. First item with **bold text**
            2. Second item with *italic text*
            3. Third item with `inline code`
            
            And a bulleted list:
            
            - Apple
            - Banana
            - Cherry
            """
        }
        
        if lowercaseMessage.contains("long") || lowercaseMessage.contains("scroll") {
            return """
            # Testing Auto-Scroll with Long Response
            
            This is a longer mock response designed to test the auto-scroll functionality [1].
            
            ## Section 1: Introduction
            
            Lorem ipsum dolor sit amet, consectetur adipiscing elit [2]. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
            
            ## Section 2: Details
            
            Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris [3] nisi ut aliquip ex ea commodo consequat.
            
            ### Subsection 2.1
            
            Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore [1][2] eu fugiat nulla pariatur.
            
            ### Subsection 2.2
            
            Excepteur sint occaecat cupidatat non proident [4], sunt in culpa qui officia deserunt mollit anim id est laborum.
            
            ## Section 3: Conclusion
            
            This concludes the mock response [1][2][3][4]. The auto-scroll should position this content appropriately.
            
            [1]: https://developer.apple.com/documentation/swiftui
            [2]: https://www.swift.org/documentation/
            [3]: https://github.com/apple/swift
            [4]: https://swift.org/getting-started/
            """
        }
        
        // Default generic response with citations
        return """
        I'm a mock AI assistant running in test mode. You asked: "\(message)"
        
        This is a simulated response with **Markdown formatting** support and inline citations [1]:
        
        - No API costs [2]
        - Instant responses [3]
        - Perfect for UI testing
        
        ## Research Findings
        
        Recent studies [1][2] have shown that mock testing significantly improves development speed. The implementation uses SwiftUI [3] for native macOS integration.
        
        According to the documentation [1], this approach provides several benefits:
        
        1. Faster iteration cycles [2]
        2. Reduced API costs [3]
        3. Consistent test results
        
        Try asking about "test", "code", "list", or "scroll" for different response types!
        
        [1]: https://developer.apple.com/documentation/swiftui
        [2]: https://www.swift.org/documentation/
        [3]: https://github.com/apple/swift
        """
    }
}
