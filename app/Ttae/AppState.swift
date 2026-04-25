import Foundation
import os
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    private static let logger = Logger(subsystem: "dev.gmelon.ttae", category: "AppState")

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

    @Published private(set) var hasAccessibilityPermission: Bool

    private let monitor = InputMonitor()
    private var permissionWatcher: Timer?

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
        self.hasAccessibilityPermission = AccessibilityPermission.isTrusted()

        monitor.isEnabled = { [weak self] in self?.correctionEnabled ?? false }
        monitor.exceptionWords = { [weak self] in Set(self?.exceptionWords ?? []) }
        monitor.onCorrection = { [weak self] _, _ in
            Task { @MainActor in
                self?.correctionCount += 1
            }
        }

        log("init: enabled=\(self.correctionEnabled), launchAtLogin=\(self.launchAtLogin), exceptions=\(self.exceptionWords.count), permission=\(self.hasAccessibilityPermission)")

        updateMonitor()
        startPermissionWatcher()
    }

    private func log(_ message: String) {
        Self.logger.info("\(message, privacy: .public)")
        print("[Ttae][AppState] \(message)")
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
    /// 권한이 새로 부여된 경우에도 사용자가 앱을 재기동할 필요 없이 1초 내로 event tap 이 살아남.
    private func startPermissionWatcher() {
        permissionWatcher = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tickPermissionWatcher() }
        }
    }

    private func tickPermissionWatcher() {
        let trusted = AccessibilityPermission.isTrusted()
        if trusted != hasAccessibilityPermission {
            log("permission state changed: \(hasAccessibilityPermission) -> \(trusted)")
            hasAccessibilityPermission = trusted
        }
        if correctionEnabled, trusted, !isMonitoring {
            log("retrying monitor.start() after permission flip")
            updateMonitor()
        }
    }

    private func updateMonitor() {
        if correctionEnabled {
            let started = monitor.start()
            isMonitoring = started
            log("updateMonitor: enabled=true monitor.start()=\(started)")
        } else {
            monitor.stop()
            isMonitoring = false
            log("updateMonitor: enabled=false monitor stopped")
        }
    }
}
