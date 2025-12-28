import SwiftUI

/// Modern liquid glass popover interface
struct PopoverContentView: View {
    @ObservedObject var manager: MenuBarManager
    let onRefresh: () -> Void
    let onPreferences: () -> Void
    let onQuit: () -> Void

    @State private var isRefreshing = false
    @State private var lastRefreshTime = Date()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            PopoverHeader()

            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    // Current Session
                    UsageMetricCard(
                        icon: "clock.fill",
                        iconColor: .orange,
                        title: "Current Session",
                        percentage: manager.usage.sessionPercentage,
                        resetTime: manager.usage.sessionResetTime,
                        subtitle: "5-hour rolling window"
                    )

                    // Weekly Usage
                    UsageMetricCard(
                        icon: "calendar",
                        iconColor: .purple,
                        title: "Weekly Usage",
                        percentage: manager.usage.weeklyPercentage,
                        resetTime: manager.usage.weeklyResetTime,
                        subtitle: "7-day limit"
                    )

                    // Opus Weekly (if applicable)
                    if manager.usage.opusWeeklyTokensUsed > 0 || manager.usage.opusWeeklyPercentage > 0 {
                        UsageMetricCard(
                            icon: "star.fill",
                            iconColor: .blue,
                            title: "Sonnet Weekly",
                            percentage: manager.usage.opusWeeklyPercentage,
                            resetTime: manager.usage.weeklyResetTime,
                            subtitle: "Model-specific limit"
                        )
                    }

                    // Extra Usage (if applicable)
                    if let used = manager.usage.costUsed, let limit = manager.usage.costLimit, limit > 0 {
                        UsageMetricCard(
                            icon: "dollarsign.circle.fill",
                            iconColor: .green,
                            title: "Extra Usage",
                            percentage: (used / limit) * 100.0,
                            resetTime: nil,
                            subtitle: String(format: "$%.2f of $%.2f", used, limit)
                        )
                    }

                    // API Usage (if enabled)
                    if let apiUsage = manager.apiUsage, DataStore.shared.loadAPITrackingEnabled() {
                        UsageMetricCard(
                            icon: "server.rack",
                            iconColor: .cyan,
                            title: "API Credits",
                            percentage: apiUsage.usagePercentage,
                            resetTime: nil,
                            subtitle: "\(apiUsage.formattedUsed) of \(apiUsage.formattedRemaining)"
                        )
                    }
                }
                .padding(16)
            }

            // Footer
            PopoverFooter(
                lastRefreshTime: lastRefreshTime,
                isRefreshing: isRefreshing,
                onRefresh: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isRefreshing = true
                    }
                    onRefresh()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isRefreshing = false
                            lastRefreshTime = Date()
                        }
                    }
                },
                onSettings: onPreferences,
                onQuit: onQuit
            )
        }
        .frame(width: 320)
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
        )
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
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Header
struct PopoverHeader: View {
    var body: some View {
        HStack(spacing: 10) {
            // App Icon
            Image("HeaderLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text("ClaudeUsage")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)

                    Text("Active")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Usage Metric Card
struct UsageMetricCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let percentage: Double
    let resetTime: Date?
    let subtitle: String

    private var statusColor: Color {
        switch percentage {
        case 0..<50: return Color(red: 0.28, green: 0.75, blue: 0.42)
        case 50..<75: return Color(red: 0.95, green: 0.68, blue: 0.25)
        case 75..<90: return Color(red: 0.95, green: 0.50, blue: 0.25)
        default: return Color(red: 0.92, green: 0.34, blue: 0.34)
        }
    }

    private var statusLabel: String {
        switch percentage {
        case 0..<50: return "Good"
        case 50..<75: return "Moderate"
        case 75..<90: return "High"
        default: return "Critical"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(iconColor)

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                Text("\(Int(percentage))%")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(statusColor)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.08))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [statusColor, statusColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * min(max(percentage / 100.0, 0), 1))
                }
            }
            .frame(height: 8)

            // Footer row
            HStack {
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Spacer()

                if let resetTime = resetTime {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 9, weight: .medium))

                        Text(formatResetTime(resetTime))
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.secondary.opacity(0.8))
                } else {
                    // Status badge
                    Text(statusLabel)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(statusColor.opacity(0.12))
                        )
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private func formatResetTime(_ date: Date) -> String {
        let diff = date.timeIntervalSince(Date())
        guard diff > 0 else { return "now" }

        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60

        if hours >= 24 {
            let days = hours / 24
            let remainingHours = hours % 24
            return "\(days)d \(remainingHours)h"
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

    private var refreshText: String {
        let seconds = Int(-lastRefreshTime.timeIntervalSinceNow)
        if seconds < 5 { return "just now" }
        if seconds < 60 { return "\(seconds)s ago" }
        return "\(seconds / 60)m ago"
    }

    var body: some View {
        HStack(spacing: 10) {
            // Refresh button
            Button(action: onRefresh) {
                HStack(spacing: 5) {
                    if isRefreshing {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 12, height: 12)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10, weight: .semibold))
                    }

                    Text(refreshText)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(refreshHovered ? Color.primary.opacity(0.08) : Color.clear)
                )
            }
            .buttonStyle(.plain)
            .disabled(isRefreshing)
            .onHover { refreshHovered = $0 }

            Spacer()

            // Settings button
            Button(action: onSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(settingsHovered ? Color.primary.opacity(0.08) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .onHover { settingsHovered = $0 }

            // Quit button
            Button(action: onQuit) {
                Image(systemName: "power")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(quitHovered ? Color.red.opacity(0.12) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .onHover { quitHovered = $0 }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.03))
    }
}
