import SwiftUI

struct AISettingsView: View {
    @ObservedObject var aiService: AIService
    
    var body: some View {
        Form {
            Section("AI Provider") {
                Picker("Provider", selection: $aiService.provider) {
                    ForEach(AIProvider.allCases, id: \.self) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
            }
            
            Section("Settings") {
                if aiService.provider == .opencode {
                    TextField("OpenCode Path", text: $aiService.opencodePath)
                } else if aiService.provider == .mock {
                    Text("Mock provider - no configuration needed")
                        .foregroundColor(.secondary)
                } else {
                    SecureField("API Key", text: $aiService.apiKey)
                }
                
                Picker("Streaming Speed", selection: $aiService.typingSpeed) {
                    ForEach(TypingSpeed.allCases, id: \.self) { speed in
                        Text("\(speed.displayName) (\(speed.rawValue)ms)").tag(speed)
                    }
                }
                .help("Controls how fast AI responses appear character-by-character")
                
                Picker("Fade-In Effect", selection: $aiService.fadeInSpeed) {
                    ForEach(FadeInSpeed.allCases, id: \.self) { speed in
                        Text("\(speed.displayName) (\(String(format: "%.1f", speed.rawValue))s)").tag(speed)
                    }
                }
                .help("Controls the smoothness of text fade-in animation")
            }
            
            Button("Save") {
                aiService.saveAPIKey()
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}
