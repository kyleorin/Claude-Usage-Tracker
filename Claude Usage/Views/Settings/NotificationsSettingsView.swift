import SwiftUI
import UserNotifications

/// Usage notifications and alerts settings
struct NotificationsSettingsView: View {
    @Binding var notificationsEnabled: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Enable Card
            GlassCard(title: "Alerts") {
                SettingRow(
                    title: "Enable Notifications",
                    subtitle: "Get alerts when approaching usage limits"
                ) {
                    Toggle("", isOn: $notificationsEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                .onChange(of: notificationsEnabled) { _, newValue in
                    DataStore.shared.saveNotificationsEnabled(newValue)
                    if newValue {
                        requestNotificationPermission()
                    }
                }
            }

            // Thresholds Card
            if notificationsEnabled {
                GlassCard(title: "Alert Thresholds") {
                    VStack(spacing: 12) {
                        ThresholdRow(percentage: 75, label: "Warning", color: SettingsColors.warning)
                        ThresholdRow(percentage: 90, label: "High Usage", color: SettingsColors.accentOrange)
                        ThresholdRow(percentage: 95, label: "Critical", color: SettingsColors.error)

                        Divider().padding(.vertical, 4)

                        ThresholdRow(percentage: 0, label: "Session Reset", color: SettingsColors.success)
                    }
                }
            }

            // Info Card
            GlassCard {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                        .foregroundColor(SettingsColors.accentBlue)

                    Text("Notifications will appear as system alerts when your usage reaches these thresholds.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()
        }
    }

    private func requestNotificationPermission() {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()

            if settings.authorizationStatus == .authorized {
                NotificationManager.shared.sendSimpleAlert(type: .notificationsEnabled)
            } else if settings.authorizationStatus == .notDetermined {
                let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
                if granted == true {
                    NotificationManager.shared.sendSimpleAlert(type: .notificationsEnabled)
                }
            }
        }
    }
}

// MARK: - Threshold Row

struct ThresholdRow: View {
    let percentage: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text("\(percentage)%")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
                .frame(width: 40, alignment: .leading)

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}
