import SwiftUI
import UserNotifications

/// Raycast-inspired Settings interface with liquid glass aesthetic
struct SettingsView: View {
    @State private var selectedSection: SettingsSection = .general
    @State private var notificationsEnabled: Bool = DataStore.shared.loadNotificationsEnabled()
    @State private var refreshInterval: Double = DataStore.shared.loadRefreshInterval()
    @State private var autoStartSessionEnabled: Bool = DataStore.shared.loadAutoStartSessionEnabled()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(spacing: 0) {
                // App header
                HStack(spacing: 10) {
                    Image("HeaderLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)

                    Text("Settings")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

                Divider()
                    .opacity(0.5)
                    .padding(.horizontal, 12)

                // Navigation items
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(SettingsSection.allCases, id: \.self) { section in
                            SidebarItem(
                                section: section,
                                isSelected: selectedSection == section,
                                action: { selectedSection = section }
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                }
            }
            .background(Color.black.opacity(colorScheme == .dark ? 0.2 : 0.02))
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 220)
        } detail: {
            // Content
            ScrollView {
                VStack(spacing: 0) {
                    // Section Header
                    SectionHeader(section: selectedSection)

                    // Section Content
                    contentView(for: selectedSection)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                ZStack {
                    Color(nsColor: .windowBackgroundColor)
                    Color.black.opacity(colorScheme == .dark ? 0.15 : 0)
                }
            )
        }
        .frame(width: 740, height: 520)
    }

    @ViewBuilder
    private func contentView(for section: SettingsSection) -> some View {
        switch section {
        case .general:
            GeneralSettingsView(refreshInterval: $refreshInterval)
        case .appearance:
            AppearanceSettingsView()
        case .notifications:
            NotificationsSettingsView(notificationsEnabled: $notificationsEnabled)
        case .session:
            SessionManagementView(autoStartSessionEnabled: $autoStartSessionEnabled)
        case .claudeCode:
            ClaudeCodeView()
        case .api:
            APIBillingView()
        case .about:
            AboutView()
        }
    }
}

// MARK: - Settings Sections

enum SettingsSection: String, CaseIterable {
    case general = "General"
    case appearance = "Appearance"
    case notifications = "Notifications"
    case session = "Sessions"
    case claudeCode = "Claude Code"
    case api = "API"
    case about = "About"

    var icon: String {
        switch self {
        case .general: return "gearshape.fill"
        case .appearance: return "paintbrush.fill"
        case .notifications: return "bell.fill"
        case .session: return "clock.arrow.circlepath"
        case .claudeCode: return "terminal.fill"
        case .api: return "server.rack"
        case .about: return "info.circle.fill"
        }
    }

    var description: String {
        switch self {
        case .general: return "App behavior and preferences"
        case .appearance: return "Menu bar customization"
        case .notifications: return "Alerts and thresholds"
        case .session: return "Automatic session management"
        case .claudeCode: return "Terminal statusline integration"
        case .api: return "API Console billing & credits"
        case .about: return "Version and info"
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .general: return SettingsColors.gradient(Color.gray, dark: Color.gray.opacity(0.7))
        case .appearance: return SettingsColors.purpleGradient
        case .notifications: return SettingsColors.redGradient
        case .session: return SettingsColors.blueGradient
        case .claudeCode: return SettingsColors.greenGradient
        case .api: return SettingsColors.orangeGradient
        case .about: return SettingsColors.cyanGradient
        }
    }

    var color: Color {
        switch self {
        case .general: return .gray
        case .appearance: return SettingsColors.accentPurple
        case .notifications: return SettingsColors.accentRed
        case .session: return SettingsColors.accentBlue
        case .claudeCode: return SettingsColors.accentGreen
        case .api: return SettingsColors.accentOrange
        case .about: return SettingsColors.accentCyan
        }
    }
}

// MARK: - Sidebar Item

struct SidebarItem: View {
    let section: SettingsSection
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // Icon with gradient
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(section.gradient)
                        .frame(width: 24, height: 24)

                    Image(systemName: section.icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text(section.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected
                            ? Color.white.opacity(colorScheme == .dark ? 0.1 : 0.8)
                            : (isHovered ? Color.white.opacity(colorScheme == .dark ? 0.05 : 0.4) : Color.clear)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3) : Color.clear,
                        lineWidth: 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let section: SettingsSection
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            // Icon badge with glow
            ZStack {
                // Glow effect
                RoundedRectangle(cornerRadius: 12)
                    .fill(section.gradient)
                    .frame(width: 44, height: 44)
                    .blur(radius: 12)
                    .opacity(0.4)

                // Icon badge
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(section.gradient)
                        .frame(width: 44, height: 44)

                    Image(systemName: section.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(section.rawValue)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Text(section.description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 14)
    }
}

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    var title: String? = nil
    let content: Content
    @Environment(\.colorScheme) var colorScheme

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = title {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.05 : 0.6))

                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.3), lineWidth: 0.5)
            }
        )
    }
}

// MARK: - Setting Row

struct SettingRow<Control: View>: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var iconColor: Color = .secondary
    let control: Control

    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        iconColor: Color = .secondary,
        @ViewBuilder control: () -> Control
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.control = control()
    }

    var body: some View {
        HStack(alignment: subtitle != nil ? .top : .center, spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
                    .frame(width: 20)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()

            control
        }
    }
}

// MARK: - Divider Row

struct SettingsDivider: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(colorScheme == .dark ? 0.06 : 0.3))
            .frame(height: 1)
            .padding(.vertical, 6)
    }
}
