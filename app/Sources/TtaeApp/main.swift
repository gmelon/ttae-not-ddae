import Foundation

print("떄가아니라때 PoC")
print("Tier 1 교정 룰을 키보드 이벤트에 적용하는 개념 검증.")
print("Accessibility 권한이 필요합니다: 시스템 설정 > 개인 정보 보호 및 보안 > 손쉬운 사용")
print()

let monitor = InputMonitor()

guard monitor.start() else {
    print("[!] Event tap 생성 실패. 이 터미널/바이너리에 Accessibility 권한이 있는지 확인하세요.")
    exit(1)
}

print("[+] 모니터링 시작. Ctrl-C 로 종료.")
CFRunLoopRun()
