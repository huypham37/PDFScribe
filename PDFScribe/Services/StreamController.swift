import Foundation

/// Controls the flow of text streaming to ensure a smooth, readable "typing" effect
/// and tracks performance metrics.
actor StreamController {
    
    struct Metrics {
        var timeToFirstToken: TimeInterval = 0
        var totalCharacters: Int = 0
        var totalTime: TimeInterval = 0
        var charactersPerSecond: Double {
            return totalTime > 0 ? Double(totalCharacters) / totalTime : 0
        }
    }
    
    private var metrics = Metrics()
    
    /// Processes a raw string stream and yields characters at a controlled pace based on typing speed.
    /// - Parameters:
    ///   - input: The raw stream from the AI service
    ///   - speed: The desired typing speed (delay between characters)
    /// - Returns: A controlled stream that yields individual characters
    func process(_ input: AsyncThrowingStream<String, Error>, speed: TypingSpeed) -> AsyncStream<String> {
        return AsyncStream { continuation in
            Task {
                var characterCount = 0
                let startTime = Date()
                
                do {
                    // Stream characters from each chunk immediately as they arrive
                    for try await chunk in input {
                        for char in chunk {
                            try? await Task.sleep(nanoseconds: speed.nanoseconds)
                            continuation.yield(String(char))
                            characterCount += 1
                        }
                    }
                    
                    let totalTime = Date().timeIntervalSince(startTime)
                    let cps = totalTime > 0 ? Double(characterCount) / totalTime : 0
                    print("📊 Stream Metrics: \(characterCount) chars in \(String(format: "%.2f", totalTime))s (\(String(format: "%.1f", cps)) chars/s)")
                    
                    continuation.finish()
                } catch {
                    print("❌ Stream error: \(error)")
                    continuation.finish()
                }
            }
        }
    }
}
