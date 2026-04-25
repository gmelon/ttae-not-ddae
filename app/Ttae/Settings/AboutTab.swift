import AppKit
import SwiftUI

struct AboutTab: View {
    private let githubURL = URL(string: "https://github.com/gmelon/ttae-not-ddae")!
    private let licenseURL = URL(string: "https://github.com/gmelon/ttae-not-ddae/blob/main/LICENSE")!
    private let versionURL = URL(string: "https://ttae.gmelon.dev/version.txt")!

    @State private var latestVersion: String?
    @State private var checking = true

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            wordmark
                .padding(.bottom, 14)
            Text("세상에 '떄' 라는 글자는 없다.")
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
        .task { await fetchLatest() }
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
        .font(.system(size: 32, weight: .medium))
    }

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    private var hasUpdate: Bool {
        guard let latest = latestVersion else { return false }
        return Self.isVersion(latest, newerThan: currentVersion)
    }

    @ViewBuilder
    private var versionBlock: some View {
        // Grid 로 라벨/값 두 컬럼 정렬. 라벨은 우측 정렬, 값은 좌측 정렬해서
        // 컬럼 경계에 정보가 모이고, 양 행의 값 셀에 동일한 ghost 를 둬서
        // 상태 전환에도 위치가 흔들리지 않는다.
        Grid(horizontalSpacing: 8, verticalSpacing: 4) {
            GridRow {
                Text("현재 버전")
                    .foregroundStyle(.secondary)
                    .gridColumnAlignment(.trailing)
                ZStack(alignment: .leading) {
                    ghostValueText
                    Text(currentVersion)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
                .gridColumnAlignment(.leading)
            }
            GridRow {
                Text("최신 버전")
                    .foregroundStyle(.secondary)
                latestVersionView
            }
        }
        .font(.callout)
    }

    private var ghostValueText: some View {
        // 버전 숫자(99.99.99) 폭만 점유. "· 업데이트 가능" 까지 포함하면 폭이
        // 너무 커져서 visible 컨텐츠가 좌측에 쏠리는 인상을 줌. 업데이트 케이스에서는
        // ZStack 이 자연스럽게 넓어지지만 그건 1회성 전환이라 허용.
        Text("99.99.99")
            .fontWeight(.semibold)
            .foregroundStyle(.clear)
            .accessibilityHidden(true)
    }

    private var latestVersionView: some View {
        ZStack(alignment: .leading) {
            ghostValueText
            latestActualContent
        }
    }

    @ViewBuilder
    private var latestActualContent: some View {
        if let latest = latestVersion {
            if hasUpdate {
                Button(action: openDownload) {
                    HStack(spacing: 4) {
                        Text(latest)
                            .fontWeight(.semibold)
                        Text("· 업데이트 가능")
                            .font(.caption)
                    }
                    .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
            } else {
                Text(latest)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
        } else if checking {
            Text("확인 중…")
                .foregroundStyle(.tertiary)
        } else {
            Text("—")
                .foregroundStyle(.tertiary)
        }
    }

    private var links: some View {
        VStack(spacing: 8) {
            Link(destination: githubURL) {
                HStack(spacing: 6) {
                    MageIcon("link", size: 14)
                    Text("GitHub 리포지토리")
                }
            }
            Link(destination: licenseURL) {
                HStack(spacing: 6) {
                    MageIcon("file", size: 14)
                    Text("오픈소스 라이선스 (MIT)")
                }
            }
        }
        .font(.callout)
    }

    private func fetchLatest() async {
        checking = true
        defer { checking = false }
        var request = URLRequest(url: versionURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 8)
        request.setValue("text/plain", forHTTPHeaderField: "Accept")
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let text = (String(data: data, encoding: .utf8) ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty, text.allSatisfy({ $0.isNumber || $0 == "." }) else { return }
            latestVersion = text
        } catch {
            // silent — UI shows fallback
        }
    }

    private func openDownload() {
        guard let latest = latestVersion else { return }
        let urlString = "https://github.com/gmelon/ttae-not-ddae/releases/latest/download/Ttae-\(latest).dmg"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    private static func isVersion(_ a: String, newerThan b: String) -> Bool {
        let ac = a.split(separator: ".").compactMap { Int($0) }
        let bc = b.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(ac.count, bc.count) {
            let av = i < ac.count ? ac[i] : 0
            let bv = i < bc.count ? bc[i] : 0
            if av != bv { return av > bv }
        }
        return false
    }
}
