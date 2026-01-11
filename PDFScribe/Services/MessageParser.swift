import Foundation

struct MarkdownSection: Identifiable {
    let id = UUID()
    let title: String?
    let content: String
    let level: Int
}

struct ParsedMessage {
    enum Block: Identifiable {
        case text(String)
        case code(language: String?, code: String)
        
        var id: UUID { UUID() }
    }
    
    let blocks: [Block]
    let references: [String]
}

struct StructuredMessage {
    let summary: String?
    let sections: [MarkdownSection]
    let references: [String]
}

class MessageParser {
    func parse(_ rawMessage: String) -> ParsedMessage {
        var references: [String] = []
        var referenceMap: [String: Int] = [:]
        
        // Pass 1: Split by code fences to separate code blocks from text
        let blocks = splitIntoBlocks(rawMessage)
        
        // Pass 2: Extract citations from text blocks
        let processedBlocks = blocks.map { block -> ParsedMessage.Block in
            switch block {
            case .text(let content):
                let processedText = extractCitations(from: content, references: &references, referenceMap: &referenceMap)
                return .text(processedText)
            case .code:
                return block
            }
        }
        
        return ParsedMessage(blocks: processedBlocks, references: references)
    }
    
    // MARK: - Section Parsing
    
    func parseIntoSections(_ rawMessage: String) -> StructuredMessage {
        var references: [String] = []
        var referenceMap: [String: Int] = [:]
        
        // Extract citations first
        let contentWithCitations = extractCitations(from: rawMessage, references: &references, referenceMap: &referenceMap)
        
        // Parse sections by ## headers
        let sections = splitIntoSections(contentWithCitations)
        
        // Separate summary from sections
        let summary: String?
        let namedSections: [MarkdownSection]
        
        if let firstSection = sections.first, firstSection.title == nil {
            summary = firstSection.content.trimmingCharacters(in: .whitespacesAndNewlines)
            namedSections = Array(sections.dropFirst())
        } else {
            summary = nil
            namedSections = sections
        }
        
        return StructuredMessage(
            summary: summary,
            sections: namedSections,
            references: references
        )
    }
    
    private func splitIntoSections(_ text: String) -> [MarkdownSection] {
        var sections: [MarkdownSection] = []
        
        // Pattern: Match ## or ### headers at start of line
        let pattern = "^(#{2,3})\\s+(.+)$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else {
            return [MarkdownSection(title: nil, content: text, level: 0)]
        }
        
        let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
        
        if matches.isEmpty {
            // No headers found - return entire text as single section
            return [MarkdownSection(title: nil, content: text, level: 0)]
        }
        
        var lastIndex = text.startIndex
        
        for (index, match) in matches.enumerated() {
            guard let matchRange = Range(match.range, in: text),
                  let levelRange = Range(match.range(at: 1), in: text),
                  let titleRange = Range(match.range(at: 2), in: text) else {
                continue
            }
            
            // Add content before this header as a section (summary if first)
            if matchRange.lowerBound > lastIndex {
                let content = String(text[lastIndex..<matchRange.lowerBound])
                if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    sections.append(MarkdownSection(title: nil, content: content, level: 0))
                }
            }
            
            // Extract header info
            let level = text[levelRange].count
            let title = String(text[titleRange])
            
            // Find content until next header or end
            let contentStart = text.index(after: matchRange.upperBound)
            let contentEnd: String.Index
            
            if index + 1 < matches.count, let nextMatchRange = Range(matches[index + 1].range, in: text) {
                contentEnd = nextMatchRange.lowerBound
            } else {
                contentEnd = text.endIndex
            }
            
            let content = String(text[contentStart..<contentEnd])
            sections.append(MarkdownSection(title: title, content: content, level: level))
            
