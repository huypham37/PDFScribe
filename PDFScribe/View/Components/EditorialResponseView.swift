import SwiftUI
import MarkdownUI

struct EditorialResponseView: View {
    let message: StoredMessage
    let modelName: String
    
    @State private var expandedSections: Set<UUID> = []
    private let parser = MessageParser()
    
    var body: some View {
        let structured = parser.parseIntoSections(message.content)
        
        return VStack(alignment: .leading, spacing: 0) {
            // Badges row
            BadgeRow(
                modelName: modelName,
                sourceCount: structured.references.count
            )
            .padding(.bottom, 20)
            
            // Summary (if exists)
            if let summary = structured.summary, !summary.isEmpty {
                Markdown(summary)
                    .markdownTheme(.luxury)
                    .textSelection(.enabled)
                    .padding(.bottom, 24)
            }
            
            // Collapsible sections
            if !structured.sections.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(structured.sections.enumerated()), id: \.element.id) { index, section in
                        CollapsibleSection(
                            section: section,
                            isExpanded: expandedSections.contains(section.id),
                            onToggle: {
                                toggleSection(section.id)
                            },
                            onCitationTap: { citationNumber in
                                scrollToSource(citationNumber)
                            }
                        )
                        
                        // Divider between sections (except last)
                        if index < structured.sections.count - 1 {
                            Divider()
                                .background(Color(nsColor: NSColor(white: 0.9, alpha: 1.0)))
                                .padding(.top, 20)
                        }
                    }
                }
            }
            
            // Sources list
            SourcesList(references: structured.references)
        }
        .onAppear {
            // Auto-expand first section
            if let firstSection = structured.sections.first {
                expandedSections.insert(firstSection.id)
            }
        }
    }
    
    private func toggleSection(_ id: UUID) {
        if expandedSections.contains(id) {
            expandedSections.remove(id)
        } else {
            expandedSections.insert(id)
        }
    }
    
    private func scrollToSource(_ number: Int) {
        // TODO: Implement scroll to source in future iteration
    }
}
