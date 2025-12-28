import SwiftUI

/// Automatic session management settings
struct SessionManagementView: View {
    @Binding var autoStartSessionEnabled: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Auto-Start Card
            GlassCard(title: "Automatic Sessions") {
                VStack(alignment: .leading, spacing: 16) {
                    SettingRow(
                        title: "Auto-start on Reset",
                        subtitle: "Initialize a new session when the current one expires"
                    ) {
                        Toggle("", isOn: $autoStartSessionEnabled)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                    .onChange(of: autoStartSessionEnabled) { _, newValue in
                        DataStore.shared.saveAutoStartSessionEnabled(newValue)
                    }

                    if autoStartSessionEnabled {
                        Divider()

                        // Beta Badge
                        HStack {
                            Text("BETA")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(SettingsColors.accentOrange)
                                )

                            Text("This feature is experimental")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // How It Works Card
            if autoStartSessionEnabled {
                GlassCard(title: "How It Works") {
                    VStack(alignment: .leading, spacing: 10) {
                        HowItWorksRow(
                            number: 1,
                            text: "Detects when your session resets to 0%"
                        )
                        HowItWorksRow(
                            number: 2,
                            text: "Sends 'Hi' to Claude 3.5 Haiku (cheapest model)"
                        )
                        HowItWorksRow(
                            number: 3,
                            text: "Uses a temporary chat that won't appear in history"
                        )
                        HowItWorksRow(
                            number: 4,
                            text: "New 5-hour session is ready instantly"
                        )
                    }
                }
            }

            Spacer()
        }
    }
}

// MARK: - How It Works Row

struct HowItWorksRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(SettingsColors.accentBlue))

            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
