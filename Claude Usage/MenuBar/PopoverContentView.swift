import SwiftUI

/// Raycast-inspired liquid glass popover interface
struct PopoverContentView: View {
    @ObservedObject var manager: MenuBarManager
    let onRefresh: () -> Void
    let onPreferences: () -> Void
    let onQuit: () -> Void

    @State private var isRefreshing = false
    @State private var lastRefreshTime = Date()
    @State private var isCompact: Bool = DataStore.shared.loadCompactPopover()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Header
            PopoverHeader()
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
                .padding(.horizontal, 16)

            // Content - Card or Compact mode
            if isCompact {
                compactContent
            } else {
                cardContent
            }

            // Footer
            PopoverFooter(
                lastRefreshTime: lastRefreshTime,
                isRefreshing: isRefreshing,
                onRefresh: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isRefreshing = true
                    }
                    onRefresh()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isRefreshing = false
                            lastRefreshTime = Date()
                        }
                    }
                },
                onSettings: onPreferences,
                onQuit: onQuit
            )
        }
        .frame(width: isCompact ? 260 : 300)
        .background(
            ZStack {
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05)
            }
        )
        .onReceive(NotificationCenter.default.publisher(for: .popoverStyleChanged)) { _ in
            isCompact = DataStore.shared.loadCompactPopover()
        }
    }

    // MARK: - Card Mode Content
    private var cardContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                // Current Session
                MetricCard(
                    icon: "clock.fill",
                    title: "Current Session",
                    percentage: manager.usage.sessionPercentage,
                    resetTime: manager.usage.sessionResetTime,
                    subtitle: "5-hour window"
                )

                // Weekly Usage
                MetricCard(
                    icon: "calendar",
                    title: "Weekly Usage",
                    percentage: manager.usage.weeklyPercentage,
                    resetTime: manager.usage.weeklyResetTime,
                    subtitle: "7-day limit"
                )

                // Sonnet Weekly (if applicable)
                if manager.usage.opusWeeklyTokensUsed > 0 || manager.usage.opusWeeklyPercentage > 0 {
                    MetricCard(
                        icon: "sparkles",
                        title: "Sonnet Weekly",
                        percentage: manager.usage.opusWeeklyPercentage,
                        resetTime: manager.usage.weeklyResetTime,
                        subtitle: "Model limit"
                    )
                }

                // Extra Usage (if applicable)
                if let used = manager.usage.costUsed, let limit = manager.usage.costLimit, limit > 0 {
                    MetricCard(
                        icon: "dollarsign.circle.fill",
                        title: "Extra Usage",
                        percentage: (used / limit) * 100.0,
                        resetTime: nil,
                        subtitle: String(format: "$%.2f / $%.2f", used, limit)
                    )
                }

                // API Usage (if enabled)
                if let apiUsage = manager.apiUsage, DataStore.shared.loadAPITrackingEnabled() {
                    MetricCard(
                        icon: "server.rack",
                        title: "API Credits",
                        percentage: apiUsage.usagePercentage,
                        resetTime: nil,
                        subtitle: "\(apiUsage.formattedUsed) / \(apiUsage.formattedRemaining)"
                    )
                }
            }
            .padding(12)
        }
    }

    // MARK: - Compact Mode Content
    private var compactContent: some View {
        VStack(spacing: 0) {
            CompactMetricRow(
                title: "Session",
                percentage: manager.usage.sessionPercentage
            )

            CompactMetricRow(
                title: "Weekly",
                percentage: manager.usage.weeklyPercentage
            )

            if manager.usage.opusWeeklyTokensUsed > 0 || manager.usage.opusWeeklyPercentage > 0 {
                CompactMetricRow(
                    title: "Sonnet",
                    percentage: manager.usage.opusWeeklyPercentage
                )
            }

            if let used = manager.usage.costUsed, let limit = manager.usage.costLimit, limit > 0 {
                CompactMetricRow(
                    title: "Extra",
                    percentage: (used / limit) * 100.0
                )
            }

            if let apiUsage = manager.apiUsage, DataStore.shared.loadAPITrackingEnabled() {
                CompactMetricRow(
                    title: "API",
                    percentage: apiUsage.usagePercentage
                )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

// MARK: - Compact Metric Row
struct CompactMetricRow: View {
    let title: String
    let percentage: Double

    @Environment(\.colorScheme) var colorScheme

    private var statusColor: Color {
        switch percentage {
        case 0..<50: return Color(red: 0.34, green: 0.80, blue: 0.50)
        case 50..<75: return Color(red: 1.0, green: 0.75, blue: 0.30)
        case 75..<90: return Color(red: 1.0, green: 0.55, blue: 0.30)
        default: return Color(red: 1.0, green: 0.40, blue: 0.40)
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary.opacity(0.8))
                .frame(width: 50, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.primary.opacity(colorScheme == .dark ? 0.1 : 0.08))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(statusColor)
                        .frame(width: geo.size.width * min(max(percentage / 100.0, 0), 1))
                }
            }
            .frame(height: 4)

            Text("\(Int(percentage))%")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(statusColor)
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Visual Effect View
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.wantsLayer = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Header
struct PopoverHeader: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            // App Icon with glow
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .blur(radius: 8)

                Image("HeaderLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("CCStats")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 5, height: 5)
                        .shadow(color: Color.green.opacity(0.5), radius: 3)

                    Text("Connected")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let icon: String
    let title: String
    let percentage: Double
    let resetTime: Date?
    let subtitle: String

    @State private var isHovered = false
    @Environment(\.colorScheme) var colorScheme

    private var statusColor: Color {
        switch percentage {
        case 0..<50: return Color(red: 0.34, green: 0.80, blue: 0.50)
        case 50..<75: return Color(red: 1.0, green: 0.75, blue: 0.30)
        case 75..<90: return Color(red: 1.0, green: 0.55, blue: 0.30)
        default: return Color(red: 1.0, green: 0.40, blue: 0.40)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 8) {
                // Icon with monochrome background (Raycast style)
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.08))
                        .frame(width: 24, height: 24)

                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary.opacity(0.6))
                }

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary.opacity(0.9))

                Spacer()

                // Percentage with glow
                Text("\(Int(percentage))%")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(statusColor)
                    .shadow(color: statusColor.opacity(0.3), radius: 4)
            }

            // Progress bar with glow
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.15))

                    // Fill with gradient
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [statusColor, statusColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * min(max(percentage / 100.0, 0), 1))
                        .shadow(color: statusColor.opacity(0.4), radius: 4, x: 0, y: 0)
                }
            }
            .frame(height: 5)

            // Footer
            HStack {
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.7))

                Spacer()

                if let resetTime = resetTime {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 8, weight: .medium))

                        Text(formatResetTime(resetTime))
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.secondary.opacity(0.6))
                }
            }
        }
        .padding(12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.05 : 0.5))

                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.2), lineWidth: 0.5)
            }
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isHovered)
        .onHover { isHovered = $0 }
    }

    private func formatResetTime(_ date: Date) -> String {
        let diff = date.timeIntervalSince(Date())
        guard diff > 0 else { return "now" }

        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60

        if hours >= 24 {
            let days = hours / 24
            return "\(days)d \(hours % 24)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Footer
struct PopoverFooter: View {
    let lastRefreshTime: Date
    let isRefreshing: Bool
    let onRefresh: () -> Void
    let onSettings: () -> Void
    let onQuit: () -> Void

    @State private var refreshHovered = false
    @State private var settingsHovered = false
    @State private var quitHovered = false
    @Environment(\.colorScheme) var colorScheme

    private var refreshText: String {
        let seconds = Int(-lastRefreshTime.timeIntervalSinceNow)
        if seconds < 5 { return "now" }
        if seconds < 60 { return "\(seconds)s" }
        return "\(seconds / 60)m"
    }

    var body: some View {
        HStack(spacing: 6) {
            // Refresh
            FooterButton(
                icon: "arrow.clockwise",
                label: refreshText,
                isLoading: isRefreshing,
                isHovered: refreshHovered,
                action: onRefresh
            )
            .onHover { refreshHovered = $0 }
            .disabled(isRefreshing)

            Spacer()

            // Settings
            FooterIconButton(
                icon: "gearshape.fill",
                isHovered: settingsHovered,
                action: onSettings
            )
            .onHover { settingsHovered = $0 }

            // Quit
            FooterIconButton(
                icon: "power",
                isHovered: quitHovered,
                hoverColor: Color.red.opacity(0.15),
                action: onQuit
            )
            .onHover { quitHovered = $0 }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.black.opacity(colorScheme == .dark ? 0.2 : 0.03))
    }
}

// MARK: - Footer Button
struct FooterButton: View {
    let icon: String
    let label: String
    var isLoading: Bool = false
    let isHovered: Bool
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.45)
                        .frame(width: 10, height: 10)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 9, weight: .semibold))
                }

                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(.secondary.opacity(0.8))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.white.opacity(isHovered ? (colorScheme == .dark ? 0.1 : 0.6) : (colorScheme == .dark ? 0.05 : 0.3)))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Footer Icon Button
struct FooterIconButton: View {
    let icon: String
    let isHovered: Bool
    var hoverColor: Color = Color.white.opacity(0.1)
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary.opacity(0.7))
                .frame(width: 26, height: 26)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isHovered ? hoverColor : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}
