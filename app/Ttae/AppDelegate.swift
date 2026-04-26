import AppKit
import SwiftUI

/// LSUIElement=YES 라 메뉴바 아이콘을 숨기면 앱을 다시 부를 진입점이 사라진다.
/// Finder/Spotlight 에서 Ttae.app 을 다시 열면 reopen 이벤트가 들어오는데, 이때
/// 환경설정 창을 띄워 사용자가 다시 메뉴바 아이콘 토글을 켤 수 있게 한다.
///
/// SwiftUI 의 `Settings` scene 은 macOS 14+ 의 LSUIElement 상태에서 reopen 시
/// `showSettingsWindow:` 액션이 통과되어도 윈도우를 만들어주지 않는 quirk 가 있어,
/// 직접 NSWindow + NSHostingController 로 환경설정 창을 관리한다. 메뉴바의
/// 환경설정 버튼도 같은 진입점을 사용한다. NSToolbar 로 macOS Settings 스타일의
/// 상단 탭을 구성하고, 클릭 시 SettingsRouter 로 SwiftUI 본문을 전환한다.
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// SwiftUI 의 `@NSApplicationDelegateAdaptor` 는 우리 AppDelegate 를 그대로
    /// `NSApp.delegate` 로 두지 않고 내부 proxy 로 감싸므로, `NSApp.delegate as? AppDelegate`
    /// 캐스트가 항상 실패한다. 메뉴바 popover 등 SwiftUI 바깥에서 진입할 때 사용할
    /// 우리 인스턴스를 직접 보관한다.
    static private(set) var shared: AppDelegate?

    private var settingsWindow: NSWindow?

    override init() {
        super.init()
        Self.shared = self
    }

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

        NSApp.setActivationPolicy(.regular)

        // MenuBarExtra(.window) popover 액션에서 호출될 때 popover 닫힘과 윈도우
        // 띄우기가 같은 런루프에서 부딪힐 수 있어 한 틱 미뤄 띄운다.
        DispatchQueue.main.async { [weak self] in
            guard let self, let window = self.settingsWindow else { return }
            NSApp.activate(ignoringOtherApps: true)
            if isFirstTime {
                window.center()
            }
            window.makeKeyAndOrderFront(nil)
        }
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
        window.toolbarStyle = .preference
        window.isReleasedWhenClosed = false
        window.delegate = self

        let toolbar = NSToolbar(identifier: "dev.gmelon.ttae.settings")
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        toolbar.selectedItemIdentifier = SettingsTab.general.toolbarIdentifier
        window.toolbar = toolbar

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

extension AppDelegate: NSToolbarDelegate {
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        SettingsTab.allCases.map(\.toolbarIdentifier)
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        guard let tab = SettingsTab(toolbarIdentifier: itemIdentifier) else { return nil }
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.label = tab.title
        item.image = NSImage(
            systemSymbolName: tab.systemIcon,
            accessibilityDescription: tab.title
        )
        item.action = #selector(toolbarItemClicked(_:))
        item.target = self
        return item
    }

    @MainActor
    @objc private func toolbarItemClicked(_ sender: NSToolbarItem) {
        if let tab = SettingsTab(toolbarIdentifier: sender.itemIdentifier) {
            SettingsRouter.shared.selectedTab = tab
        }
    }
}
