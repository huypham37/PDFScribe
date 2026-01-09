import SwiftUI

struct TestSymbolView: View {
    @State private var isActive = false
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Symbol Effect Test")
                .font(.title)
            
            // Test 1: scribble with drawOn (TOGGLE isActive)
            VStack {
                Text("scribble + drawOn (toggle isActive)")
                    .font(.caption)
                Image(systemName: "scribble")
                    .font(.system(size: 40))
                    .symbolEffect(.drawOn.wholeSymbol, isActive: isActive)
                    .onAppear {
                        // Toggle isActive every 2 seconds to retrigger animation
                        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                            isActive.toggle()
                            print("🎨 isActive toggled: \(isActive)")
                        }
                        // Initial trigger
                        isActive = true
                    }
                    .onDisappear {
                        timer?.invalidate()
                    }
            }
            
            // Test 2: scribble.variable with drawOn (TOGGLE)
            VStack {
                Text("scribble.variable + drawOn (toggle)")
                    .font(.caption)
                Image(systemName: "scribble.variable")
                    .font(.system(size: 40))
                    .symbolEffect(.drawOn.wholeSymbol, isActive: isActive)
            }
            
            // Test 3: pencil with drawOn (TOGGLE)
            VStack {
                Text("pencil + drawOn (toggle)")
                    .font(.caption)
                Image(systemName: "pencil")
                    .font(.system(size: 40))
                    .symbolEffect(.drawOn.wholeSymbol, isActive: isActive)
            }
            
            // Test 4: scribble with variableColor (control - should work)
            VStack {
                Text("scribble.variable + variableColor (control)")
                    .font(.caption)
                Image(systemName: "scribble.variable")
                    .font(.system(size: 40))
                    .symbolEffect(.variableColor.iterative, options: .repeat(.continuous))
            }
            
            Text("isActive: \(isActive ? "true" : "false")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 400, height: 600)
    }
}

#Preview {
    TestSymbolView()
}
