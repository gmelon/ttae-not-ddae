import SwiftUI

struct AboutTab: View {
    private let githubURL = URL(string: "https://github.com/gmelon/ttae-not-ddae")!
    private let licenseURL = URL(string: "https://github.com/gmelon/ttae-not-ddae/blob/main/LICENSE")!

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            wordmark
                .padding(.bottom, 14)

            Text("세상에 '떄' 라는 말은 없다.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.bottom, 26)

            versionBlock

            Spacer()

            links

            Spacer().frame(height: 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    private var wordmark: some View {
        HStack(spacing: 0) {
            Text("떄")
                .strikethrough(true, color: .red.opacity(0.7))
                .foregroundStyle(.tertiary)
            Text(" 가 아니라 ")
                .foregroundStyle(.secondary)
            Text("때")
                .foregroundStyle(Color.accentColor)
                .fontWeight(.semibold)
        }
        .font(.system(size: 32, weight: .medium))
    }

    private var versionBlock: some View {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return VStack(spacing: 2) {
            Text("버전 \(version)")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("빌드 \(build)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private var links: some View {
        VStack(spacing: 8) {
            Link(destination: githubURL) {
                Label("GitHub 리포지토리", systemImage: "arrow.up.right.square")
            }
            Link(destination: licenseURL) {
                Label("오픈소스 라이선스 (MIT)", systemImage: "doc.text")
            }
        }
        .font(.callout)
    }
}
