import SwiftUI

/// General app behavior and preferences
struct GeneralSettingsView: View {
    @Binding var refreshInterval: Double
    @State private var checkOverageLimitEnabled: Bool = DataStore.shared.loadCheckOverageLimitEnabled()
    @State private var launchAtLogin: Bool = LaunchAtLoginManager.shared.isEnabled

    var body: some View {
        VStack(spacing: 16) {
            // Startup Card
            GlassCard(title: "Startup") {
                SettingRow(
                    title: "Launch at Login",
                    subtitle: "Start CCStats when you log in"
                ) {
                    Toggle("", isOn: $launchAtLogin)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                .onChange(of: launchAtLogin) { _, newValue in
                    let success = LaunchAtLoginManager.shared.setEnabled(newValue)
                    if !success {
                        launchAtLogin = LaunchAtLoginManager.shared.isEnabled
                    }
                }
            }

            // Refresh Card
            GlassCard(title: "Data Refresh") {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Update Interval")
                            .font(.system(size: 13))

                        Spacer()

                        Text("\(Int(refreshInterval)) seconds")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $refreshInterval, in: 5...120, step: 5)
                        .onChange(of: refreshInterval) { _, newValue in
                            DataStore.shared.saveRefreshInterval(newValue)
                        }

                    Text("Lower values provide more real-time data but use more resources")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            // Tracking Card
            GlassCard(title: "Usage Tracking") {
                SettingRow(
                    title: "Track Extra Usage",
                    subtitle: "Show monthly cost and overage limits"
                ) {
                    Toggle("", isOn: $checkOverageLimitEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                .onChange(of: checkOverageLimitEnabled) { _, newValue in
                    DataStore.shared.saveCheckOverageLimitEnabled(newValue)
                }
            }

            Spacer()
        }
        .onAppear {
            launchAtLogin = LaunchAtLoginManager.shared.isEnabled
        }
    }
}
