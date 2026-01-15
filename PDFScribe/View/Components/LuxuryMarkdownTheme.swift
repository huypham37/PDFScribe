import SwiftUI
import MarkdownUI

extension Theme {
    static var luxury: Theme {
        Theme()
            // Body text - Palatino
            .text {
                FontFamily(.custom("Palatino"))
                FontSize(17)
            }
            // Headings
            .heading1 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontFamily(.custom("Palatino"))
                        FontSize(32)
                        FontWeight(.bold)
                    }
                    .markdownMargin(top: 24, bottom: 16)
            }
            .heading2 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontFamily(.custom("Palatino"))
                        FontSize(26)
                        FontWeight(.bold)
                    }
                    .markdownMargin(top: 20, bottom: 12)
            }
            .heading3 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontFamily(.custom("Palatino"))
                        FontSize(21)
                        FontWeight(.semibold)
                    }
                    .markdownMargin(top: 16, bottom: 10)
            }
            .heading4 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontFamily(.custom("Palatino"))
                        FontSize(19)
                        FontWeight(.semibold)
                    }
                    .markdownMargin(top: 12, bottom: 8)
            }
            // Inline code - pill style
            .code {
                FontFamily(.custom("SFMono-Regular"))
                FontSize(15)
                BackgroundColor(Color(nsColor: .controlBackgroundColor))
            }
            // Code blocks
            .codeBlock { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontFamily(.custom("SFMono-Regular"))
                        FontSize(14)
                    }
                    .padding(16)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .markdownMargin(top: 8, bottom: 8)
            }
            // Paragraphs - more breathing room
            .paragraph { configuration in
                configuration.label
                    .markdownMargin(top: 0, bottom: 16)
            }
            // Lists - generous spacing between items for premium feel
            .listItem { configuration in
                configuration.label
                    .markdownMargin(top: 8, bottom: 8)
            }
            // Blockquotes
            .blockquote { configuration in
                configuration.label
                    .padding(.leading, 16)
                    .padding(.vertical, 8)
                    .overlay(
                        Rectangle()
                            .fill(Color.brandPrimary.opacity(0.3))
                            .frame(width: 4),
                        alignment: .leading
                    )
                    .markdownMargin(top: 8, bottom: 8)
            }
            // Links
            .link {
                ForegroundColor(.brandPrimary)
            }
            // Strong/Bold
            .strong {
                FontWeight(.semibold)
            }
            // Emphasis/Italic
            .emphasis {
                FontStyle(.italic)
            }
            // Images
            .image { configuration in
                configuration.label
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .markdownMargin(top: 12, bottom: 12)
            }
    }
}
