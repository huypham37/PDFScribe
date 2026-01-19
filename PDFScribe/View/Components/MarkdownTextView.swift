import SwiftUI
import Textual

struct MarkdownTextView: View {
    let content: String
    
    var body: some View {
        StructuredText(markdown: content)
            .textual.structuredTextStyle(.luxury)
            .textual.textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
