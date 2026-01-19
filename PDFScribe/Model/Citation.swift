import Foundation

struct Citation: Identifiable, Hashable {
    let id: Int
    var sourceURL: String?
    var sourceTitle: String?
    var sourceDomain: String?
    var pageReference: String?
    var snippet: String?
    
    init(id: Int, sourceURL: String? = nil, sourceTitle: String? = nil, sourceDomain: String? = nil, pageReference: String? = nil, snippet: String? = nil) {
        self.id = id
        self.sourceURL = sourceURL
        self.sourceTitle = sourceTitle
        self.sourceDomain = sourceDomain
        self.pageReference = pageReference
        self.snippet = snippet
    }
}

struct CitationContext {
    var citations: [Int: Citation]
    var sourceOrder: [Int]
    
    init() {
        self.citations = [:]
        self.sourceOrder = []
    }
    
    init(citations: [Int: Citation], sourceOrder: [Int]) {
        self.citations = citations
        self.sourceOrder = sourceOrder
    }
    
    mutating func addCitation(_ citation: Citation) {
        citations[citation.id] = citation
        if !sourceOrder.contains(citation.id) {
            sourceOrder.append(citation.id)
        }
    }
    
    func getCitation(for id: Int) -> Citation? {
        return citations[id]
    }
}
