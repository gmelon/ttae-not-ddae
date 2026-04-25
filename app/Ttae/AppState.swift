import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var correctionEnabled: Bool {
        didSet {
            UserDefaults.standard.set(correctionEnabled, forKey: Key.enabled)
            // didSet 내부에서 동기적으로 다른 publish/heavy work 를 하면 SwiftUI 의 view update
            // 사이클 안에서 변화가 발생해 'Publishing changes from within view updates' 경고가 뜨므로
            // 무거운 side effect 는 항상 다음 runloop tick 으로 미룬다.
            DispatchQueue.main.async { [weak self] in
                self?.updateMonitor()
            }
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: Key.launchAtLogin)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
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

    @Published private(set) var hasAccessibilityPermission: Bool

    /// 모니터링 상태는 다른 두 @Published 로부터 파생되는 computed.
    var isMonitoring: Bool {
        correctionEnabled && hasAccessibilityPermission
    }

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
        // CGEventTap 콜백은 임의의 스레드. 카운터 증가는 메인 runloop 다음 tick 에서 처리해야
        // SwiftUI view update 사이클과 충돌하지 않음.
        monitor.onCorrection = { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.correctionCount += 1
            }
        }

        // init 직후의 monitor 시작도 view 가 처음 그려진 다음 tick 에서 안전하게.
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
            // Timer 콜백 안에서 직접 @Published 를 mutate 하지 말고 다음 tick 으로 미룬다.
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
