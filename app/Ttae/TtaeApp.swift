import SwiftUI

@main
struct TtaeApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent()
                .environmentObject(state)
        } label: {
            Image(systemName: state.correctionEnabled
                  ? "character.bubble.fill"
                  : "character.bubble")
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .environmentObject(state)
                .frame(width: 520, height: 440)
        }
    }
}
