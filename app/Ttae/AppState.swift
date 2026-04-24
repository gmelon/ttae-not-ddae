import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var correctionEnabled: Bool {
        didSet {
            UserDefaults.standard.set(correctionEnabled, forKey: Key.enabled)
            updateMonitor()
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: Key.launchAtLogin)
            LaunchAtLogin.setEnabled(launchAtLogin)
        }
    }

    @Published var exceptionWords: [String] {
        didSet { UserDefaults.standard.set(exceptionWords, forKey: Key.exceptionWords) }
    }

    @Published private(set) var correctionCount: Int {
        didSet { UserDefaults.standard.set(correctionCount, forKey: Key.count) }
    }

    @Published private(set) var isMonitoring = false

    var hasAccessibilityPermission: Bool {
        AccessibilityPermission.isTrusted()
    }

    private let monitor = InputMonitor()

    private enum Key {
        static let enabled = "correctionEnabled"
        static let launchAtLogin = "launchAtLogin"
        static let exceptionWords = "exceptionWords"
        static let count = "correctionCount"
    }

    init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Key.enabled) == nil {
            defaults.set(true, forKey: Key.enabled)
        }
        self.correctionEnabled = defaults.bool(forKey: Key.enabled)
        self.launchAtLogin = LaunchAtLogin.isEnabled
        self.exceptionWords = defaults.stringArray(forKey: Key.exceptionWords) ?? []
        self.correctionCount = defaults.integer(forKey: Key.count)

        monitor.isEnabled = { [weak self] in self?.correctionEnabled ?? false }
        monitor.exceptionWords = { [weak self] in Set(self?.exceptionWords ?? []) }
        monitor.onCorrection = { [weak self] _, _ in
            Task { @MainActor in
                self?.correctionCount += 1
            }
        }

        updateMonitor()
    }

    func addExceptionWord(_ word: String) {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !exceptionWords.contains(trimmed) else { return }
        exceptionWords.append(trimmed)
    }

    func removeExceptionWords(_ words: Set<String>) {
        exceptionWords.removeAll { words.contains($0) }
    }

    func resetCorrectionCount() {
        correctionCount = 0
    }

    func requestAccessibility() {
        AccessibilityPermission.prompt()
        objectWillChange.send()
    }

    private func updateMonitor() {
        if correctionEnabled {
            isMonitoring = monitor.start()
        } else {
            monitor.stop()
            isMonitoring = false
        }
    }
}
