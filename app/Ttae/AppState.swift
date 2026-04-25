import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class AppState {
    static let shared = AppState()

    var correctionEnabled: Bool {
        didSet {
            UserDefaults.standard.set(correctionEnabled, forKey: Key.enabled)
            DispatchQueue.main.async { [weak self] in
                self?.updateMonitor()
            }
        }
    }

    var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: Key.launchAtLogin)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                LaunchAtLogin.setEnabled(self.launchAtLogin)
            }
        }
    }

    var exceptionWords: [String] {
        didSet { UserDefaults.standard.set(exceptionWords, forKey: Key.exceptionWords) }
    }

    var menuBarIconVisible: Bool {
        didSet { UserDefaults.standard.set(menuBarIconVisible, forKey: Key.menuBarIconVisible) }
    }

    private(set) var correctionCount: Int {
        didSet { UserDefaults.standard.set(correctionCount, forKey: Key.count) }
    }

    private(set) var hasAccessibilityPermission: Bool

    /// 모니터링 상태는 다른 두 값으로부터 파생되는 computed.
    var isMonitoring: Bool {
        correctionEnabled && hasAccessibilityPermission
    }

    @ObservationIgnored
    private let monitor = InputMonitor()
    @ObservationIgnored
    private var permissionWatcher: Timer?

    private enum Key {
        static let enabled = "correctionEnabled"
        static let launchAtLogin = "launchAtLogin"
        static let exceptionWords = "exceptionWords"
        static let count = "correctionCount"
        static let menuBarIconVisible = "menuBarIconVisible"
    }

    init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Key.enabled) == nil {
            defaults.set(true, forKey: Key.enabled)
        }
        if defaults.object(forKey: Key.menuBarIconVisible) == nil {
            defaults.set(true, forKey: Key.menuBarIconVisible)
        }
        self.correctionEnabled = defaults.bool(forKey: Key.enabled)
        self.launchAtLogin = LaunchAtLogin.isEnabled
        self.exceptionWords = defaults.stringArray(forKey: Key.exceptionWords) ?? []
        self.menuBarIconVisible = defaults.bool(forKey: Key.menuBarIconVisible)
        self.correctionCount = defaults.integer(forKey: Key.count)
        self.hasAccessibilityPermission = AccessibilityPermission.isTrusted()

        monitor.isEnabled = { [weak self] in self?.correctionEnabled ?? false }
        monitor.exceptionWords = { [weak self] in Set(self?.exceptionWords ?? []) }
        monitor.onCorrection = { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.correctionCount += 1
            }
        }

        DispatchQueue.main.async { [weak self] in
            self?.updateMonitor()
        }
        startPermissionWatcher()
    }

    deinit {
        permissionWatcher?.invalidate()
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
    }

    private func startPermissionWatcher() {
        permissionWatcher = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.tickPermissionWatcher() }
        }
    }

    private func tickPermissionWatcher() {
        let trusted = AccessibilityPermission.isTrusted()
        if trusted != hasAccessibilityPermission {
            hasAccessibilityPermission = trusted
        }
        if correctionEnabled, trusted {
            updateMonitor()
        }
    }

    private func updateMonitor() {
        if correctionEnabled {
            _ = monitor.start()
        } else {
            monitor.stop()
        }
    }
}
