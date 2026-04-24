import SwiftUI

struct GeneralTab: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        Form {
            Section("교정") {
                Toggle("자동 교정 사용", isOn: $state.correctionEnabled)
                    .help("한글 쌍자음 + ㅒ/ㅖ 처럼 사전에 존재할 수 없는 음절을 자동으로 올바른 음절로 교정합니다.")
            }

            Section("시작") {
                Toggle("로그인 시 자동 실행", isOn: $state.launchAtLogin)
            }

            Section("통계") {
                LabeledContent("교정된 오타", value: "\(state.correctionCount)회")
                Button("카운터 초기화") {
                    state.resetCorrectionCount()
                }
            }

            Section("권한") {
                if state.hasAccessibilityPermission {
                    Label("Accessibility 권한이 부여되었습니다.", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Accessibility 권한이 필요합니다.", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("시스템 설정 > 개인 정보 보호 및 보안 > 손쉬운 사용 에서 떄가아니라때를 허용해 주세요.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("권한 요청 / 시스템 설정 열기") {
                            state.requestAccessibility()
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}
