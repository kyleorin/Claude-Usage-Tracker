import SwiftUI

/// Menu bar icon appearance and customization
struct AppearanceSettingsView: View {
    @State private var iconStyle: MenuBarIconStyle = DataStore.shared.loadMenuBarIconStyle()
    @State private var monochromeMode: Bool = DataStore.shared.loadMonochromeMode()
    @State private var compactPopover: Bool = DataStore.shared.loadCompactPopover()

    var body: some View {
        VStack(spacing: 16) {
            // Icon Style Card
            GlassCard(title: "Menu Bar Icon") {
                VStack(alignment: .leading, spacing: 16) {
                    // Icon Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(MenuBarIconStyle.allCases, id: \.self) { style in
                            IconStyleOption(
                                style: style,
                                isSelected: iconStyle == style
                            ) {
                                iconStyle = style
                                DataStore.shared.saveMenuBarIconStyle(style)
                                NotificationCenter.default.post(name: .menuBarIconStyleChanged, object: nil)
                            }
                        }
                    }
                }
            }

            // Popover Style Card
            GlassCard(title: "Popover") {
                SettingRow(
                    title: "Compact Mode",
                    subtitle: "Show minimal popover without cards"
                ) {
                    Toggle("", isOn: $compactPopover)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                .onChange(of: compactPopover) { _, newValue in
                    DataStore.shared.saveCompactPopover(newValue)
                }
            }

            // Color Mode Card
            GlassCard(title: "Color Mode") {
                SettingRow(
                    title: "Monochrome",
                    subtitle: "Adapt to system appearance without color"
                ) {
                    Toggle("", isOn: $monochromeMode)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                .onChange(of: monochromeMode) { _, newValue in
                    DataStore.shared.saveMonochromeMode(newValue)
                    NotificationCenter.default.post(name: .menuBarIconStyleChanged, object: nil)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Icon Style Option

struct IconStyleOption: View {
    let style: MenuBarIconStyle
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // Preview
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.primary.opacity(0.03))
                        .frame(height: 48)

                    Image(systemName: style.icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                }

                // Label
                Text(style.displayName)
                    .font(.system(size: 11, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
