import SwiftUI

struct InlineCitationBadge: View {
    let number: Int
    let onTap: ((Int) -> Void)?
    
    @State private var isHovered = false
    
    var body: some View {
        Text("\(number)")
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(Color("BrandPrimary"))
            .frame(minWidth: 18, minHeight: 18)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(isHovered ? Color("BrandBackgroundSecondary") : Color("BrandBackground"))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color("BrandSecondary").opacity(0.3), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .onTapGesture {
                onTap?(number)
            }
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 4) {
            Text("Climate models")
            InlineCitationBadge(number: 1, onTap: { num in
                print("Tapped citation \(num)")
            })
            Text("have improved accuracy")
            InlineCitationBadge(number: 2, onTap: { num in
                print("Tapped citation \(num)")
            })
        }
        
        HStack(spacing: 4) {
            Text("Recent studies")
            InlineCitationBadge(number: 1, onTap: nil)
            InlineCitationBadge(number: 2, onTap: nil)
            InlineCitationBadge(number: 3, onTap: nil)
            Text("suggest improvements")
        }
    }
    .padding()
}
