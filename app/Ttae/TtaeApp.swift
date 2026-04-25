import SwiftUI

@main
struct TtaeApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        MenuBarExtra(isInserted: $state.menuBarIconVisible) {
            MenuBarPopover()
                .environmentObject(state)
        } label: {
            Image("Logo")
                .resizable()
                .interpolation(.high)
                .frame(width: 18, height: 18)
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
