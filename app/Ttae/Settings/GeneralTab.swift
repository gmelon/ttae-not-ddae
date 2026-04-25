import SwiftUI

struct GeneralTab: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        Form {
            Section {
                Toggle("자동 교정 사용", isOn: $state.correctionEnabled)
                    .help("한글 쌍자음 + ㅒ/ㅖ 처럼 사전에 존재할 수 없는 음절을 자동으로 교정합니다.")
            } header: {
                Text("교정")
            }

            Section {
                Toggle("로그인 시 자동 실행", isOn: $state.launchAtLogin)
            } header: {
                Text("시작")
            }

            Section {
                LabeledContent("교정된 오타") {
                    Text("\(state.correctionCount)회")
                        .contentTransition(.numericText())
                        .animation(.snappy, value: state.correctionCount)
                        .monospacedDigit()
                }
                if state.correctionCount > 0 {
                    Button("카운터 초기화", role: .destructive) {
                        state.resetCorrectionCount()
                    }
                }
            } header: {
                Text("통계")
            }

            Section {
                if state.hasAccessibilityPermission {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Accessibility 권한이 부여되어 있습니다")
                    }
                    .font(.callout)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("Accessibility 권한이 필요합니다")
                                .fontWeight(.medium)
                        }
                        Text("시스템 설정 > 개인 정보 보호 및 보안 > 손쉬운 사용 에서 떄가아니라때를 허용해 주세요.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Button("권한 요청 / 시스템 설정 열기") {
                            state.requestAccessibility()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 2)
                }
            } header: {
                Text("권한")
            }
        }
        .formStyle(.grouped)
    }
}
