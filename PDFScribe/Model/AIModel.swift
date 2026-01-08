import Foundation

struct AIModel: Identifiable, Equatable {
    let id: String
    let name: String
    let provider: AIProvider
    
    static func == (lhs: AIModel, rhs: AIModel) -> Bool {
        lhs.id == rhs.id
    }
}

struct AIMode: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String?
    
    static func == (lhs: AIMode, rhs: AIMode) -> Bool {
        lhs.id == rhs.id
    }
}
