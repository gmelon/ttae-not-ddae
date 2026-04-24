# 떄가아니라때

> 세상에 '떄' 라는 말은 없다.

한글을 빠르게 치다 보면 Shift 를 모음까지 눌러버려서 "떄", "쨰", "꺠", "뺴" 같은
존재할 수 없는 음절이 자주 입력됩니다. 「떄가아니라때」는 이런 오타를 실시간으로 감지하여
올바른 음절로 자동 교정해 주는 가벼운 macOS 메뉴바 앱입니다.

### 상태

초기 구현 중입니다. 현재 마일스톤 M1 (핵심 로직 PoC) 완료.

- M1 완료: 한글 음절 분해/합성 유틸, Tier 1 교정 룰, CGEventTap 기반 키 이벤트 감시 PoC
- M2 진행 예정: MenuBarExtra + Settings 창 + on/off / 예외 단어 UI

### 예정된 주요 기능

- 떄 → 때, 쨰 → 째, 꺠 → 깨, 뺴 → 빼 등 쌍자음 + ㅒ/ㅖ 오타 자동 교정
- 메뉴바 상주형 앱, 설정 창 하나의 간결한 구성
- 교정 on/off 토글 및 예외 단어 관리
- 로그인 시 자동 실행

### 개발 / 실행

빌드와 테스트는 `app/` 디렉터리에서 Swift Package Manager 로 동작합니다.

```sh
cd app
swift build            # TtaeCore + ttae 실행 파일 빌드
swift test             # 단위 테스트 실행
swift run ttae         # 이벤트 탭 PoC 실행 (Accessibility 권한 필요)
```

최초 PoC 실행 시 해당 터미널/Xcode 에 "시스템 설정 > 개인 정보 보호 및 보안 > 손쉬운 사용" 권한이 필요합니다.

### 라이선스

MIT License. 자세한 내용은 [LICENSE](LICENSE) 참고.
