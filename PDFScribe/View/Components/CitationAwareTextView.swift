import SwiftUI
import AppKit

/// A view that renders markdown text with styled citation pills
/// Citations [N] are displayed as pill-shaped badges that link to sources
struct CitationAwareTextView: View {
    let markdown: String
    let citations: CitationContext
    let onCitationTap: ((Int) -> Void)?
    
    init(markdown: String, citations: CitationContext = CitationContext(), onCitationTap: ((Int) -> Void)? = nil) {
        self.markdown = markdown
        self.citations = citations
        self.onCitationTap = onCitationTap
    }
    
    var body: some View {
        CitationTextViewRepresentable(
            markdown: markdown,
            citations: citations,
            onCitationTap: onCitationTap
        )
    }
}

// MARK: - NSViewRepresentable

private struct CitationTextViewRepresentable: NSViewRepresentable {
    let markdown: String
    let citations: CitationContext
    let onCitationTap: ((Int) -> Void)?
    
    func makeNSView(context: Context) -> CitationNSTextView {
        let textView = CitationNSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainerInset = .zero
        textView.delegate = context.coordinator
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        context.coordinator.textView = textView
        updateContent(textView)
        
        return textView
    }
    
    func updateNSView(_ textView: CitationNSTextView, context: Context) {
        updateContent(textView)
    }
    
