import SwiftUI
import MarkdownUI

struct CollapsibleSection: View {
    let section: MarkdownSection
    let isExpanded: Bool
    let onToggle: () -> Void
    let onCitationTap: ((Int) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    onToggle()
                }
            }) {
                HStack(alignment: .top, spacing: 12) {
                    Text(section.title ?? "")
                        .font(.custom("Charter", size: 19))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(nsColor: NSColor(white: 0.1, alpha: 1.0)))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(nsColor: NSColor(white: 0.6, alpha: 1.0)))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
                }
            }
            .buttonStyle(.plain)
            .padding(.bottom, isExpanded ? 12 : 0)
            
            // Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    Markdown(section.content)
                        .markdownTheme(.luxury)
                        .textSelection(.enabled)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    
                    CitationPills(content: section.content, onCitationTap: onCitationTap)
                }
            }
        }
        .padding(.top, 20)
    }
}
