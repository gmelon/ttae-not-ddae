import AppKit

/// 앱이 이미 실행 중인 상태에서 사용자가 Spotlight/Finder/Cmd+Tab 등으로 다시 실행하려 하면 호출됨.
/// LSUIElement=YES 라 메뉴바 아이콘이 숨겨져 있을 때 진입점이 사라지는데, 이때 환경설정 창을 띄워
/// 사용자가 메뉴바 아이콘 토글을 다시 켤 수 있도록 한다.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        return true
    }
}
