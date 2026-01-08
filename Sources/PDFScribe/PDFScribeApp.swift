import SwiftUI

@main
struct PDFScribeApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var pdfViewModel = PDFViewModel()
    @StateObject private var editorViewModel = EditorViewModel()

    var body: some Scene {
        WindowGroup {
            MainSplitView()
                .environmentObject(appViewModel)
                .environmentObject(pdfViewModel)
                .environmentObject(editorViewModel)
        }
        .windowStyle(.titleBar)
    }
}
