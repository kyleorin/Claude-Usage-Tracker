import SwiftUI

/// Popover with card or compact mode
struct PopoverContentView: View {
    @ObservedObject var manager: MenuBarManager
    let onRefresh: () -> Void
    let onPreferences: () -> Void
    let onQuit: () -> Void

    @State private var isRefreshing = false
    @State private var lastRefreshTime = Date()
    @Environment(\.colorScheme) var colorScheme

    private var isCompact: Bool {
        DataStore.shared.loadCompactPopover()
    }

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
        .frame(width: isCompact ? 240 : 280)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
    }

    // MARK: - Card Content
    private var cardContent: some View {
        VStack(spacing: 8) {
            MetricCard(
                icon: "clock.fill",
                iconGradient: [Color.orange, Color.orange.opacity(0.7)],
                title: "Session",
                percentage: manager.usage.sessionPercentage,
                resetTime: manager.usage.sessionResetTime
            )

            MetricCard(
                icon: "calendar",
                iconGradient: [Color.purple, Color.purple.opacity(0.7)],
                title: "Weekly",
                percentage: manager.usage.weeklyPercentage,
                resetTime: manager.usage.weeklyResetTime
            )

            if manager.usage.opusWeeklyTokensUsed > 0 || manager.usage.opusWeeklyPercentage > 0 {
                MetricCard(
                    icon: "sparkles",
                    iconGradient: [Color.blue, Color.cyan],
                    title: "Sonnet",
                    percentage: manager.usage.opusWeeklyPercentage,
                    resetTime: nil
                )
            }

            if let used = manager.usage.costUsed, let limit = manager.usage.costLimit, limit > 0 {
                MetricCard(
                    icon: "dollarsign.circle.fill",
                    iconGradient: [Color.green, Color.mint],
                    title: "Extra",
                    percentage: (used / limit) * 100.0,
                    resetTime: nil,
                    subtitle: String(format: "$%.2f", used)
                )
            }

            if let apiUsage = manager.apiUsage, DataStore.shared.loadAPITrackingEnabled() {
                MetricCard(
                    icon: "server.rack",
                    iconGradient: [Color.cyan, Color.teal],
                    title: "API",
                    percentage: apiUsage.usagePercentage,
                    resetTime: nil,
                    subtitle: apiUsage.formattedUsed
                )
            }
        }
        .padding(10)
    }

    // MARK: - Compact Content
    private var compactContent: some View {
        VStack(spacing: 6) {
            CompactRow(title: "Session", percentage: manager.usage.sessionPercentage, resetTime: manager.usage.sessionResetTime)
            CompactRow(title: "Weekly", percentage: manager.usage.weeklyPercentage, resetTime: manager.usage.weeklyResetTime)

            if manager.usage.opusWeeklyTokensUsed > 0 || manager.usage.opusWeeklyPercentage > 0 {
                CompactRow(title: "Sonnet", percentage: manager.usage.opusWeeklyPercentage, resetTime: nil)
            }

            if let used = manager.usage.costUsed, let limit = manager.usage.costLimit, limit > 0 {
                CompactRow(title: "Extra", percentage: (used / limit) * 100.0, resetTime: nil, subtitle: String(format: "$%.2f", used))
            }

            if let apiUsage = manager.apiUsage, DataStore.shared.loadAPITrackingEnabled() {
                CompactRow(title: "API", percentage: apiUsage.usagePercentage, resetTime: nil, subtitle: apiUsage.formattedUsed)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
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

            Circle()
                .fill(Color.green)
                .frame(width: 6, height: 6)
        }
    }
}

// MARK: - Metric Card (Default)
struct MetricCard: View {
    let icon: String
    let iconGradient: [Color]
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
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(LinearGradient(colors: iconGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 22, height: 22)

                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 50, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.primary.opacity(0.1))

                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(statusColor)
                        .frame(width: geo.size.width * min(max(percentage / 100.0, 0), 1))
                }
            }
            .frame(height: 5)

            Text("\(Int(percentage))%")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(statusColor)
                .frame(width: 38, alignment: .trailing)

            if let resetTime = resetTime {
                Text(formatTime(resetTime))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .frame(width: 28, alignment: .trailing)
            } else if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .frame(width: 28, alignment: .trailing)
            } else {
                Spacer().frame(width: 28)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(colorScheme == .dark ? 0.4 : 0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }

    private func formatTime(_ date: Date) -> String {
        let diff = date.timeIntervalSince(Date())
        guard diff > 0 else { return "now" }
        let hours = Int(diff) / 3600
        if hours >= 24 { return "\(hours / 24)d" }
        if hours > 0 { return "\(hours)h" }
        return "\((Int(diff) % 3600) / 60)m"
    }
}

// MARK: - Compact Row
struct CompactRow: View {
    let title: String
    let percentage: Double
    var resetTime: Date? = nil
    var subtitle: String? = nil

    private var statusColor: Color {
        switch percentage {
        case 0..<50: return Color(red: 0.34, green: 0.80, blue: 0.50)
        case 50..<75: return Color(red: 1.0, green: 0.75, blue: 0.30)
        case 75..<90: return Color(red: 1.0, green: 0.55, blue: 0.30)
        default: return Color(red: 1.0, green: 0.40, blue: 0.40)
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: 45, alignment: .leading)

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

            Text("\(Int(percentage))%")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(statusColor)
                .frame(width: 32, alignment: .trailing)

            if let resetTime = resetTime {
                Text(formatTime(resetTime))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.6))
                    .frame(width: 24, alignment: .trailing)
            } else if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.6))
                    .frame(width: 24, alignment: .trailing)
            }
        }
        .frame(height: 18)
    }

    private func formatTime(_ date: Date) -> String {
        let diff = date.timeIntervalSince(Date())
        guard diff > 0 else { return "now" }
        let hours = Int(diff) / 3600
        if hours >= 24 { return "\(hours / 24)d" }
        if hours > 0 { return "\(hours)h" }
        return "\((Int(diff) % 3600) / 60)m"
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
