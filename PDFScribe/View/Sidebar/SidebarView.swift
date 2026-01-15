import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedMenu: MenuItem = .home
    
    enum MenuItem: String, CaseIterable {
        case home = "Home"
        case discover = "Discover"
        case spaces = "Spaces"
        case library = "Library"
        
        var icon: String {
            switch self {
            case .home: return "magnifyingglass"
            case .discover: return "globe"
            case .spaces: return "square.grid.2x2"
            case .library: return "books.vertical"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                // Logo and toggle
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                        Text("PDFScribe")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "sidebar.left")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                // New Thread button
                Button(action: {
                    appViewModel.createNewSession()
                }) {
                    Text("New Thread")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .glassEffect(in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            
            Divider()
            
            // Navigation menu
            VStack(spacing: 4) {
                ForEach(MenuItem.allCases, id: \.self) { item in
                    MenuItemView(
                        icon: item.icon,
                        title: item.rawValue,
                        isSelected: selectedMenu == item
                    ) {
                        selectedMenu = item
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            
            // History section
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(appViewModel.recentSessions.prefix(10)) { session in
                        HistoryItemView(session: session) {
                            appViewModel.selectSession(session)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
            }
            
            Spacer()
            
            Divider()
            
            // Footer
            VStack(spacing: 12) {
                Button(action: {}) {
                    HStack(spacing: 8) {
                        Image(systemName: "command")
                            .font(.system(size: 12))
                        Text("Shortcuts")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                
                // User profile
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color("SlateIndigo"))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text("U")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        )
                    
                    Text("User")
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "creditcard")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {}) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
    }
}

struct MenuItemView: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .frame(width: 16)
                Text(title)
                    .font(.system(size: 13))
                Spacer()
            }
            .foregroundColor(isSelected ? .primary : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

struct HistoryItemView: View {
    let session: ChatSession
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(session.title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}
