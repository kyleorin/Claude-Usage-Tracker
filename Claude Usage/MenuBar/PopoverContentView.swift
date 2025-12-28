import SwiftUI

/// Clean, modern popover interface
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
            HeaderView()

            Divider()
                .padding(.horizontal, 16)

            // Content
            ScrollView {
                VStack(spacing: 12) {
                    // Current Session Card
                    UsageCard(
                        icon: "clock.fill",
                        iconColor: Color(red: 0.92, green: 0.34, blue: 0.34),
                        title: "CURRENT SESSION",
                        items: [
                            UsageItemData(
                                title: "5-Hour Usage",
                                percentage: manager.usage.sessionPercentage,
                                resetTime: manager.usage.sessionResetTime
                            )
                        ]
                    )

                    // Weekly Limits Card
                    UsageCard(
                        icon: "calendar",
                        iconColor: Color(red: 0.55, green: 0.36, blue: 0.76),
                        title: "WEEKLY LIMITS",
                        items: buildWeeklyItems()
                    )

                    // API Usage Card (if enabled)
                    if let apiUsage = manager.apiUsage, DataStore.shared.loadAPITrackingEnabled() {
                        APIUsageCard(apiUsage: apiUsage)
                    }
                }
                .padding(16)
            }

            // Footer
            FooterBar(
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
                onDashboard: onPreferences,
                onQuit: onQuit
            )
        }
        .frame(width: 340)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func buildWeeklyItems() -> [UsageItemData] {
        var items: [UsageItemData] = [
            UsageItemData(
                title: "7-Day Usage",
                percentage: manager.usage.weeklyPercentage,
                resetTime: manager.usage.weeklyResetTime
            )
        ]

        if manager.usage.opusWeeklyTokensUsed > 0 || manager.usage.opusWeeklyPercentage > 0 {
            items.append(UsageItemData(
                title: "Sonnet (7-Day)",
                percentage: manager.usage.opusWeeklyPercentage,
                resetTime: manager.usage.weeklyResetTime
            ))
        }

        if let used = manager.usage.costUsed, let limit = manager.usage.costLimit, limit > 0 {
            items.append(UsageItemData(
                title: "Extra Usage",
                percentage: (used / limit) * 100.0,
                resetTime: nil
            ))
        }

        return items
    }
}

// MARK: - Header
struct HeaderView: View {
    var body: some View {
        HStack(spacing: 12) {
            // App Icon
            ZStack {
                Circle()
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .frame(width: 42, height: 42)

                Image("HeaderLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("ClaudeUsage")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(red: 0.28, green: 0.75, blue: 0.42))
                        .frame(width: 8, height: 8)

                    Text("Account Session")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0.28, green: 0.75, blue: 0.42))
                }
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }
}

// MARK: - Usage Card
struct UsageCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let items: [UsageItemData]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(iconColor)

                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .default))
                    .foregroundColor(.secondary)
                    .tracking(0.8)
            }

            // Items
            VStack(spacing: 16) {
                ForEach(items) { item in
                    UsageRow(item: item)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
        )
    }
}

// MARK: - Usage Item Data
struct UsageItemData: Identifiable {
    let id = UUID()
    let title: String
    let percentage: Double
    let resetTime: Date?

    var status: (text: String, color: Color) {
        switch percentage {
        case 0..<50:
            return ("Good", Color(red: 0.28, green: 0.75, blue: 0.42))
        case 50..<75:
            return ("Moderate", Color(red: 0.95, green: 0.68, blue: 0.25))
        case 75..<90:
            return ("High", Color(red: 0.95, green: 0.50, blue: 0.25))
        default:
            return ("Critical", Color(red: 0.92, green: 0.34, blue: 0.34))
        }
    }
}

