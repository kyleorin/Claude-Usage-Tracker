import SwiftUI

/// Raycast-inspired color palette with vibrant accents and glass effects
enum SettingsColors {
    // MARK: - Accent Colors (Vibrant gradients)
    static let accent = Color.accentColor

    static let accentGreen = Color(red: 0.34, green: 0.80, blue: 0.50)
    static let accentGreenDark = Color(red: 0.24, green: 0.65, blue: 0.40)

    static let accentBlue = Color(red: 0.40, green: 0.60, blue: 0.95)
    static let accentBlueDark = Color(red: 0.30, green: 0.50, blue: 0.85)

    static let accentPurple = Color(red: 0.60, green: 0.40, blue: 0.90)
    static let accentPurpleDark = Color(red: 0.50, green: 0.30, blue: 0.80)

    static let accentOrange = Color(red: 1.0, green: 0.60, blue: 0.30)
    static let accentOrangeDark = Color(red: 0.95, green: 0.50, blue: 0.20)

    static let accentRed = Color(red: 1.0, green: 0.40, blue: 0.40)
    static let accentRedDark = Color(red: 0.90, green: 0.30, blue: 0.30)

    static let accentCyan = Color(red: 0.30, green: 0.80, blue: 0.90)
    static let accentCyanDark = Color(red: 0.20, green: 0.70, blue: 0.80)

    static let accentPink = Color(red: 0.95, green: 0.45, blue: 0.65)
    static let accentPinkDark = Color(red: 0.85, green: 0.35, blue: 0.55)

    // MARK: - Glass Surfaces
    static let glassLight = Color.white.opacity(0.06)
    static let glassMedium = Color.white.opacity(0.10)
    static let glassStrong = Color.white.opacity(0.15)
    static let glassBorder = Color.white.opacity(0.08)
    static let glassBorderStrong = Color.white.opacity(0.12)

    // MARK: - Dark overlay
    static let darkOverlay = Color.black.opacity(0.25)
    static let darkOverlayLight = Color.black.opacity(0.15)

    // MARK: - Status
    static let success = Color(red: 0.34, green: 0.80, blue: 0.50)
    static let warning = Color(red: 1.0, green: 0.75, blue: 0.30)
    static let error = Color(red: 1.0, green: 0.40, blue: 0.40)
    static let info = Color(red: 0.40, green: 0.60, blue: 0.95)

    // MARK: - UI Elements
    static let primary = Color.accentColor
    static let cardBackground = Color(nsColor: .controlBackgroundColor)
    static let inputBackground = Color(nsColor: .textBackgroundColor)
    static let border = Color.primary.opacity(0.1)

    // MARK: - Badges
    static let betaBadge = Color.orange
    static let proBadge = Color.purple
    static let newBadge = Color.blue

    // MARK: - Helper Functions
    static func lightOverlay(_ color: Color, opacity: Double) -> Color {
        color.opacity(opacity)
    }

    static func borderColor(_ color: Color, opacity: Double) -> Color {
        color.opacity(opacity)
    }

    // MARK: - Gradient Presets
    static func gradient(_ base: Color, dark: Color) -> LinearGradient {
        LinearGradient(
            colors: [base, dark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var greenGradient: LinearGradient {
        gradient(accentGreen, dark: accentGreenDark)
    }

    static var blueGradient: LinearGradient {
        gradient(accentBlue, dark: accentBlueDark)
    }

    static var purpleGradient: LinearGradient {
        gradient(accentPurple, dark: accentPurpleDark)
    }

    static var orangeGradient: LinearGradient {
        gradient(accentOrange, dark: accentOrangeDark)
    }

    static var redGradient: LinearGradient {
        gradient(accentRed, dark: accentRedDark)
    }

    static var cyanGradient: LinearGradient {
        gradient(accentCyan, dark: accentCyanDark)
    }
}

// MARK: - Glass Card Modifier

struct RaycastGlassCard: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.white.opacity(colorScheme == .dark ? 0.05 : 0.6))

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.3), lineWidth: 0.5)
                }
            )
    }
}

// MARK: - Icon Badge

struct IconBadge: View {
    let icon: String
    let gradient: LinearGradient
    var size: CGFloat = 28

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.25)
                .fill(gradient)
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)

            Image(systemName: icon)
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Glow Effect

struct GlowEffect: ViewModifier {
    let color: Color
    var radius: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.4), radius: radius)
    }
}

extension View {
    func raycastCard(cornerRadius: CGFloat = 12) -> some View {
        modifier(RaycastGlassCard(cornerRadius: cornerRadius))
    }

    func glow(_ color: Color, radius: CGFloat = 8) -> some View {
        modifier(GlowEffect(color: color, radius: radius))
    }
}
