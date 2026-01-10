import Foundation

struct ToolCall: Identifiable {
    let id: String
    var title: String
    var status: Status
    
    enum Status {
        case pending
        case inProgress
        case running
        case completed
        case failed
        case cancelled
    }
    
    init(id: String, title: String, status: Status = .running) {
        self.id = id
        self.title = title
        self.status = status
    }
}
