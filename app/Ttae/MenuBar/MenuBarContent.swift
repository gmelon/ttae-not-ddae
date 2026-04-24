import AppKit
import SwiftUI

struct MenuBarContent: View {
    @EnvironmentObject var state: AppState
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Toggle("자동 교정 사용", isOn: $state.correctionEnabled)

        Divider()

        Text("교정된 오타: \(state.correctionCount)회")

        Divider()

        if !state.hasAccessibilityPermission {
            Button("Accessibility 권한 부여…") {
                state.requestAccessibility()
            }
            Divider()
        }

        Button("환경설정…") {
            openSettings()
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut(",")

        Button("종료") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
