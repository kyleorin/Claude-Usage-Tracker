import SwiftUI
import UserNotifications

/// Modern native macOS Settings interface with liquid glass aesthetic
struct SettingsView: View {
    @State private var selectedSection: SettingsSection = .general
    @State private var notificationsEnabled: Bool = DataStore.shared.loadNotificationsEnabled()
    @State private var refreshInterval: Double = DataStore.shared.loadRefreshInterval()
    @State private var autoStartSessionEnabled: Bool = DataStore.shared.loadAutoStartSessionEnabled()

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(SettingsSection.allCases, id: \.self, selection: $selectedSection) { section in
                SidebarRow(section: section)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            // Content
            ScrollView {
                VStack(spacing: 0) {
                    // Section Header
                    SectionHeader(section: selectedSection)

                    // Section Content
                    contentView(for: selectedSection)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 28)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(width: 760, height: 540)
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
        case .general: return "gearshape"
        case .appearance: return "paintbrush"
        case .notifications: return "bell"
        case .session: return "clock.arrow.circlepath"
        case .claudeCode: return "terminal"
        case .api: return "server.rack"
        case .about: return "info.circle"
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
        case .about: return "Version and credits"
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
        case .about: return .secondary
        }
    }
}

// MARK: - Sidebar Row

struct SidebarRow: View {
    let section: SettingsSection

    var body: some View {
        Label {
            Text(section.rawValue)
                .font(.system(size: 13))
        } icon: {
            Image(systemName: section.icon)
                .font(.system(size: 13))
                .foregroundStyle(section.color)
        }
        .tag(section)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let section: SettingsSection

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(section.color.opacity(0.12))
                        .frame(width: 42, height: 42)

                    Image(systemName: section.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(section.color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(section.rawValue)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)

                    Text(section.description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }
}

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    var title: String? = nil
    let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title = title {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }

            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.05), lineWidth: 0.5)
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
    var body: some View {
        Divider()
            .padding(.vertical, 6)
    }
}