    private func updateContent(_ textView: CitationNSTextView) {
        let attributedString = buildAttributedString()
        textView.textStorage?.setAttributedString(attributedString)
        textView.invalidateIntrinsicContentSize()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onCitationTap: onCitationTap, citations: citations)
    }
    
    // MARK: - Attributed String Builder
    
    private func buildAttributedString() -> NSAttributedString {
        let cleaned = cleanMarkdown(markdown)
        let result = NSMutableAttributedString()
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.paragraphSpacing = 8
        
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Palatino", size: 17) ?? NSFont.systemFont(ofSize: 17),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle
        ]
        
        let blocks = parseMarkdownBlocks(cleaned)
        
        for (index, block) in blocks.enumerated() {
            let isLastBlock = index == blocks.count - 1
            let blockString = processBlock(block, baseAttributes: baseAttributes, isLastBlock: isLastBlock)
            result.append(blockString)
        }
        
        return result
    }
    
    private func cleanMarkdown(_ text: String) -> String {
        let lines = text.components(separatedBy: "\n")
        let filtered = lines.filter { line in
            let pattern = #"^\s*\[\d+\]:\s*"#
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return true }
            let range = NSRange(location: 0, length: line.utf16.count)
            return regex.firstMatch(in: line, range: range) == nil
        }
        return filtered.joined(separator: "\n")
    }
    
    // MARK: - Markdown Block Parsing
    
    private enum MarkdownBlock {
        case paragraph(String)
        case header(level: Int, text: String)
        case bulletList([String])
        case numberedList([String])
        case codeBlock(String)
    }
    
    private func parseMarkdownBlocks(_ text: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = text.components(separatedBy: "\n")
        var currentParagraph: [String] = []
        var currentBulletList: [String] = []
        var currentNumberedList: [String] = []
        var inCodeBlock = false
        var codeBlockContent: [String] = []
        
        func flushParagraph() {
            if !currentParagraph.isEmpty {
                let text = currentParagraph.joined(separator: " ").trimmingCharacters(in: .whitespaces)
                if !text.isEmpty {
                    blocks.append(.paragraph(text))
                }
                currentParagraph = []
            }
        }
        
        func flushBulletList() {
            if !currentBulletList.isEmpty {
                blocks.append(.bulletList(currentBulletList))
                currentBulletList = []
            }
        }
        
        func flushNumberedList() {
            if !currentNumberedList.isEmpty {
                blocks.append(.numberedList(currentNumberedList))
                currentNumberedList = []
            }
        }
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasPrefix("```") {
                if inCodeBlock {
                    blocks.append(.codeBlock(codeBlockContent.joined(separator: "\n")))
                    codeBlockContent = []
                    inCodeBlock = false
                } else {
                    flushParagraph()
                    flushBulletList()
                    flushNumberedList()
                    inCodeBlock = true
                }
                continue
            }
            
            if inCodeBlock {
                codeBlockContent.append(line)
                continue
            }
            
            if let match = trimmed.range(of: #"^(#{1,6})\s+(.+)$"#, options: .regularExpression) {
                flushParagraph()
                flushBulletList()
                flushNumberedList()
                let headerMatch = trimmed[match]
                let level = headerMatch.prefix(while: { $0 == "#" }).count
                let text = String(trimmed.dropFirst(level).trimmingCharacters(in: .whitespaces))
                print("🎯 Found header level \(level): '\(text)'")
                blocks.append(.header(level: level, text: text))
                continue
            }
            
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("• ") {
                flushParagraph()
                flushNumberedList()
                let itemText = String(trimmed.dropFirst(2))
                currentBulletList.append(itemText)
                continue
            }
            
            if let match = trimmed.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
                flushParagraph()
                flushBulletList()
                let itemText = String(trimmed[match.upperBound...])
                currentNumberedList.append(itemText)
                continue
            }
            
            if trimmed.isEmpty {
                flushParagraph()
                flushBulletList()
                flushNumberedList()
                continue
            }
            
            flushBulletList()
            flushNumberedList()
            currentParagraph.append(trimmed)
        }
        
        flushParagraph()
        flushBulletList()
        flushNumberedList()
        
        return blocks
    }
    
    // MARK: - Block Processing
    
    private func processBlock(_ block: MarkdownBlock, baseAttributes: [NSAttributedString.Key: Any], isLastBlock: Bool = false) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        switch block {
        case .paragraph(let text):
            result.append(processInlineFormatting(text, baseAttributes: baseAttributes))
            if !isLastBlock {
                result.append(NSAttributedString(string: "\n"))
            }
            
        case .header(let level, let text):
            var headerAttributes = baseAttributes
            let fontSize: CGFloat = level == 1 ? 24 : (level == 2 ? 20 : 17)
            headerAttributes[.font] = NSFont(name: "Charter-Bold", size: fontSize) ?? NSFont.boldSystemFont(ofSize: fontSize)
            result.append(processInlineFormatting(text, baseAttributes: headerAttributes))
            if !isLastBlock {
                result.append(NSAttributedString(string: "\n"))
            }
            
        case .bulletList(let items):
            for item in items {
                var itemAttributes = baseAttributes
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 4
                paragraphStyle.paragraphSpacing = 6
                paragraphStyle.headIndent = 20
                paragraphStyle.firstLineHeadIndent = 0
                itemAttributes[.paragraphStyle] = paragraphStyle
                
                result.append(NSAttributedString(string: "•  ", attributes: itemAttributes))
                result.append(processInlineFormatting(item, baseAttributes: itemAttributes))
                result.append(NSAttributedString(string: "\n"))
            }
            if !isLastBlock {
                result.append(NSAttributedString(string: "\n"))
            }
            
        case .numberedList(let items):
            for (index, item) in items.enumerated() {
                var itemAttributes = baseAttributes
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 4
                paragraphStyle.paragraphSpacing = 6
                paragraphStyle.headIndent = 24
                paragraphStyle.firstLineHeadIndent = 0
                itemAttributes[.paragraphStyle] = paragraphStyle
                
                result.append(NSAttributedString(string: "\(index + 1). ", attributes: itemAttributes))
                result.append(processInlineFormatting(item, baseAttributes: itemAttributes))
                result.append(NSAttributedString(string: "\n"))
            }
            if !isLastBlock {
                result.append(NSAttributedString(string: "\n"))
            }
            
        case .codeBlock(let code):
            var codeAttributes = baseAttributes
            codeAttributes[.font] = NSFont(name: "SFMono-Regular", size: 14) ?? NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
            codeAttributes[.backgroundColor] = NSColor.quaternaryLabelColor.withAlphaComponent(0.3)
            result.append(NSAttributedString(string: code, attributes: codeAttributes))
            if !isLastBlock {
                result.append(NSAttributedString(string: "\n\n"))
            }
        }
        
        return result
    }
    
    // MARK: - Inline Formatting
    
    private func processInlineFormatting(_ text: String, baseAttributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let result = NSMutableAttributedString()
        var currentIndex = text.startIndex
        
        let patterns: [(pattern: String, type: InlineType)] = [
            (#"\[(\d+)\]"#, .citation),
            (#"\*\*(.+?)\*\*"#, .bold),
            (#"\*(.+?)\*"#, .italic),
            (#"`(.+?)`"#, .code)
        ]
        
        var allMatches: [(range: Range<String.Index>, type: InlineType, content: String)] = []
        
        for (pattern, type) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let nsRange = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, range: nsRange)
            
            for match in matches {
                guard let matchRange = Range(match.range, in: text),
                      let contentRange = Range(match.range(at: 1), in: text) else { continue }
                let content = String(text[contentRange])
                allMatches.append((matchRange, type, content))
            }
        }
        
        allMatches.sort { $0.range.lowerBound < $1.range.lowerBound }
        
        // Filter overlapping matches (keep first one)
        var filteredMatches: [(range: Range<String.Index>, type: InlineType, content: String)] = []
        var lastEnd: String.Index? = nil
        for match in allMatches {
            if let end = lastEnd, match.range.lowerBound < end {
                continue // Skip overlapping match
            }
            filteredMatches.append(match)
            lastEnd = match.range.upperBound
        }
        
        for match in filteredMatches {
            if currentIndex < match.range.lowerBound {
                let plainText = String(text[currentIndex..<match.range.lowerBound])
                result.append(NSAttributedString(string: plainText, attributes: baseAttributes))
            }
            
            switch match.type {
            case .citation:
                if let number = Int(match.content) {
                    result.append(createCitationPill(number: number, baseAttributes: baseAttributes))
                }
            case .bold:
                var boldAttributes = baseAttributes
                if let font = baseAttributes[.font] as? NSFont {
                    boldAttributes[.font] = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
                }
                result.append(NSAttributedString(string: match.content, attributes: boldAttributes))
            case .italic:
                var italicAttributes = baseAttributes
                if let font = baseAttributes[.font] as? NSFont {
                    italicAttributes[.font] = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
                }
                result.append(NSAttributedString(string: match.content, attributes: italicAttributes))
            case .code:
                var codeAttributes = baseAttributes
                codeAttributes[.font] = NSFont(name: "SFMono-Regular", size: 15) ?? NSFont.monospacedSystemFont(ofSize: 15, weight: .regular)
                codeAttributes[.backgroundColor] = NSColor.quaternaryLabelColor.withAlphaComponent(0.3)
                result.append(NSAttributedString(string: match.content, attributes: codeAttributes))
            }
            
            currentIndex = match.range.upperBound
        }
        
        if currentIndex < text.endIndex {
            let remainingText = String(text[currentIndex...])
            result.append(NSAttributedString(string: remainingText, attributes: baseAttributes))
        }
        
        return result
    }
    
    private enum InlineType {
        case citation, bold, italic, code
    }
    
    // MARK: - Citation Pill
    
    private func createCitationPill(number: Int, baseAttributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        // Get citation info
        let citation = citations.citations[number]
        let displayText: String
        
        if let domain = citation?.sourceDomain {
            // Show domain like "ibm" or "github"
            let shortDomain = domain.replacingOccurrences(of: "www.", with: "")
                .components(separatedBy: ".").first ?? domain
            displayText = shortDomain
        } else {
            displayText = "\(number)"
        }
        
        // Create the pill image
        let pillImage = createPillImage(text: displayText, number: number)
        
        // Create attachment with the image
        let attachment = NSTextAttachment()
        attachment.image = pillImage
        
        // Adjust bounds for vertical alignment
        let font = baseAttributes[.font] as? NSFont ?? NSFont.systemFont(ofSize: 17)
        let midY = (font.capHeight - pillImage.size.height) / 2
        attachment.bounds = CGRect(
            x: 0,
            y: midY,
            width: pillImage.size.width,
            height: pillImage.size.height
        )
        
        let attachmentString = NSMutableAttributedString(attachment: attachment)
        
        // Add link attribute for click handling
        let url: URL
        if let sourceURL = citation?.sourceURL {
            url = URL(string: sourceURL) ?? URL(string: "citation://\(number)")!
        } else {
            url = URL(string: "citation://\(number)")!
        }
        attachmentString.addAttribute(.link, value: url, range: NSRange(location: 0, length: attachmentString.length))
        
        return attachmentString
    }
    
    private func createPillImage(text: String, number: Int) -> NSImage {
        let font = NSFont.systemFont(ofSize: 11, weight: .medium)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(calibratedRed: 0.25, green: 0.3, blue: 0.35, alpha: 1.0)
        ]
        
        let textSize = (text as NSString).size(withAttributes: textAttributes)
        let padding: CGFloat = 6
        let height: CGFloat = 18
        let width = textSize.width + padding * 2
        
        let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { rect in
            // Background pill
            let pillPath = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: 4, yRadius: 4)
            NSColor(calibratedRed: 0.92, green: 0.93, blue: 0.94, alpha: 1.0).setFill()
            pillPath.fill()
            
            // Text
            let textRect = CGRect(
                x: (rect.width - textSize.width) / 2,
                y: (rect.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            (text as NSString).draw(in: textRect, withAttributes: textAttributes)
            
            return true
        }
        
        return image
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, NSTextViewDelegate {
        let onCitationTap: ((Int) -> Void)?
        let citations: CitationContext
        weak var textView: CitationNSTextView?
        
        init(onCitationTap: ((Int) -> Void)?, citations: CitationContext) {
            self.onCitationTap = onCitationTap
            self.citations = citations
        }
        
        func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
            guard let url = link as? URL else { return false }
            
            if url.scheme == "citation" {
                if let number = Int(url.host ?? "") {
                    onCitationTap?(number)
                }
                return true
            }
            
            NSWorkspace.shared.open(url)
            return true
        }
    }
}

// MARK: - Custom NSTextView with intrinsic size

private class CitationNSTextView: NSTextView {
    override var intrinsicContentSize: NSSize {
        guard let layoutManager = layoutManager,
              let textContainer = textContainer else {
            return super.intrinsicContentSize
        }
        
        layoutManager.ensureLayout(for: textContainer)
        let usedRect = layoutManager.usedRect(for: textContainer)
        
        return NSSize(
            width: NSView.noIntrinsicMetric,
            height: usedRect.height + textContainerInset.height * 2
        )
    }
    
    override func didChangeText() {
        super.didChangeText()
        invalidateIntrinsicContentSize()
    }
}

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            CitationAwareTextView(
                markdown: """
                Climate models [1] have shown improved accuracy [2] over recent decades.
                
                **Key benefits:**
                - Instant responses [1]
                - No API costs [2]
                - Perfect for UI testing [3]
                
                ## Research Findings
                
                Recent studies have shown that mock testing significantly improves development speed.
                
                1. Faster iteration cycles
                2. Reduced API costs
                3. Better test coverage
                """,
                citations: CitationContext(),
                onCitationTap: { num in
                    print("Tapped citation \(num)")
                }
            )
        }
        .padding()
    }
    .frame(width: 500, height: 600)
}
