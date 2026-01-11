import SwiftUI

struct BadgeRow: View {
    let modelName: String
    let sourceCount: Int
    
    var body: some View {
        HStack(spacing: 8) {
            // Model badge
            Badge(
                icon: "circle",
                text: modelName,
                foregroundColor: .gray,
                backgroundColor: Color(nsColor: NSColor(white: 0.95, alpha: 1.0)),
                borderColor: Color(nsColor: NSColor(white: 0.85, alpha: 1.0))
            )
            
            // Sources badge
            if sourceCount > 0 {
                Badge(
                    icon: "checkmark.circle",
                    text: "\(sourceCount) Source\(sourceCount == 1 ? "" : "s")",
                    foregroundColor: Color.blue.opacity(0.8),
                    backgroundColor: Color.blue.opacity(0.08),
                    borderColor: Color.blue.opacity(0.2)
                )
            }
        }
    }
}

// MARK: - Badge Component

private struct Badge: View {
    let icon: String
    let text: String
    let foregroundColor: Color
    let backgroundColor: Color
    let borderColor: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(foregroundColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
