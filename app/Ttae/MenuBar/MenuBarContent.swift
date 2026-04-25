import AppKit
import SwiftUI

struct MenuBarPopover: View {
    @EnvironmentObject var state: AppState
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 0) {
            header
            counter
            Divider()
            toggleRow

            if !state.hasAccessibilityPermission {
                Divider()
                permissionBanner
            }

            Divider()
            footer
        }
        .frame(width: 260)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("떄가아니라때")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
            Spacer()
            statusDot
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)
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

    private var toggleRow: some View {
        Toggle(isOn: $state.correctionEnabled) {
            Text("자동 교정")
                .font(.body)
        }
        .toggleStyle(.switch)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var permissionBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
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
        .padding(.vertical, 9)
        .background(Color.orange.opacity(0.08))
    }

    private var footer: some View {
        HStack(spacing: 0) {
            footerButton(title: "환경설정", systemImage: "gearshape", shortcut: ",") {
                openSettings()
                NSApp.activate(ignoringOtherApps: true)
            }
            Divider().frame(height: 18)
            footerButton(title: "종료", systemImage: "power", shortcut: "q") {
                NSApp.terminate(nil)
            }
        }
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
    }

    private func footerButton(
        title: String,
        systemImage: String,
        shortcut: KeyEquivalent,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .padding(.vertical, 9)
        }
        .buttonStyle(.plain)
        .keyboardShortcut(shortcut)
    }
}
