import SwiftUI

enum PortalTheme {
    static let background = Color(red: 0.965, green: 0.966, blue: 0.94)
    static let surface = Color.white
    static let groupedSurface = Color(red: 0.985, green: 0.985, blue: 0.972)
    static let primaryText = Color(red: 0.05, green: 0.05, blue: 0.045)
    static let secondaryText = Color(red: 0.45, green: 0.45, blue: 0.40)
    static let border = Color(red: 0.86, green: 0.86, blue: 0.82)
    static let accent = Color(red: 0.09, green: 0.11, blue: 0.10)
    static let positive = Color(red: 0.14, green: 0.48, blue: 0.30)
    static let warning = Color(red: 0.74, green: 0.47, blue: 0.12)

    static func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(surface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(border, lineWidth: 1)
            )
    }
}

struct Pill: View {
    let title: String
    var systemImage: String?

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(title)
        }
        .font(.caption.weight(.medium))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(PortalTheme.groupedSurface)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(PortalTheme.border, lineWidth: 1))
    }
}

