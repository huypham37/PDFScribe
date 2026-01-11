import SwiftUI

struct CitationPills: View {
    let content: String
    let onCitationTap: ((Int) -> Void)?
    
    var body: some View {
        let citations = extractCitations(from: content)
        
        if !citations.isEmpty {
            HStack(spacing: 6) {
                ForEach(citations, id: \.self) { number in
                    CitationPill(number: number) {
                        onCitationTap?(number)
                    }
                }
            }
            .padding(.top, 8)
        }
    }
    
    private func extractCitations(from text: String) -> [Int] {
        let pattern = "\\[(\\d+)\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }
        
        let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
        var citations = Set<Int>()
        
        for match in matches {
            if let range = Range(match.range(at: 1), in: text),
               let number = Int(text[range]) {
                citations.insert(number)
            }
        }
        
        return citations.sorted()
    }
}

// MARK: - Citation Pill Component

private struct CitationPill: View {
    let number: Int
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text("\(number)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(nsColor: NSColor(white: 0.4, alpha: 1.0)))
                .frame(width: 22, height: 22)
                .background(isHovered ? Color(nsColor: NSColor(white: 0.85, alpha: 1.0)) : Color(nsColor: NSColor(white: 0.92, alpha: 1.0)))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(nsColor: NSColor(white: 0.7, alpha: 1.0)), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
