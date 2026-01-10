import SwiftUI

extension View {
    @ViewBuilder
    func glassBackground() -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect()
        } else {
            // Enhanced fallback with visible translucent effect
            self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
