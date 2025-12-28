import SwiftUI

/// Modern macOS-native color palette
enum SettingsColors {
    // MARK: - Accent Colors
    static let accent = Color.accentColor
    static let accentGreen = Color(red: 0.28, green: 0.75, blue: 0.42)
    static let accentBlue = Color(red: 0.35, green: 0.55, blue: 0.85)
    static let accentPurple = Color(red: 0.55, green: 0.36, blue: 0.76)
    static let accentOrange = Color(red: 0.95, green: 0.55, blue: 0.25)
    static let accentRed = Color(red: 0.92, green: 0.34, blue: 0.34)

    // MARK: - Surfaces
    static let surfacePrimary = Color(nsColor: .windowBackgroundColor)
    static let surfaceSecondary = Color(nsColor: .controlBackgroundColor)
    static let surfaceTertiary = Color(nsColor: .underPageBackgroundColor)

    // MARK: - Glass Effects
    static let glassBackground = Color.white.opacity(0.05)
    static let glassBorder = Color.white.opacity(0.1)
    static let glassHighlight = Color.white.opacity(0.15)

    // MARK: - Text
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color.secondary.opacity(0.6)

    // MARK: - Status
    static let success = Color(red: 0.28, green: 0.75, blue: 0.42)
    static let warning = Color(red: 0.95, green: 0.68, blue: 0.25)
    static let error = Color(red: 0.92, green: 0.34, blue: 0.34)
    static let info = Color(red: 0.35, green: 0.55, blue: 0.85)

    // MARK: - Sidebar
    static let sidebarBackground = Color(nsColor: .controlBackgroundColor).opacity(0.5)
    static let sidebarSelected = Color.accentColor
    static let sidebarHover = Color.primary.opacity(0.05)
}

/// Glass-style view modifiers
struct GlassBackground: ViewModifier {
    var cornerRadius: CGFloat = 12
    var padding: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
    }
}

struct SoftShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
    }
}

extension View {
    func glassBackground(cornerRadius: CGFloat = 12, padding: CGFloat = 0) -> some View {
        modifier(GlassBackground(cornerRadius: cornerRadius, padding: padding))
    }

    func softShadow() -> some View {
        modifier(SoftShadow())
    }
}
