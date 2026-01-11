import SwiftUI

struct SourcesList: View {
    let references: [String]
    
    var body: some View {
        if !references.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                // Section header
                Text("SOURCES")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(nsColor: NSColor(white: 0.5, alpha: 1.0)))
                    .tracking(1.2)
                    .padding(.bottom, 12)
                
                // Source items
                VStack(spacing: 6) {
                    ForEach(Array(references.enumerated()), id: \.offset) { index, url in
                        SourceItem(number: index + 1, url: url)
                    }
                }
            }
            .padding(.top, 24)
        }
    }
}

// MARK: - Source Item Component

private struct SourceItem: View {
    let number: Int
    let url: String
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            if let nsURL = URL(string: url) {
                NSWorkspace.shared.open(nsURL)
            }
        }) {
            HStack(alignment: .top, spacing: 12) {
                // Number badge
                Text("\(number)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(nsColor: NSColor(white: 0.5, alpha: 1.0)))
                    .frame(width: 28, height: 28)
                    .background(isHovered ? Color(nsColor: NSColor(white: 0.85, alpha: 1.0)) : Color(nsColor: NSColor(white: 0.92, alpha: 1.0)))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                // URL info
                VStack(alignment: .leading, spacing: 2) {
                    Text(extractTitle(from: url))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isHovered ? Color.blue : Color(nsColor: NSColor(white: 0.1, alpha: 1.0)))
                        .lineLimit(1)
                    
                    Text(extractDomain(from: url))
                        .font(.system(size: 11))
                        .foregroundColor(Color(nsColor: NSColor(white: 0.5, alpha: 1.0)))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(10)
            .background(isHovered ? Color(nsColor: NSColor(white: 0.97, alpha: 1.0)) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    private func extractDomain(from urlString: String) -> String {
        guard let url = URL(string: urlString),
              let host = url.host else {
            return urlString
        }
        return host.replacingOccurrences(of: "www.", with: "")
    }
    
    private func extractTitle(from urlString: String) -> String {
        guard let url = URL(string: urlString) else {
            return urlString
        }
        
        let path = url.path
        let filename = path.components(separatedBy: "/").last ?? ""
        
        if !filename.isEmpty {
            return filename
                .replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }
        
        return extractDomain(from: urlString)
    }
}
