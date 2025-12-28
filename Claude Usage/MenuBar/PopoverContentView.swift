import SwiftUI

/// Compact Raycast-inspired popover
struct PopoverContentView: View {
    @ObservedObject var manager: MenuBarManager
    let onRefresh: () -> Void
    let onPreferences: () -> Void
    let onQuit: () -> Void

    @State private var isRefreshing = false
    @State private var lastRefreshTime = Date()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Header
            PopoverHeader()
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Divider
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 1)
                .padding(.horizontal, 14)

            // Content - no scroll, compact
            VStack(spacing: 8) {
                // Current Session - always show
                MetricRow(
                    title: "Session",
                    percentage: manager.usage.sessionPercentage,
                    resetTime: manager.usage.sessionResetTime
                )

                // Weekly Usage - always show
                MetricRow(
                    title: "Weekly",
                    percentage: manager.usage.weeklyPercentage,
                    resetTime: manager.usage.weeklyResetTime
                )

                // Sonnet Weekly (if applicable)
                if manager.usage.opusWeeklyTokensUsed > 0 || manager.usage.opusWeeklyPercentage > 0 {
                    MetricRow(
                        title: "Sonnet",
                        percentage: manager.usage.opusWeeklyPercentage,
                        resetTime: nil
                    )
                }

                // Extra Usage (if applicable)
                if let used = manager.usage.costUsed, let limit = manager.usage.costLimit, limit > 0 {
                    MetricRow(
                        title: "Extra",
                        percentage: (used / limit) * 100.0,
                        resetTime: nil,
                        subtitle: String(format: "$%.2f", used)
                    )
                }

                // API Usage (if enabled)
                if let apiUsage = manager.apiUsage, DataStore.shared.loadAPITrackingEnabled() {
                    MetricRow(
                        title: "API",
                        percentage: apiUsage.usagePercentage,
                        resetTime: nil,
                        subtitle: apiUsage.formattedUsed
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

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
        .frame(width: 260)
        .background(
            ZStack {
                VisualEffectView(material: .popover, blendingMode: .behindWindow)
            }
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
        HStack(spacing: 8) {
            Image("HeaderLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22, height: 22)

            Text("CCStats")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)

            Spacer()

            // Status dot
            Circle()
                .fill(Color.green)
                .frame(width: 6, height: 6)
        }
    }
}

// MARK: - Metric Row (Compact)
struct MetricRow: View {
    let title: String
    let percentage: Double
    var resetTime: Date? = nil
    var subtitle: String? = nil

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
            // Title
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.primary.opacity(0.08))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(statusColor)
                        .frame(width: geo.size.width * min(max(percentage / 100.0, 0), 1))
                }
            }
            .frame(height: 4)

            // Percentage
            Text("\(Int(percentage))%")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(statusColor)
                .frame(width: 36, alignment: .trailing)

            // Reset time or subtitle
            if let resetTime = resetTime {
                Text(formatResetTime(resetTime))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.6))
                    .frame(width: 40, alignment: .trailing)
            } else if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.6))
                    .frame(width: 40, alignment: .trailing)
            }
        }
        .frame(height: 20)
    }

    private func formatResetTime(_ date: Date) -> String {
        let diff = date.timeIntervalSince(Date())
        guard diff > 0 else { return "now" }

        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60

        if hours >= 24 {
            return "\(hours / 24)d"
        } else if hours > 0 {
            return "\(hours)h"
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
        if seconds < 5 { return "now" }
        if seconds < 60 { return "\(seconds)s" }
        return "\(seconds / 60)m"
    }

    var body: some View {
        HStack(spacing: 4) {
            // Refresh
            Button(action: onRefresh) {
                HStack(spacing: 3) {
                    if isRefreshing {
                        ProgressView()
                            .scaleEffect(0.4)
                            .frame(width: 10, height: 10)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 9, weight: .medium))
                    }
                    Text(refreshText)
                        .font(.system(size: 10))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(refreshHovered ? Color.primary.opacity(0.08) : Color.clear)
                )
            }
            .buttonStyle(.plain)
            .onHover { refreshHovered = $0 }
            .disabled(isRefreshing)

            Spacer()

            // Settings
            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(settingsHovered ? Color.primary.opacity(0.08) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .onHover { settingsHovered = $0 }

            // Quit
            Button(action: onQuit) {
                Image(systemName: "power")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(quitHovered ? Color.red.opacity(0.1) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .onHover { quitHovered = $0 }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.03))
    }
}
