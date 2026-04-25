import AppKit
import SwiftUI

/// LSUIElement=YES 라 메뉴바 아이콘을 숨기면 앱을 다시 부를 진입점이 사라진다.
/// Finder/Spotlight 에서 Ttae.app 을 다시 열면 reopen 이벤트가 들어오는데, 이때
/// 환경설정 창을 띄워 사용자가 다시 메뉴바 아이콘 토글을 켤 수 있게 한다.
///
/// SwiftUI 의 `Settings` scene 은 macOS 14+ 의 LSUIElement 상태에서 reopen 시
/// `showSettingsWindow:` 액션이 통과되어도 윈도우를 만들어주지 않는 quirk 가 있어,
/// 직접 NSWindow + NSHostingController 로 환경설정 창을 관리한다. 메뉴바의
/// 환경설정 버튼도 같은 진입점을 사용한다.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var settingsWindow: NSWindow?

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        showSettings()
        return true
    }

    @MainActor
    func showSettings() {
        let isFirstTime = settingsWindow == nil
        if isFirstTime {
            createSettingsWindow()
        }

        // .accessory(LSUIElement) 상태에선 활성화가 막힐 수 있어 일단 .regular 로.
        // 창이 닫히면 windowWillClose 에서 다시 .accessory 로 복귀해 Dock 아이콘 제거.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        if isFirstTime {
            settingsWindow?.center()
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @MainActor
    private func createSettingsWindow() {
        let host = NSHostingController(
            rootView: SettingsView()
                .environment(AppState.shared)
                .frame(width: 540, height: 460)
        )
        let window = NSWindow(contentViewController: host)
        window.title = "환경설정"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        settingsWindow = window
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
