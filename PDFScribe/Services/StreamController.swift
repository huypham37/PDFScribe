import Foundation

/// Streams text chunks from AI service to UI for smooth animation.
/// Passes through chunks directly without artificial delays - SwiftUI handles animation.
actor StreamController {
    
    /// Passes through chunks from input stream directly to output.
    /// SwiftUI animation handles the smooth appearance.
    func process(_ input: AsyncThrowingStream<String, Error>, speed: TypingSpeed) -> AsyncStream<String> {
        print("🔵 DEBUG: StreamController.process() started - passthrough mode for animation")
        
        return AsyncStream { continuation in
            Task(priority: .userInitiated) {
                var totalCharacters = 0
                let startTime = Date()
                var chunkCount = 0
                
                do {
                    print("🔵 DEBUG: StreamController waiting for chunks...")
                    for try await chunk in input {
                        if Task.isCancelled { break }
                        
                        chunkCount += 1
                        print("🔵 DEBUG: StreamController received chunk #\(chunkCount): '\(chunk.prefix(30))...' (\(chunk.count) chars)")
                        
                        // Pass through chunk directly - no splitting, no delay
                        continuation.yield(chunk)
                        totalCharacters += chunk.count
                        
                        print("🔵 DEBUG: Yielded chunk #\(chunkCount) to continuation")
                    }
                    
                    let totalTime = Date().timeIntervalSince(startTime)
                    let cps = totalTime > 0 ? Double(totalCharacters) / totalTime : 0
                    print("📊 Stream Metrics: \(totalCharacters) chars in \(String(format: "%.2f", totalTime))s (\(String(format: "%.1f", cps)) chars/s)")
                    
                } catch {
                    print("❌ StreamController error: \(error)")
                }
                
                continuation.finish()
                print("🔵 DEBUG: StreamController finished")
            }
        }
    }
}
