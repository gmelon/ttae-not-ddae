import AppKit
import SwiftUI

struct MenuBarPopover: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var state = state

        VStack(spacing: 0) {
            header
            counter

            softDivider
            Toggle("자동 교정", isOn: $state.correctionEnabled)
                .toggleStyle(.switch)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

            if !state.hasAccessibilityPermission {
                softDivider
                permissionBanner
            }

            softDivider
            footer
        }
        .frame(width: 264)
    }

    private var softDivider: some View {
        Divider().opacity(0.5)
    }

    private var header: some View {
        HStack(spacing: 0) {
            wordmark
            Spacer()
            statusDot
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private var wordmark: some View {
        HStack(spacing: 0) {
            Text("떄")
                .strikethrough(true, color: .red.opacity(0.7))
                .foregroundStyle(.tertiary)
            Text(" 가 아니라 ")
                .foregroundStyle(.secondary)
            Text("때")
                .foregroundStyle(.primary)
                .fontWeight(.semibold)
        }
        .font(.system(size: 13, weight: .medium))
    }

    private var statusDot: some View {
        Circle()
            .fill(state.isMonitoring ? Color.green : Color.secondary.opacity(0.5))
            .frame(width: 7, height: 7)
            .help(state.isMonitoring ? "활성" : "비활성")
            .animation(.easeInOut(duration: 0.2), value: state.isMonitoring)
    }

    private var counter: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("\(state.correctionCount)")
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .contentTransition(.numericText())
                .animation(.snappy, value: state.correctionCount)
            Text("회 교정함")
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
    }

    private var permissionBanner: some View {
        HStack(spacing: 10) {
            MageIcon("warning", size: 16)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 1) {
                Text("권한이 필요합니다")
                    .font(.caption)
                    .fontWeight(.medium)
                Text("Accessibility 허용 후 사용 가능")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("부여") { state.requestAccessibility() }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.08))
    }

    private var footer: some View {
        HStack(spacing: 0) {
            footerButton(title: "환경설정", icon: "settings", shortcut: ",") {
                AppDelegate.shared?.showSettings()
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 16).opacity(0.5)

            footerButton(title: "종료", icon: "logout", shortcut: "q") {
                NSApp.terminate(nil)
            }
            .frame(maxWidth: .infinity)
        }
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
    }

    private func footerButton(
        title: String,
        icon: String,
        shortcut: KeyEquivalent,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Spacer(minLength: 0)
                MageIcon(icon, size: 13)
                Text(title)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(shortcut)
    }
}
