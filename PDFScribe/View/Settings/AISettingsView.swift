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
                } else {
                    SecureField("API Key", text: $aiService.apiKey)
                }
                
                Picker("Streaming Speed", selection: $aiService.typingSpeed) {
                    ForEach(TypingSpeed.allCases, id: \.self) { speed in
                        Text("\(speed.displayName) (\(speed.rawValue)ms)").tag(speed)
                    }
                }
                .help("Controls how fast AI responses appear character-by-character")
            }
            
            Button("Save") {
                aiService.saveAPIKey()
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}
