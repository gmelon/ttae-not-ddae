import SwiftUI

@main
struct TtaeApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var state = AppState.shared

    var body: some Scene {
        @Bindable var state = state

        MenuBarExtra(isInserted: $state.menuBarIconVisible) {
            MenuBarPopover()
                .environment(state)
        } label: {
            Image("Logo")
                .renderingMode(.template)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .menuBarExtraStyle(.window)
    }
}
