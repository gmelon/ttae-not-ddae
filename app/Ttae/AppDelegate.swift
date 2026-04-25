import AppKit

/// LSUIElement=YES 라 메뉴바 아이콘을 숨기면 앱을 다시 부를 진입점이 사라진다.
/// Finder/Spotlight 에서 Ttae.app 을 다시 열면 reopen 이벤트가 들어오는데, 이때
/// 환경설정 창을 띄워 사용자가 다시 메뉴바 아이콘 토글을 켤 수 있게 한다.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        showSettings()
        return true
    }

    private func showSettings() {
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async {
            NSApp.sendAction(
                Selector(("showSettingsWindow:")),
                to: nil,
                from: nil
            )
        }
    }
}
