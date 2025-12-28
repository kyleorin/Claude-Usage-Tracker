import SwiftUI
import UserNotifications

/// Clean Raycast-style Settings interface
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
                // Navigation items
                ScrollView {
                    VStack(spacing: 1) {
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
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 200)
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
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(width: 680, height: 480)
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
        case .session: return "clock"
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
        case .about: return "Version and info"
        }
    }
}

// MARK: - Sidebar Item (Raycast style - monochrome)

struct SidebarItem: View {
    let section: SettingsSection
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: section.icon)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .frame(width: 18)

                Text(section.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        isSelected
                            ? Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.08)
                            : (isHovered ? Color.primary.opacity(0.04) : Color.clear)
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

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: section.icon)
                .font(.system(size: 18))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(section.rawValue)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                Text(section.description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 12)
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
        VStack(alignment: .leading, spacing: 10) {
            if let title = title {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }

            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }
}

// MARK: - Setting Row

struct SettingRow<Control: View>: View {
    let title: String
    var subtitle: String? = nil
    let control: Control

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder control: () -> Control
    ) {
        self.title = title
        self.subtitle = subtitle
        self.control = control()
    }

    var body: some View {
        HStack(alignment: subtitle != nil ? .top : .center, spacing: 12) {
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
            .padding(.vertical, 4)
    }
}
