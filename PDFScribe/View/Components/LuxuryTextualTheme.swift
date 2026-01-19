import SwiftUI
import Textual

// MARK: - Luxury StructuredText Style
struct LuxuryTextualStyle: StructuredText.Style {
    // MARK: Inline Styles
    var inlineStyle: InlineStyle {
        InlineStyle()
            .code(.monospaced, .fontScale(0.88))
            .strong(.fontWeight(.semibold))
            .emphasis(.italic)
            .link(.foregroundColor(.brandPrimary))
    }
    
    // MARK: Block Styles
    var headingStyle: LuxuryHeadingStyle { .init() }
    var paragraphStyle: LuxuryParagraphStyle { .init() }
    var blockQuoteStyle: LuxuryBlockQuoteStyle { .init() }
    var codeBlockStyle: LuxuryCodeBlockStyle { .init() }
    var listItemStyle: LuxuryListItemStyle { .init() }
    var tableStyle: StructuredText.DefaultTableStyle { .default }
    var tableCellStyle: StructuredText.DefaultTableCellStyle { .default }
    var thematicBreakStyle: StructuredText.DividerThematicBreakStyle { .divider }
    
    // MARK: List Markers
    var unorderedListMarker: StructuredText.SymbolListMarker { .disc }
    var orderedListMarker: StructuredText.DecimalListMarker { .decimal }
}

// MARK: - Heading Style
struct LuxuryHeadingStyle: StructuredText.HeadingStyle {
    func makeBody(configuration: Configuration) -> some View {
        let level = configuration.headingLevel
        let size: CGFloat = switch level {
            case 1: 32
            case 2: 26
            case 3: 21
            case 4: 19
            default: 17
        }
        
        configuration.label
            .font(.custom("Palatino", size: size))
            .fontWeight(level <= 2 ? .bold : .semibold)
            .textual.blockSpacing(StructuredText.BlockSpacing(
                top: level == 1 ? 24 : 20,
                bottom: level == 1 ? 16 : 12
            ))
    }
}

// MARK: - Paragraph Style
struct LuxuryParagraphStyle: StructuredText.ParagraphStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("Palatino", size: 17))
            .textual.blockSpacing(StructuredText.BlockSpacing(top: 0, bottom: 16))
    }
}

// MARK: - BlockQuote Style
struct LuxuryBlockQuoteStyle: StructuredText.BlockQuoteStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.leading, 16)
            .padding(.vertical, 8)
            .overlay(
                Rectangle()
                    .fill(Color.brandPrimary.opacity(0.3))
                    .frame(width: 4),
                alignment: .leading
            )
            .textual.blockSpacing(StructuredText.BlockSpacing(top: 8, bottom: 8))
    }
}

// MARK: - Code Block Style
struct LuxuryCodeBlockStyle: StructuredText.CodeBlockStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("SFMono-Regular", size: 14))
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .textual.blockSpacing(StructuredText.BlockSpacing(top: 8, bottom: 8))
    }
}

// MARK: - List Item Style
struct LuxuryListItemStyle: StructuredText.ListItemStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            configuration.marker
            configuration.block
        }
        .textual.blockSpacing(StructuredText.BlockSpacing(top: 4, bottom: 4))
    }
}

// MARK: - Extension for convenience
extension StructuredText.Style where Self == LuxuryTextualStyle {
    static var luxury: LuxuryTextualStyle {
        LuxuryTextualStyle()
    }
}
