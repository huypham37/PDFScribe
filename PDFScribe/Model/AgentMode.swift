import SwiftUI

/// OpenCode agent modes for chat
enum AgentMode: Hashable, Identifiable {
    case build
    case plan
    case explore
    case custom(id: String, name: String, description: String)
    
    var id: String {
        switch self {
        case .build: return "build"
        case .plan: return "plan"
        case .explore: return "explore"
        case .custom(let id, _, _): return id
        }
    }
    
    var rawValue: String {
        switch self {
        case .build: return "Build"
        case .plan: return "Plan"
        case .explore: return "Explore"
        case .custom(_, let name, _): return name
        }
    }
    
    var icon: String {
        switch self {
        case .build:
            return "hammer.fill"
        case .plan:
            return "list.bullet.clipboard"
        case .explore:
            return "magnifyingglass"
        case .custom:
            return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .build:
            return .purple
        case .plan:
            return .blue
        case .explore:
            return .green
        case .custom:
            return .orange
        }
    }
    
    var description: String {
        switch self {
        case .build:
            return "Full permissions for coding and file modifications"
        case .plan:
            return "Read-only mode with planning capabilities"
        case .explore:
            return "Search and explore the codebase"
        case .custom(_, _, let description):
            return description
        }
    }
    
    /// OpenCode agent identifier
    var agentID: String {
        return id.lowercased()
    }
}
