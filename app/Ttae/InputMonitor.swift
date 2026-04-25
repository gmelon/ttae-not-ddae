import AppKit
import Carbon.HIToolbox
import CoreGraphics
import Foundation
import os
import TtaeCore

/// macOS 한글 IME 가 합성한 음절(예: 떄)은 CGEventTap 까지 올라오지 않으므로
/// 두벌식 자판 keycode 시퀀스로 패턴을 잡아 처리한다.
///
/// 직전 keyDown 이 (shift + 쌍자음 키), 현재 keyDown 이 (shift + ㅒ/ㅖ 키) 일 때
/// 현재 원본 이벤트를 suppress 하고, 같은 keycode 를 shift 없이 재주입한다.
/// IME 는 ㅐ/ㅔ 를 받아 (쌍자음 + ㅐ/ㅔ) 음절로 합성한다.
final class InputMonitor {
    private static let logger = Logger(subsystem: "dev.gmelon.ttae", category: "InputMonitor")

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let eventSource = CGEventSource(stateID: .hidSystemState)

    private static let synthMarker: Int64 = 0x4D_DAE_4D

    /// 두벌식 자판에서 (shift + 키) 가 쌍자음을 만드는 keycode → Hangul.Initial rawValue
    private static let doubleConsonantKeycodes: [Int64: Int] = [
        12: Hangul.Initial.ssangBieup.rawValue,   // Q -> ㅃ
        13: Hangul.Initial.ssangJieut.rawValue,   // W -> ㅉ
        14: Hangul.Initial.ssangDigeut.rawValue,  // E -> ㄸ
        15: Hangul.Initial.ssangGiyeok.rawValue,  // R -> ㄲ
        17: Hangul.Initial.ssangSiot.rawValue,    // T -> ㅆ
    ]

    /// 두벌식 자판에서 (shift + 키) 가 ㅒ / ㅖ 를 만드는 keycode → (잘못된 medial, 올바른 medial)
    private static let shiftedVowelKeycodes: [Int64: (wrong: Int, fixed: Int)] = [
        31: (Hangul.Medial.yae.rawValue, Hangul.Medial.ae.rawValue),  // O: ㅒ→ㅐ
        35: (Hangul.Medial.ye.rawValue,  Hangul.Medial.e.rawValue),   // P: ㅖ→ㅔ
    ]

    var isEnabled: () -> Bool = { true }
    var exceptionWords: () -> Set<String> = { [] }
    var onCorrection: (Character, Character) -> Void = { _, _ in }

    private var lastKeyDownKeycode: Int64 = -1
    private var lastKeyDownHadShift: Bool = false

    @discardableResult
    func start() -> Bool {
        guard eventTap == nil else { return true }
        log("start() called")
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let pointer = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, userInfo in
                guard let userInfo else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<InputMonitor>.fromOpaque(userInfo).takeUnretainedValue()
                return monitor.handle(type: type, event: event)
            },
            userInfo: pointer
        ) else {
            log("tapCreate FAILED (Accessibility permission missing or revoked)")
            return false
        }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        log("event tap created and enabled")
        return true
    }

    func stop() {
        if eventTap != nil {
            log("event tap stopped")
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        lastKeyDownKeycode = -1
        lastKeyDownHadShift = false
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if event.getIntegerValueField(.eventSourceUserData) == Self.synthMarker {
            return Unmanaged.passUnretained(event)
        }

        guard isEnabled(), type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        let keycode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        let hasShift = flags.contains(.maskShift)

        // 한글 IME 가 활성화된 상태가 아니면 패턴 매칭 자체를 스킵한다 (영문 EO 는 그대로 둠).
        let koreanActive = isKoreanInputSourceActive()

        // 패턴: 직전 = shift + 쌍자음, 현재 = shift + ㅒ/ㅖ
        if koreanActive,
           hasShift,
           lastKeyDownHadShift,
           let medial = Self.shiftedVowelKeycodes[keycode],
           let initial = Self.doubleConsonantKeycodes[lastKeyDownKeycode] {

            let wrongChar = Hangul.compose(initial: initial, medial: medial.wrong, final: 0)
            let correctChar = Hangul.compose(initial: initial, medial: medial.fixed, final: 0)
            let exceptions = exceptionWords()

            if let wrong = wrongChar, exceptions.contains(String(wrong)) {
                log("matched but exception, passing through: \(wrong)")
                lastKeyDownKeycode = keycode
                lastKeyDownHadShift = hasShift
                return Unmanaged.passUnretained(event)
            }

            log("matched: kc(\(lastKeyDownKeycode)+shift)+kc(\(keycode)+shift) -> \(String(describing: wrongChar))→\(String(describing: correctChar)) [stripping shift in place]")

            if let wrong = wrongChar, let correct = correctChar {
                onCorrection(wrong, correct)
            }

            // 원본 이벤트의 shift 만 그 자리에서 벗겨서 그대로 흘려보낸다.
            // 새 이벤트를 post 하면 Spotlight 같은 시스템 프로세스가 합성 이벤트를 거부하기 때문에
            // 사용자의 진짜 이벤트를 가로채 flag 만 수정하는 방식이 가장 호환성이 좋다.
            event.flags = flags.subtracting(.maskShift)
            event.setIntegerValueField(.eventSourceUserData, value: Self.synthMarker)

            lastKeyDownKeycode = keycode
            lastKeyDownHadShift = false

            return Unmanaged.passUnretained(event)
        }

        lastKeyDownKeycode = keycode
        lastKeyDownHadShift = hasShift

        return Unmanaged.passUnretained(event)
    }

    private func isKoreanInputSourceActive() -> Bool {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return false
        }
        guard let raw = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else {
            return false
        }
        let id = Unmanaged<CFString>.fromOpaque(raw).takeUnretainedValue() as String
        return id.contains("Korean") || id.lowercased().contains("hangul")
    }

    private func log(_ message: String) {
        Self.logger.info("\(message, privacy: .public)")
        print("[Ttae][InputMonitor] \(message)")
    }
}
