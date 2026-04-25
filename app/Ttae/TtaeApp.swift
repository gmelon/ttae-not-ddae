import SwiftUI

@main
struct TtaeApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @StateObject private var state = AppState()

    var body: some Scene {
        MenuBarExtra(isInserted: $state.menuBarIconVisible) {
            MenuBarPopover()
                .environmentObject(state)
        } label: {
            Image("Logo")
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(state)
                .frame(width: 540, height: 460)
        }
    }
}
