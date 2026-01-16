import Foundation

/// Streams text chunks from AI service to UI for smooth animation.
/// Passes through chunks directly without artificial delays - SwiftUI handles animation.
actor StreamController {
    
    /// Passes through chunks from input stream directly to output.
    /// SwiftUI animation handles the smooth appearance.
    func process(_ input: AsyncThrowingStream<String, Error>, speed: TypingSpeed) -> AsyncStream<String> {
        return AsyncStream { continuation in
            Task(priority: .userInitiated) {
                var totalCharacters = 0
                let startTime = Date()
                var chunkCount = 0
                
                defer {
                    continuation.finish()
                }
                
                do {
                    for try await chunk in input {
                        if Task.isCancelled { 
                            return  // Exit early, defer will finish continuation
                        }
                        
                        chunkCount += 1
                        
                        // Pass through chunk directly - no splitting, no delay
                        continuation.yield(chunk)
                        totalCharacters += chunk.count
                    }
                    
                } catch {
                    // Error logged, continuation finished by defer
                }
            }
        }
    }
}
