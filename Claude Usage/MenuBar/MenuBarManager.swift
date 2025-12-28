import Cocoa
import SwiftUI
import Combine

class MenuBarManager: NSObject, ObservableObject {
    private var statusItem: NSStatusItem?
    private var refreshTimer: Timer?
    @Published private(set) var usage: ClaudeUsage = .empty
    @Published private(set) var status: ClaudeStatus = .unknown
    @Published private(set) var apiUsage: APIUsage? = nil

    private var popover: NSPopover?
    private var eventMonitor: Any?
    private var detachedWindow: NSWindow?
    private var settingsWindow: NSWindow?

    private let apiService = ClaudeAPIService()
    private let statusService = ClaudeStatusService()
    private let dataStore = DataStore.shared
    private let networkMonitor = NetworkMonitor.shared

    private var refreshIntervalObserver: NSKeyValueObservation?
    private var appearanceObserver: NSKeyValueObservation?
    private var iconStyleObserver: NSObjectProtocol?

    // MARK: - Image Caching
    private var cachedImage: NSImage?
    private var cachedImageKey: String = ""
    private var updateDebounceTimer: Timer?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            updateStatusButton(button, usage: usage)
            button.action = #selector(togglePopover)
            button.target = self
        }

        setupPopover()

        // Load saved data first
        if let savedUsage = dataStore.loadUsage() {
            usage = savedUsage
            if let button = statusItem?.button {
                updateStatusButton(button, usage: savedUsage)
            }
        }
        if let savedAPIUsage = dataStore.loadAPIUsage() {
            apiUsage = savedAPIUsage
        }

        // Network monitoring
        networkMonitor.onNetworkAvailable = { [weak self] in
            self?.refreshUsage()
        }
        networkMonitor.startMonitoring()

        // Initial fetch
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.refreshUsage()
        }

        startAutoRefresh()
        observeRefreshIntervalChanges()
        observeAppearanceChanges()
        observeIconStyleChanges()
    }

    func cleanup() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        networkMonitor.stopMonitoring()
        refreshIntervalObserver?.invalidate()
        refreshIntervalObserver = nil
        appearanceObserver?.invalidate()
        appearanceObserver = nil
        if let iconStyleObserver = iconStyleObserver {
            NotificationCenter.default.removeObserver(iconStyleObserver)
            self.iconStyleObserver = nil
        }
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        detachedWindow?.close()
        detachedWindow = nil
        statusItem = nil
    }

    private func setupPopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 500)
        popover.behavior = .semitransient
        popover.animates = true
        popover.delegate = self
        popover.contentViewController = createContentViewController()
        self.popover = popover
    }

    private func createContentViewController() -> NSHostingController<PopoverContentView> {
        let contentView = PopoverContentView(
            manager: self,
            onRefresh: { [weak self] in
                self?.refreshUsage()
            },
            onPreferences: { [weak self] in
                self?.closePopoverOrWindow()
                self?.preferencesClicked()
            },
            onQuit: { [weak self] in
                self?.quitClicked()
            }
        )
        return NSHostingController(rootView: contentView)
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }

        if let window = detachedWindow {
            window.close()
            detachedWindow = nil
            return
        }

        if let popover = popover {
            if popover.isShown {
                closePopover()
            } else {
                if popover.contentViewController == nil {
                    popover.contentViewController = createContentViewController()
                }
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                startMonitoringForOutsideClicks()
            }
        }
    }

    private func closePopover() {
        popover?.performClose(nil)
        stopMonitoringForOutsideClicks()
    }

    private func startMonitoringForOutsideClicks() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self,
                  let popover = self.popover,
                  popover.isShown,
                  self.detachedWindow == nil else { return }
            self.closePopover()
        }
    }

    private func stopMonitoringForOutsideClicks() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func closePopoverOrWindow() {
        if let window = detachedWindow {
            window.close()
            detachedWindow = nil
        } else {
            popover?.performClose(nil)
        }
    }

    private func updateStatusButton(_ button: NSStatusBarButton, usage: ClaudeUsage) {
        let iconStyle = dataStore.loadMenuBarIconStyle()
        let isDarkAppearance = button.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let monochromeMode = dataStore.loadMonochromeMode()

        let percentage = Int(usage.sessionPercentage)
        let cacheKey = "\(percentage)_\(isDarkAppearance)_\(iconStyle.rawValue)_\(monochromeMode)"

        if cachedImage != nil && cachedImageKey == cacheKey {
            return
        }

        updateDebounceTimer?.invalidate()
        updateDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            let image: NSImage
            switch iconStyle {
            case .battery:
                image = self.createBatteryStyle(usage: usage, isDarkMode: isDarkAppearance, monochromeMode: monochromeMode)
            case .progressBar:
                image = self.createProgressBarStyle(usage: usage, isDarkMode: isDarkAppearance, monochromeMode: monochromeMode)
            case .percentageOnly:
                image = self.createPercentageOnlyStyle(usage: usage, isDarkMode: isDarkAppearance, monochromeMode: monochromeMode)
            case .icon:
                image = self.createIconWithBarStyle(usage: usage, isDarkMode: isDarkAppearance, monochromeMode: monochromeMode)
            case .compact:
                image = self.createCompactStyle(usage: usage, isDarkMode: isDarkAppearance, monochromeMode: monochromeMode)
            }

            self.cachedImage = image
            self.cachedImageKey = cacheKey
            button.image = image
            button.image?.isTemplate = false
            button.title = ""
        }
    }

    // MARK: - Icon Styles

    private func createBatteryStyle(usage: ClaudeUsage, isDarkMode: Bool, monochromeMode: Bool) -> NSImage {
        let percentage = CGFloat(usage.sessionPercentage) / 100.0
        let width: CGFloat = 26
        let height: CGFloat = 18
        let image = NSImage(size: NSSize(width: width, height: height))

        image.lockFocus()
        defer { image.unlockFocus() }

        let strokeColor: NSColor = isDarkMode ? .white.withAlphaComponent(0.7) : .black.withAlphaComponent(0.6)
        let fillColor = monochromeMode ? strokeColor : getColorForUsageLevel(usage.statusLevel)

        // Battery body dimensions
        let bodyWidth: CGFloat = 20
        let bodyHeight: CGFloat = 10
        let bodyX: CGFloat = 1
        let bodyY: CGFloat = (height - bodyHeight) / 2
        let cornerRadius: CGFloat = 2.5

        // Draw battery outline
        let bodyRect = NSRect(x: bodyX, y: bodyY, width: bodyWidth, height: bodyHeight)
        let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: cornerRadius, yRadius: cornerRadius)
        strokeColor.setStroke()
        bodyPath.lineWidth = 1.2
        bodyPath.stroke()

        // Draw battery cap (nub)
        let capWidth: CGFloat = 2.5
        let capHeight: CGFloat = 5
        let capX = bodyX + bodyWidth + 0.5
        let capY = bodyY + (bodyHeight - capHeight) / 2
        let capPath = NSBezierPath(roundedRect: NSRect(x: capX, y: capY, width: capWidth, height: capHeight), xRadius: 1, yRadius: 1)
        strokeColor.setFill()
        capPath.fill()

        // Draw fill level
        let fillPadding: CGFloat = 2
        let fillMaxWidth = bodyWidth - fillPadding * 2
        let fillWidth = fillMaxWidth * percentage
        if fillWidth > 1 {
            let fillRect = NSRect(x: bodyX + fillPadding, y: bodyY + fillPadding, width: fillWidth, height: bodyHeight - fillPadding * 2)
            let fillPath = NSBezierPath(roundedRect: fillRect, xRadius: 1.5, yRadius: 1.5)
            fillColor.setFill()
            fillPath.fill()
        }

        return image
    }

    private func createProgressBarStyle(usage: ClaudeUsage, isDarkMode: Bool, monochromeMode: Bool) -> NSImage {
        let width: CGFloat = 36
        let height: CGFloat = 18
        let image = NSImage(size: NSSize(width: width, height: height))

        image.lockFocus()
        defer { image.unlockFocus() }

        let textColor: NSColor = isDarkMode ? .white : .black
        let fillColor = monochromeMode ? textColor : getColorForUsageLevel(usage.statusLevel)
        let backgroundColor: NSColor = isDarkMode ? NSColor.white.withAlphaComponent(0.12) : NSColor.black.withAlphaComponent(0.08)

        let barWidth: CGFloat = width - 4
        let barHeight: CGFloat = 6
        let barY = (height - barHeight) / 2
        let barX: CGFloat = 2

        // Background pill
        let bgPath = NSBezierPath(roundedRect: NSRect(x: barX, y: barY, width: barWidth, height: barHeight), xRadius: 3, yRadius: 3)
        backgroundColor.setFill()
        bgPath.fill()

        // Fill pill
        let fillWidth = barWidth * CGFloat(usage.sessionPercentage / 100.0)
        if fillWidth > 2 {
            let fillPath = NSBezierPath(roundedRect: NSRect(x: barX, y: barY, width: fillWidth, height: barHeight), xRadius: 3, yRadius: 3)
            fillColor.setFill()
            fillPath.fill()
        }

        return image
    }

    private func createPercentageOnlyStyle(usage: ClaudeUsage, isDarkMode: Bool, monochromeMode: Bool) -> NSImage {
        let percentageText = "\(Int(usage.sessionPercentage))%"
        let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        let textColor: NSColor = isDarkMode ? .white : .black
        let fillColor = monochromeMode ? textColor : getColorForUsageLevel(usage.statusLevel)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: fillColor
        ]

        let textSize = percentageText.size(withAttributes: attributes)
        let image = NSImage(size: NSSize(width: textSize.width + 4, height: 18))

        image.lockFocus()
        defer { image.unlockFocus() }

        let textY = (18 - textSize.height) / 2
        percentageText.draw(at: NSPoint(x: 2, y: textY), withAttributes: attributes)

        return image
    }

    private func createIconWithBarStyle(usage: ClaudeUsage, isDarkMode: Bool, monochromeMode: Bool) -> NSImage {
        let size: CGFloat = 18
        let image = NSImage(size: NSSize(width: size, height: size))

        image.lockFocus()
        defer { image.unlockFocus() }

        let textColor: NSColor = isDarkMode ? .white : .black
        let fillColor = monochromeMode ? textColor : getColorForUsageLevel(usage.statusLevel)

        let percentage = usage.sessionPercentage / 100.0
        let center = NSPoint(x: size / 2, y: size / 2)
        let radius = (size - 4) / 2
        let lineWidth: CGFloat = 3
        let startAngle: CGFloat = 90
        let endAngle = startAngle - (360 * CGFloat(percentage))

        // Background ring
        let bgArcPath = NSBezierPath()
        bgArcPath.appendArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 360, clockwise: false)
        textColor.withAlphaComponent(0.12).setStroke()
        bgArcPath.lineWidth = lineWidth
        bgArcPath.stroke()

        // Progress ring (clockwise from top)
        if percentage > 0 {
            let arcPath = NSBezierPath()
            arcPath.appendArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            fillColor.setStroke()
            arcPath.lineWidth = lineWidth
            arcPath.lineCapStyle = .round
            arcPath.stroke()
        }

        return image
    }

    private func createCompactStyle(usage: ClaudeUsage, isDarkMode: Bool, monochromeMode: Bool) -> NSImage {
        let width: CGFloat = 12
        let height: CGFloat = 18
        let image = NSImage(size: NSSize(width: width, height: height))

        image.lockFocus()
        defer { image.unlockFocus() }

        let textColor: NSColor = isDarkMode ? .white : .black
        let fillColor = monochromeMode ? textColor : getColorForUsageLevel(usage.statusLevel)
        let dotSize: CGFloat = 8

        let dotY = (height - dotSize) / 2
        let dotX = (width - dotSize) / 2
        let dotRect = NSRect(x: dotX, y: dotY, width: dotSize, height: dotSize)
        let dotPath = NSBezierPath(ovalIn: dotRect)
        fillColor.setFill()
        dotPath.fill()

        return image
    }

    private func getColorForUsageLevel(_ level: UsageStatusLevel) -> NSColor {
        switch level {
        case .safe:
            // Matches SettingsColors.accentGreen
            return NSColor(red: 0.28, green: 0.75, blue: 0.42, alpha: 1.0)
        case .moderate:
            // Matches SettingsColors.accentOrange
            return NSColor(red: 0.95, green: 0.55, blue: 0.25, alpha: 1.0)
        case .critical:
            // Matches SettingsColors.error
            return NSColor(red: 0.92, green: 0.34, blue: 0.34, alpha: 1.0)
        }
    }

    private func startAutoRefresh() {
        let interval = dataStore.loadRefreshInterval()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refreshUsage()
        }
    }

    private func restartAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        startAutoRefresh()
    }

    private func observeRefreshIntervalChanges() {
        refreshIntervalObserver = dataStore.userDefaults.observe(\.refreshInterval, options: [.new]) { [weak self] _, change in
            if let newValue = change.newValue, newValue > 0 {
                DispatchQueue.main.async {
                    self?.restartAutoRefresh()
                }
            }
        }
    }

    private func observeAppearanceChanges() {
        appearanceObserver = NSApp.observe(\.effectiveAppearance, options: [.new]) { [weak self] _, _ in
            guard let self = self, let button = self.statusItem?.button else { return }
            DispatchQueue.main.async {
                self.cachedImageKey = ""
                self.updateStatusButton(button, usage: self.usage)
            }
        }
    }

    private func observeIconStyleChanges() {
        iconStyleObserver = NotificationCenter.default.addObserver(
            forName: .menuBarIconStyleChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self, let button = self.statusItem?.button else { return }
            self.cachedImageKey = ""
            self.updateStatusButton(button, usage: self.usage)
        }
    }

    func refreshUsage() {
        Task {
            async let usageResult = apiService.fetchUsageData()
            async let statusResult = statusService.fetchStatus()

            do {
                let newUsage = try await usageResult
                await MainActor.run {
                    self.usage = newUsage
                    dataStore.saveUsage(newUsage)
                    if let button = statusItem?.button {
                        updateStatusButton(button, usage: newUsage)
                    }
                    NotificationManager.shared.checkAndNotify(usage: newUsage)
                }
            } catch {
                // Silent failure
            }

            do {
                let newStatus = try await statusResult
                await MainActor.run {
                    self.status = newStatus
                }
            } catch {
                // Silent failure
            }

            if dataStore.loadAPITrackingEnabled(),
               let apiSessionKey = dataStore.loadAPISessionKey(),
               let orgId = dataStore.loadAPIOrganizationId() {
                do {
                    let newAPIUsage = try await apiService.fetchAPIUsageData(organizationId: orgId, apiSessionKey: apiSessionKey)
                    await MainActor.run {
                        self.apiUsage = newAPIUsage
                        dataStore.saveAPIUsage(newAPIUsage)
                    }
                } catch {
                    // Silent failure
                }
            }
        }
    }

    @objc private func preferencesClicked() {
        closePopoverOrWindow()

        if let existingWindow = settingsWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            NSApp.setActivationPolicy(.regular)

            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)

            let window = NSWindow(contentViewController: hostingController)
            window.title = "CCStats - Settings"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.setContentSize(NSSize(width: 720, height: 600))
            window.center()
            window.isReleasedWhenClosed = false
            window.delegate = self

            self.settingsWindow = window
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc private func quitClicked() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - NSPopoverDelegate
extension MenuBarManager: NSPopoverDelegate {
    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        return true
    }

    func detachableWindow(for popover: NSPopover) -> NSWindow? {
        stopMonitoringForOutsideClicks()

        let newContentViewController = createContentViewController()

        let window = NSWindow(contentViewController: newContentViewController)
        window.title = "CCStats"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 340, height: 500))
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.isRestorable = false
        window.delegate = self

        detachedWindow = window
        return window
    }
}

// MARK: - NSWindowDelegate
extension MenuBarManager: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            if window == settingsWindow {
                NSApp.setActivationPolicy(.accessory)
                settingsWindow = nil
            } else if window == detachedWindow {
                detachedWindow = nil
            }
        }
    }
}
