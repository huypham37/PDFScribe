import SwiftUI

@MainActor
class AppViewModel: ObservableObject {
    @Published var documentTitle: String = "Untitled"
    
    // We will add more state here later (current file path, etc.)
}
