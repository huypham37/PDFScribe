import Foundation

struct ParsedMessage {
    enum Block: Identifiable {
        case text(String)
        case code(language: String?, code: String)
        
        var id: UUID { UUID() }
    }
    
    let blocks: [Block]
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
    
    private func extractCitations(from text: String, references: inout [String], referenceMap: inout [String: Int]) -> String {
        var processedText = text
        
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
                        references.append(url)
                        citationNumber = references.count
                        referenceMap[url] = citationNumber
                    }
                    
                    // Replace with citation
                    let replacement = linkText != nil ? "\(linkText!) [\(citationNumber)]" : "[\(citationNumber)]"
                    processedText.replaceSubrange(matchRange, with: replacement)
                }
            }
        }
        
        return processedText
    }
}
