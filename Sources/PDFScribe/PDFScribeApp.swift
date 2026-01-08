import SwiftUI

@main
struct PDFScribeApp: App {
    @StateObject private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            MainSplitView()
                .environmentObject(appViewModel)
        }
        .windowStyle(.titleBar)
    }
}
