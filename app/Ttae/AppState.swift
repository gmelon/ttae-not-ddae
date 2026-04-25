import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var correctionEnabled: Bool {
        didSet {
            UserDefaults.standard.set(correctionEnabled, forKey: Key.enabled)
            // updateMonitor 가 isMonitoring (다른 @Published) 을 mutate 하므로
            // view update 사이클 안에서의 publish chain 을 끊어야 함.
            Task { @MainActor in
                self.updateMonitor()
            }
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: Key.launchAtLogin)
            Task { @MainActor in
                LaunchAtLogin.setEnabled(self.launchAtLogin)
            }
        }
    }

    @Published var exceptionWords: [String] {
        didSet { UserDefaults.standard.set(exceptionWords, forKey: Key.exceptionWords) }
    }

    @Published var menuBarIconVisible: Bool {
        didSet { UserDefaults.standard.set(menuBarIconVisible, forKey: Key.menuBarIconVisible) }
    }

    @Published private(set) var correctionCount: Int {
        didSet { UserDefaults.standard.set(correctionCount, forKey: Key.count) }
    }

    @Published private(set) var isMonitoring = false

    @Published private(set) var hasAccessibilityPermission: Bool

    private let monitor = InputMonitor()
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
            Task { @MainActor in
                self?.correctionCount += 1
            }
        }

        updateMonitor()
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

    /// Accessibility 권한 상태가 변하면 UI 와 monitor 를 자동 동기화한다.
    /// 권한 부여 시 사용자가 앱을 재기동할 필요 없이 1초 내로 event tap 이 살아남.
    private func startPermissionWatcher() {
        permissionWatcher = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tickPermissionWatcher() }
        }
    }

    private func tickPermissionWatcher() {
        let trusted = AccessibilityPermission.isTrusted()
        let permissionChanged = trusted != hasAccessibilityPermission
        if permissionChanged {
            hasAccessibilityPermission = trusted
        }
        if correctionEnabled, trusted, !isMonitoring {
            // permission@Published 가 방금 갱신됐을 수 있으므로 다음 tick 으로 미뤄
            // 이중 publish 를 피한다.
            Task { @MainActor in
                self.updateMonitor()
            }
        }
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