// MARK: - Usage Row
struct UsageRow: View {
    let item: UsageItemData

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title + Badge + Percentage
            HStack(alignment: .center) {
                Text(item.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()

                // Status Badge
                Text(item.status.text)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(item.status.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(item.status.color.opacity(0.12))
                    )

                // Percentage
                Text("\(Int(item.percentage))%")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(item.status.color)
                    .frame(minWidth: 48, alignment: .trailing)
            }

            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.12))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(item.status.color)
                        .frame(width: geo.size.width * min(max(item.percentage / 100.0, 0), 1), height: 6)
                }
            }
            .frame(height: 6)

            // Reset Time
            if let resetTime = item.resetTime {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.7))

                    Text("Resets in \(formatResetTime(resetTime))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
        }
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

// MARK: - API Usage Card
struct APIUsageCard: View {
    let apiUsage: APIUsage

    private var status: (text: String, color: Color) {
        switch apiUsage.usagePercentage {
        case 0..<50:
            return ("Good", Color(red: 0.28, green: 0.75, blue: 0.42))
        case 50..<75:
            return ("Moderate", Color(red: 0.95, green: 0.68, blue: 0.25))
        case 75..<90:
            return ("High", Color(red: 0.95, green: 0.50, blue: 0.25))
        default:
            return ("Critical", Color(red: 0.92, green: 0.34, blue: 0.34))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "server.rack")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 0.35, green: 0.55, blue: 0.85))

                Text("API USAGE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(0.8)
            }

            // Content
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center) {
                    Text("API Credits")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)

                    Spacer()

                    Text(status.text)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(status.color.opacity(0.12))
                        )

                    Text("\(Int(apiUsage.usagePercentage))%")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(status.color)
                        .frame(minWidth: 48, alignment: .trailing)
                }

                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.12))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(status.color)
                            .frame(width: geo.size.width * min(apiUsage.usagePercentage / 100.0, 1), height: 6)
                    }
                }
                .frame(height: 6)

                // Credits Info
                HStack(spacing: 4) {
                    Text(apiUsage.formattedUsed)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    Text("of")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.6))

                    Text(apiUsage.formattedRemaining)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    Text("remaining")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
        )
    }
}

// MARK: - Footer Bar
struct FooterBar: View {
    let lastRefreshTime: Date
    let isRefreshing: Bool
    let onRefresh: () -> Void
    let onDashboard: () -> Void
    let onQuit: () -> Void

    @State private var refreshHovered = false
    @State private var dashboardHovered = false
    @State private var quitHovered = false

    private var refreshText: String {
        let seconds = Int(-lastRefreshTime.timeIntervalSinceNow)
        if seconds < 5 { return "just now" }
        if seconds < 60 { return "\(seconds)s ago" }
        return "\(seconds / 60)m ago"
    }

    private let accentGreen = Color(red: 0.28, green: 0.75, blue: 0.42)

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 8) {
                // Refresh Button (outlined)
                Button(action: onRefresh) {
                    HStack(spacing: 6) {
                        if isRefreshing {
                            ProgressView()
                                .scaleEffect(0.55)
                                .frame(width: 14, height: 14)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .semibold))
                        }

                        Text(refreshText)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(accentGreen)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(accentGreen, lineWidth: 1.5)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(refreshHovered ? accentGreen.opacity(0.08) : Color.clear)
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(isRefreshing)
                .onHover { refreshHovered = $0 }

                Spacer()

                // Dashboard Button
                Button(action: onDashboard) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 11, weight: .medium))

                        Text("Dashboard")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.primary.opacity(0.8))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(dashboardHovered ? Color.primary.opacity(0.06) : Color(nsColor: .controlBackgroundColor).opacity(0.8))
                    )
                }
                .buttonStyle(.plain)
                .onHover { dashboardHovered = $0 }

                // Quit Button
                Button(action: onQuit) {
                    HStack(spacing: 6) {
                        Image(systemName: "power")
                            .font(.system(size: 11, weight: .medium))

                        Text("Quit")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.primary.opacity(0.8))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(quitHovered ? Color.primary.opacity(0.06) : Color(nsColor: .controlBackgroundColor).opacity(0.8))
                    )
                }
                .buttonStyle(.plain)
                .onHover { quitHovered = $0 }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
