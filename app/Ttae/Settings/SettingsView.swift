import AppKit
import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case exceptions
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "일반"
        case .exceptions: return "예외 단어"
        case .about: return "정보"
        }
    }

    var systemIcon: String {
        switch self {
        case .general: return "gearshape"
        case .exceptions: return "text.badge.xmark"
        case .about: return "info.circle"
        }
    }

    var toolbarIdentifier: NSToolbarItem.Identifier {
        NSToolbarItem.Identifier(rawValue: "dev.gmelon.ttae.settings.\(rawValue)")
    }

    init?(toolbarIdentifier: NSToolbarItem.Identifier) {
        let prefix = "dev.gmelon.ttae.settings."
        let raw = toolbarIdentifier.rawValue
        guard raw.hasPrefix(prefix) else { return nil }
        self.init(rawValue: String(raw.dropFirst(prefix.count)))
    }
}

@MainActor
@Observable
final class SettingsRouter {
    static let shared = SettingsRouter()
    var selectedTab: SettingsTab = .general
    private init() {}
}

struct SettingsView: View {
    @State private var router = SettingsRouter.shared

    var body: some View {
        Group {
            switch router.selectedTab {
            case .general: GeneralTab()
            case .exceptions: ExceptionsTab()
            case .about: AboutTab()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
