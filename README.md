# 떄가아니라때

> 세상에 '떄' 라는 말은 없다.

한글을 빠르게 치다 보면 Shift 를 모음까지 눌러버려서 "떄", "쨰", "꺠", "뺴" 같은
존재할 수 없는 음절이 자주 입력됩니다. 「떄가아니라때」는 이런 오타를 실시간으로 감지하여
올바른 음절로 자동 교정해 주는 가벼운 macOS 메뉴바 앱입니다.

### 상태

초기 구현 중입니다. 현재 마일스톤 M2 (앱 UI 셸) 완료.

- M1 완료: 한글 음절 분해/합성 유틸(TtaeCore), Tier 1 교정 룰, CGEventTap 기반 입력 감지 PoC
- M2 완료: Xcode 앱 프로젝트, MenuBarExtra, 설정 창(일반·예외 단어·정보), 로그인 시 자동 실행(SMAppService), Accessibility 권한 플로우
- M3 진행 예정: 실제 backspace + 재입력 교정, IME 조합 상태 처리, 배포 파이프라인(Developer ID 서명 + 공증)

### 예정된 주요 기능

- 떄 → 때, 쨰 → 째, 꺠 → 깨, 뺴 → 빼 등 쌍자음 + ㅒ/ㅖ 오타 자동 교정
- 메뉴바 상주형 앱, 설정 창 하나의 간결한 구성
- 교정 on/off 토글 및 예외 단어 관리
- 로그인 시 자동 실행

### 개발 / 실행

프로젝트 루트는 `app/` 입니다. 앱은 Xcode 에서 열고, 핵심 로직은 SwiftPM 으로 단독 테스트 가능합니다.

```sh
cd app

# 앱 빌드/실행
open Ttae.xcodeproj                 # Xcode 에서 Run

# 또는 CLI 빌드
xcodebuild -project Ttae.xcodeproj -scheme Ttae -configuration Debug build

# 핵심 로직 단위 테스트 (TtaeCore)
swift test
```

`Ttae.xcodeproj` 는 `project.yml` 로부터 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 으로 생성되며 리포에 함께 커밋됩니다. 구조적 변경(파일 추가, 빌드 설정 등)은 `project.yml` 수정 후 `xcodegen generate` 로 반영합니다. 단순한 파일 편집은 Xcode 에서 직접 해도 됩니다.

최초 실행 시 "시스템 설정 > 개인 정보 보호 및 보안 > 손쉬운 사용" 에서 떄가아니라때에 권한을 부여해야 합니다. 앱 내 설정 화면에서 해당 설정을 바로 열 수 있습니다.

### 브랜치 전략

- `develop` (기본 브랜치): 모든 기능 작업이 모이는 곳. PR 의 base 는 `develop`
- `main` (릴리즈 브랜치): 여기에 push 가 들어오면 GitHub Actions 가 자동으로 서명·공증·릴리즈를 만듭니다. 직접 작업하지 않음
- 릴리즈 절차: `app/project.yml` 의 `MARKETING_VERSION` 을 새 버전(예: `0.2.0`) 으로 올리는 커밋을 `develop` 에 머지 → `develop` → `main` PR/머지 → main push 시 release.yml 이 동작 → `.dmg` + `vX.Y.Z` 태그 자동 생성

### CI / Release 워크플로

- `.github/workflows/ci.yml` — PR 과 develop/main push 시 swift test + 미서명 xcodebuild 빌드
- `.github/workflows/release.yml` — main push 시 `app/project.yml` 의 `MARKETING_VERSION` 읽어서 build → Developer ID 서명 → 공증 → DMG → Release 업로드 → 태그 push. 동일 버전 태그가 이미 있으면 스킵
- 필요한 GitHub Secrets: `DEVELOPER_ID_CERTIFICATE_P12`, `DEVELOPER_ID_CERTIFICATE_PASSWORD`, `KEYCHAIN_PASSWORD`, `APP_STORE_CONNECT_KEY_P8`, `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`

### 라이선스

MIT License. 자세한 내용은 [LICENSE](LICENSE) 참고.

### Third-party

- 아이콘: [Mage Icons](https://mageicons.com/) (Apache License 2.0)
