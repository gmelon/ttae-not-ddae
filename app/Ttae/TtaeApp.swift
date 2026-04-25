import SwiftUI

@main
struct TtaeApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarPopover()
                .environmentObject(state)
        } label: {
            Text("때")
                .font(.system(size: 14, weight: .semibold))
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(state)
                .frame(width: 540, height: 460)
        }
    }
}
