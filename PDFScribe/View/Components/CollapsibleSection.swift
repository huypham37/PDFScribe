import SwiftUI

struct CollapsibleSection: View {
    let section: MarkdownSection
    let citations: CitationContext
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
                        .foregroundColor(.brandText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.brandSecondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
                }
            }
            .buttonStyle(.plain)
            .padding(.bottom, isExpanded ? 12 : 0)
            
            // Content
            if isExpanded {
                CitationAwareTextView(
                    markdown: section.content,
                    citations: citations,
                    onCitationTap: onCitationTap
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.top, 20)
    }
}
