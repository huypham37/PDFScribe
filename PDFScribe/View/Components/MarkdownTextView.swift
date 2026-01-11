import SwiftUI
import MarkdownUI

struct MarkdownTextView: View {
    let content: String
    
    var body: some View {
        Markdown(content)
            .markdownTheme(.luxury)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
