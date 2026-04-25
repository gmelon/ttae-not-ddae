# 떄가아니라때

> 세상에 '떄' 라는 글자는 없다.

한글을 빠르게 치다 보면 Shift 가 모음까지 따라가서 떄·꺠·뺴·쨰 같은,
한국어에 존재할 수 없는 글자가 찍힙니다. **떄가아니라때** 는 이 패턴을
입력되는 즉시 감지하고 올바른 글자로 교정하는 macOS 메뉴바 앱입니다.

랜딩: <https://ttae.gmelon.dev>
다운로드: <https://github.com/gmelon/ttae-not-ddae/releases/latest>

## 특징

- **즉시 교정** — 잘못된 글자가 찍히는 순간 backspace + 올바른 글자가 자동으로 들어갑니다.
- **한글 입력일 때만 동작** — 두벌식 한국어 입력 모드일 때만 작동, 영문이나 코드 작성 중에는 끼어들지 않습니다.
- **메뉴바에 조용히 상주** — Dock 에 뜨지 않고, 메뉴바 아이콘도 숨길 수 있습니다.
- **데이터 외부 전송 없음** — 모든 처리는 로컬에서만 일어나며, 코드 전체가 공개되어 있어 직접 검증 가능합니다.

## 교정 대상

쌍자음(ㄲ ㄸ ㅃ ㅆ ㅉ) 과 이중모음(ㅒ ㅖ) 결합 — 사전 어디에도 등장하지 않는 10개 글자.

| 잘못 → 올바른 |
| --- |
| 떄 → 때, 뗴 → 떼 |
| 꺠 → 깨, 꼐 → 께 |
| 뺴 → 빼, 뼤 → 뻬 |
| 썌 → 쌔, 쎼 → 쎄 |
| 쨰 → 째, 쪠 → 쩨 |

그 외 글자는 절대 건드리지 않습니다.

## 시스템 요구사항

- macOS 14 (Sonoma) 이상
- 두벌식 한국어 입력 소스
- 시스템 설정 > 개인 정보 보호 및 보안 > 손쉬운 사용 권한

## 설치

1. [최신 릴리즈](https://github.com/gmelon/ttae-not-ddae/releases/latest) 에서 `Ttae-X.Y.Z.dmg` 다운로드
2. 더블 클릭 후 `Ttae.app` 을 `Applications` 폴더로 드래그
3. 처음 실행 시 시스템 설정 > 개인 정보 보호 및 보안 > 손쉬운 사용 에서 권한 켜기

Apple Developer ID 로 서명되어 있어 Gatekeeper 경고 없이 설치됩니다.

## 개발

```sh
cd app

# Xcode 에서 열기
open Ttae.xcodeproj

# 또는 CLI 빌드
xcodebuild -project Ttae.xcodeproj -scheme Ttae -configuration Debug build

# 핵심 로직 단위 테스트
swift test
```

### 프로젝트 구조

| 디렉터리 | 내용 |
| --- | --- |
| `app/` | macOS 앱 (Xcode 프로젝트) |
| `app/Ttae/` | 앱 소스 (SwiftUI + AppKit) |
| `app/Sources/TtaeCore/` | 한글 음절 분해/합성, 교정 룰 (SwiftPM 라이브러리) |
| `app/Tests/TtaeCoreTests/` | TtaeCore 단위 테스트 |
| `landing/` | 랜딩 페이지 (Astro 6, Cloudflare Pages 로 배포) |

`app/Ttae.xcodeproj` 는 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 으로 `app/project.yml` 에서 생성되며 리포에 함께 커밋됩니다. 구조적 변경(파일 추가·빌드 설정 등) 은 `project.yml` 수정 후 `xcodegen generate` 로 반영합니다. 단순 파일 편집은 Xcode 에서 직접 해도 됩니다.

### 브랜치 전략

- `develop` — 기본 브랜치. 모든 기능 작업이 모이는 곳. PR 의 base
- `main` — 릴리즈 브랜치. push 가 들어오면 GitHub Actions 가 서명·공증·릴리즈를 자동으로 만듭니다. 직접 작업하지 않음

### 릴리즈 절차

1. `app/project.yml` 의 `MARKETING_VERSION` 을 새 버전(예: `1.0.1`) 으로 bump
2. develop → main PR 머지
3. release.yml 이 자동 동작 — Xcode build → Developer ID 서명 → notary 공증 → `.dmg` + SHA-256 + `vX.Y.Z` 태그 + GitHub Release 업로드
4. 같은 버전 태그가 이미 있으면 release.yml 은 스킵

### CI / Release 워크플로

- `.github/workflows/ci.yml` — PR 과 develop/main push 시 `swift test` + 미서명 `xcodebuild` 빌드
- `.github/workflows/release.yml` — main push 시 `MARKETING_VERSION` 읽어서 build → 서명 → 공증 → DMG → Release. concurrency group 으로 직렬화

필요한 GitHub Secrets:

- `DEVELOPER_ID_CERTIFICATE_P12`, `DEVELOPER_ID_CERTIFICATE_PASSWORD` — Apple Developer ID Application 인증서
- `KEYCHAIN_PASSWORD` — 임시 빌드 키체인 패스워드
- `APP_STORE_CONNECT_KEY_P8`, `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID` — notarytool 용 App Store Connect API 키

### 랜딩 페이지

```sh
cd landing
npm install
npm run dev      # http://localhost:4321
npm run build
```

`landing/src/pages/version.txt.ts` 가 빌드 타임에 GitHub Releases API 를 조회해 `dist/version.txt` 로 최신 버전을 출력합니다. 앱은 안내 탭에서 이 엔드포인트를 fetch 해 업데이트 가능 여부를 표시합니다.

배포는 Cloudflare Pages — `landing/` 디렉터리를 root 로 두고 main push 시 자동 배포 + PR 마다 preview URL 발급.

## 라이선스

[MIT License](LICENSE).

## Third-party

- [Mage Icons](https://mageicons.com/) (Apache License 2.0) — 설정 UI 아이콘
- [Pretendard](https://github.com/orioncactus/pretendard) (SIL Open Font License 1.1) — 랜딩 페이지 폰트
- Apple 로고 SVG (Font Awesome free, CC BY 4.0) — 랜딩 다운로드 버튼
