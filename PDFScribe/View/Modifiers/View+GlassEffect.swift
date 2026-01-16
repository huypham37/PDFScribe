import SwiftUI

extension View {
    @ViewBuilder
    func glassBackground() -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect()
        } else {
            // Brand-aligned fallback with subtle translucency
            self
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.brandBackground.opacity(0.85))
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.brandBackgroundSecondary.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
    }
}
