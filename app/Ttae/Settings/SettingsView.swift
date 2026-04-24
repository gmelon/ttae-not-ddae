import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralTab()
                .tabItem { Label("일반", systemImage: "gearshape") }
            ExceptionsTab()
                .tabItem { Label("예외 단어", systemImage: "text.badge.xmark") }
            AboutTab()
                .tabItem { Label("정보", systemImage: "info.circle") }
        }
    }
}
