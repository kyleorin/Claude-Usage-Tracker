import SwiftUI

/// Clean, modern popover interface matching CUStats design
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
            AppHeader()

            // Content
            VStack(spacing: 16) {
                // Current Session Section
                UsageSection(
                    icon: "clock.fill",
                    iconColor: Color(red: 0.95, green: 0.3, blue: 0.3),
                    title: "CURRENT SESSION",
                    items: [
                        UsageItem(
                            title: "5-Hour Usage",
                            percentage: manager.usage.sessionPercentage,
                            resetTime: manager.usage.sessionResetTime
                        )
                    ]
                )

                // Weekly Limits Section
                UsageSection(
                    icon: "calendar",
                    iconColor: Color(red: 0.6, green: 0.4, blue: 0.8),
                    title: "WEEKLY LIMITS",
                    items: buildWeeklyItems()
                )

                // API Usage Section (if enabled)
                if let apiUsage = manager.apiUsage, DataStore.shared.loadAPITrackingEnabled() {
                    APISection(apiUsage: apiUsage)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)

            // Footer
            FooterView(
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
        .frame(width: 320)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func buildWeeklyItems() -> [UsageItem] {
        var items: [UsageItem] = [
            UsageItem(
                title: "7-Day Usage",
                percentage: manager.usage.weeklyPercentage,
                resetTime: manager.usage.weeklyResetTime
            )
        ]

        // Add Opus/Sonnet if available
        if manager.usage.opusWeeklyTokensUsed > 0 || manager.usage.opusWeeklyPercentage > 0 {
            items.append(UsageItem(
                title: "Sonnet (7-Day)",
                percentage: manager.usage.opusWeeklyPercentage,
                resetTime: manager.usage.weeklyResetTime.addingTimeInterval(2 * 24 * 3600) // Example offset
            ))
        }

        // Add Extra Usage if applicable
        if let used = manager.usage.costUsed, let limit = manager.usage.costLimit, limit > 0 {
            let percentage = (used / limit) * 100.0
            items.append(UsageItem(
                title: "Extra Usage",
                percentage: percentage,
                resetTime: nil
            ))
        }

        return items
    }
}

// MARK: - App Header
struct AppHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            // App Icon
            Image("HeaderLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color(nsColor: .controlBackgroundColor))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("ClaudeUsage")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)

                    Text("Account Session")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.green)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Usage Section
struct UsageSection: View {
    let icon: String
    let iconColor: Color
    let title: String
    let items: [UsageItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(iconColor)

                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.primary)
                    .tracking(0.5)
            }

            // Usage Items
            VStack(spacing: 14) {
                ForEach(items, id: \.title) { item in
                    UsageRowView(item: item)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
    }
}

// MARK: - Usage Item Model
struct UsageItem: Identifiable {
    let id = UUID()
    let title: String
    let percentage: Double
    let resetTime: Date?

    var statusText: String {
        switch percentage {
        case 0..<50: return "Good"
        case 50..<75: return "Moderate"
        case 75..<90: return "High"
        default: return "Critical"
        }
    }

    var statusColor: Color {
        switch percentage {
        case 0..<50: return Color(red: 0.2, green: 0.78, blue: 0.35)  // Green
        case 50..<75: return Color(red: 1.0, green: 0.75, blue: 0.0)  // Yellow/Orange
        case 75..<90: return Color(red: 1.0, green: 0.5, blue: 0.0)   // Orange
        default: return Color(red: 0.95, green: 0.35, blue: 0.35)     // Coral Red
        }
    }

    var progressColor: Color {
        statusColor
    }
}

// MARK: - Usage Row View
struct UsageRowView: View {
    let item: UsageItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title Row
            HStack {
                Text(item.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()

                // Status Badge
                Text(item.statusText)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(item.statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(item.statusColor.opacity(0.12))
                    )

                // Percentage
                Text("\(Int(item.percentage))%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(item.statusColor)
                    .frame(width: 50, alignment: .trailing)
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.15))

                    // Fill
                    RoundedRectangle(cornerRadius: 3)
                        .fill(item.progressColor)
                        .frame(width: geometry.size.width * min(item.percentage / 100.0, 1.0))
                }
            }
            .frame(height: 6)

            // Reset Time
            if let resetTime = item.resetTime {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)

                    Text("Resets in \(resetTime.shortResetString())")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - API Section
struct APISection: View {
    let apiUsage: APIUsage

    private var statusColor: Color {
        switch apiUsage.usagePercentage {
        case 0..<50: return Color(red: 0.2, green: 0.78, blue: 0.35)
        case 50..<75: return Color(red: 1.0, green: 0.75, blue: 0.0)
        case 75..<90: return Color(red: 1.0, green: 0.5, blue: 0.0)
        default: return Color(red: 0.95, green: 0.35, blue: 0.35)
        }
    }

    private var statusText: String {
        switch apiUsage.usagePercentage {
        case 0..<50: return "Good"
        case 50..<75: return "Moderate"
        case 75..<90: return "High"
        default: return "Critical"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: "server.rack")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(red: 0.3, green: 0.6, blue: 0.9))

                Text("API USAGE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.primary)
                    .tracking(0.5)
            }

            // API Usage Row
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("API Credits")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)

                    Spacer()

                    Text(statusText)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(statusColor.opacity(0.12))
                        )

                    Text("\(Int(apiUsage.usagePercentage))%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(statusColor)
                        .frame(width: 50, alignment: .trailing)
                }

                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.15))

                        RoundedRectangle(cornerRadius: 3)
                            .fill(statusColor)
                            .frame(width: geometry.size.width * min(apiUsage.usagePercentage / 100.0, 1.0))
                    }
                }
                .frame(height: 6)

                // Credits info
                HStack {
                    Text(apiUsage.formattedUsed)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    Text("of")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.7))

                    Text(apiUsage.formattedRemaining)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
    }
}

// MARK: - Footer View
struct FooterView: View {
    let lastRefreshTime: Date
    let isRefreshing: Bool
    let onRefresh: () -> Void
    let onDashboard: () -> Void
    let onQuit: () -> Void

    private var refreshText: String {
        let seconds = Int(-lastRefreshTime.timeIntervalSinceNow)
        if seconds < 5 {
            return "just now"
        } else if seconds < 60 {
            return "\(seconds)s ago"
        } else {
            let minutes = seconds / 60
            return "\(minutes)m ago"
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            // Refresh Button
            Button(action: onRefresh) {
                HStack(spacing: 6) {
                    if isRefreshing {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 14, height: 14)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                    }

                    Text(refreshText)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(Color(red: 0.2, green: 0.78, blue: 0.35))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 0.2, green: 0.78, blue: 0.35), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
            .disabled(isRefreshing)

            Spacer()

            // Dashboard Button
            Button(action: onDashboard) {
                HStack(spacing: 6) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 12, weight: .medium))

                    Text("Dashboard")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
            }
            .buttonStyle(.plain)

            // Quit Button
            Button(action: onQuit) {
                HStack(spacing: 6) {
                    Image(systemName: "power")
                        .font(.system(size: 12, weight: .medium))

                    Text("Quit")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Date Extension for Short Reset String
extension Date {
    func shortResetString() -> String {
        let now = Date()
        let diff = self.timeIntervalSince(now)

        if diff <= 0 {
            return "now"
        }

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
