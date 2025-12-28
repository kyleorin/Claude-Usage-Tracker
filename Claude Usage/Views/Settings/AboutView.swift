import SwiftUI

/// Clean About page with app information
struct AboutView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        VStack(spacing: 20) {
            // App Info Card
            GlassCard {
                VStack(spacing: 16) {
                    // Logo and Version
                    HStack(spacing: 16) {
                        Image("AboutLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 56, height: 56)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("ClaudeUsage")
                                .font(.system(size: 20, weight: .semibold))

                            Text("Version \(appVersion)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }

                    Divider()

                    // Description
                    Text("A native macOS app for monitoring your Claude AI usage limits. Track your 5-hour session window and weekly limits in real-time from your menu bar.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Links Card
            GlassCard(title: "Resources") {
                VStack(spacing: 0) {
                    AboutLink(
                        title: "Claude Status",
                        subtitle: "Check system status",
                        icon: "bolt.horizontal",
                        url: "https://status.claude.com"
                    )

                    Divider().padding(.vertical, 8)

                    AboutLink(
                        title: "Anthropic",
                        subtitle: "Learn more about Claude",
                        icon: "sparkles",
                        url: "https://www.anthropic.com"
                    )
                }
            }

            // Info Card
            GlassCard(title: "Info") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("License")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("MIT")
                            .font(.system(size: 12, weight: .medium))
                    }

                    HStack {
                        Text("Platform")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("macOS 13+")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
            }

            Spacer()
        }
    }
}

// MARK: - About Link

struct AboutLink: View {
    let title: String
    let subtitle: String
    let icon: String
    let url: String

    @State private var isHovered = false

    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                NSWorkspace.shared.open(url)
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(SettingsColors.accentBlue)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .opacity(isHovered ? 0.7 : 1)
    }
}
