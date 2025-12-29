//
//  UpdateService.swift
//  CCStats - GitHub Release Update Checker
//
//  Created by Claude Code on 2025-12-29.
//

import Foundation
import AppKit

/// Manages app updates by checking GitHub releases
/// No external dependencies required - uses GitHub API directly
final class UpdateService {
    static let shared = UpdateService()

    // Configure your GitHub repo here
    private let githubOwner = "kyleorin"
    private let githubRepo = "Claude-Usage-Tracker"

    private init() {}

    /// Check for updates by querying GitHub releases API
    func checkForUpdates() {
        Task {
            await checkForUpdatesAsync()
        }
    }

    private func checkForUpdatesAsync() async {
        let urlString = "https://api.github.com/repos/\(githubOwner)/\(githubRepo)/releases/latest"
        guard let url = URL(string: urlString) else { return }

        do {
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

            let (data, _) = try await URLSession.shared.data(for: request)

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let tagName = json["tag_name"] as? String,
               let htmlUrl = json["html_url"] as? String {

                let latestVersion = tagName.replacingOccurrences(of: "v", with: "")
                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

                await MainActor.run {
                    if isNewerVersion(latestVersion, than: currentVersion) {
                        showUpdateAlert(newVersion: latestVersion, downloadURL: htmlUrl)
                    } else {
                        showUpToDateAlert()
                    }
                }
            }
        } catch {
            await MainActor.run {
                showErrorAlert()
            }
        }
    }

    /// Compare version strings (e.g., "1.2.3" vs "1.2.4")
    private func isNewerVersion(_ new: String, than current: String) -> Bool {
        let newComponents = new.split(separator: ".").compactMap { Int($0) }
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(newComponents.count, currentComponents.count) {
            let newPart = i < newComponents.count ? newComponents[i] : 0
            let currentPart = i < currentComponents.count ? currentComponents[i] : 0

            if newPart > currentPart { return true }
            if newPart < currentPart { return false }
        }
        return false
    }

    private func showUpdateAlert(newVersion: String, downloadURL: String) {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "CCStats \(newVersion) is available. You're currently on \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown")."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: downloadURL) {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private func showUpToDateAlert() {
        let alert = NSAlert()
        alert.messageText = "You're Up to Date"
        alert.informativeText = "CCStats \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") is the latest version."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showErrorAlert() {
        let alert = NSAlert()
        alert.messageText = "Update Check Failed"
        alert.informativeText = "Could not check for updates. Please check your internet connection."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