            lastIndex = contentEnd
        }
        
        return sections
    }
    
    private func splitIntoBlocks(_ text: String) -> [ParsedMessage.Block] {
        var blocks: [ParsedMessage.Block] = []
        let pattern = "```([a-z]*)\n([\\s\\S]*?)```"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return [.text(text)]
        }
        
        let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
        var lastIndex = text.startIndex
        
        for match in matches {
            // Add text before code block
            if let matchRange = Range(match.range, in: text) {
                let beforeText = String(text[lastIndex..<matchRange.lowerBound])
                if !beforeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    blocks.append(.text(beforeText))
                }
                
                // Extract language and code
                let language: String? = {
                    if let langRange = Range(match.range(at: 1), in: text) {
                        let lang = String(text[langRange])
                        return lang.isEmpty ? nil : lang
                    }
                    return nil
                }()
                
                if let codeRange = Range(match.range(at: 2), in: text) {
                    let code = String(text[codeRange])
                    blocks.append(.code(language: language, code: code))
                }
                
                lastIndex = matchRange.upperBound
            }
        }
        
        // Add remaining text after last code block
        if lastIndex < text.endIndex {
            let remainingText = String(text[lastIndex...])
            if !remainingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                blocks.append(.text(remainingText))
            }
        }
        
        // If no code blocks found, return entire text as single block
        if blocks.isEmpty {
            blocks.append(.text(text))
        }
        
        return blocks
    }
    
    private func convertMarkdownHeaders(_ text: String) -> String {
        var result = text
        
        // Convert ### headers to bold (SwiftUI Text doesn't support ### syntax)
        // Match: ### Header Text at start of line
        let headerPattern = "^(#{1,6})\\s+(.+)$"
        guard let regex = try? NSRegularExpression(pattern: headerPattern, options: [.anchorsMatchLines]) else {
            return result
        }
        
        let matches = regex.matches(in: result, options: [], range: NSRange(result.startIndex..., in: result))
        for match in matches.reversed() {
            if let _ = Range(match.range(at: 1), in: result),
               let textRange = Range(match.range(at: 2), in: result),
               let fullRange = Range(match.range, in: result) {
                let headerText = String(result[textRange])
                // Replace with bold markdown syntax that SwiftUI Text supports
                result.replaceSubrange(fullRange, with: "**\(headerText)**")
            }
        }
        
        return result
    }
    
    private func extractCitations(from text: String, references: inout [String], referenceMap: inout [String: Int]) -> String {
        var processedText = convertMarkdownHeaders(text)
        
        // Pattern to match markdown links: [text](url) or bare URLs
        let patterns = [
            "\\[([^\\]]+)\\]\\((https?://[^\\)]+)\\)",  // [text](url)
            "(https?://[^\\s\\)\\]]+)"                    // bare url
        ]
        
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { continue }
            
            // Process matches in reverse to maintain string indices
            let matches = regex.matches(in: processedText, options: [], range: NSRange(processedText.startIndex..., in: processedText))
            
            for match in matches.reversed() {
                if let matchRange = Range(match.range, in: processedText) {
                    let url: String
                    let linkText: String?
                    
                    if match.numberOfRanges == 3 {
                        // [text](url) format
                        if let urlRange = Range(match.range(at: 2), in: processedText),
                           let textRange = Range(match.range(at: 1), in: processedText) {
                            url = String(processedText[urlRange])
                            linkText = String(processedText[textRange])
                        } else {
                            continue
                        }
                    } else {
                        // Bare URL format
                        url = String(processedText[matchRange])
                        linkText = nil
                    }
                    
                    // Get or create citation number
                    let citationNumber: Int
                    if let existing = referenceMap[url] {
                        citationNumber = existing
                    } else {
                        citationNumber = references.count + 1  // Fix: Start at [1], not [0]
                        references.append(url)
                        referenceMap[url] = citationNumber
                    }
                    
                    // Replace with citation
                    // Add leading space for bare URLs to prevent text concatenation
                    let replacement = linkText != nil ? "\(linkText!) [\(citationNumber)]" : " [\(citationNumber)]"
                    processedText.replaceSubrange(matchRange, with: replacement)
                }
            }
        }
        
        return processedText
    }
}
