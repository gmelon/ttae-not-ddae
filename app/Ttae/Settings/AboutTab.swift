import SwiftUI

struct AboutTab: View {
    private let githubURL = URL(string: "https://github.com/gmelon/ttae-not-ddae")!
    private let licenseURL = URL(string: "https://github.com/gmelon/ttae-not-ddae/blob/main/LICENSE")!

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Text("떄가아니라때")
                .font(.largeTitle)
                .bold()

            Text("세상에 '떄' 라는 말은 없다.")
                .font(.title3)
                .foregroundStyle(.secondary)

            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
            Text("버전 \(version) (\(build))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()
                .padding(.horizontal, 60)

            VStack(spacing: 8) {
                Link("GitHub 리포지토리", destination: githubURL)
                Link("오픈소스 라이선스 (MIT)", destination: licenseURL)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
