import AppKit
import CoreGraphics
import Foundation
import TtaeCore

final class InputMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let eventSource = CGEventSource(stateID: .hidSystemState)

    /// 우리가 합성한 이벤트를 식별하기 위한 magic value.
    /// 이 값이 박혀 있는 이벤트는 다시 가공하지 않고 그대로 통과시킨다.
    private static let synthMarker: Int64 = 0x4D_DAE_4D
    private static let backspaceKeyCode: CGKeyCode = 51 // kVK_Delete

    var isEnabled: () -> Bool = { true }
    var exceptionWords: () -> Set<String> = { [] }
    var onCorrection: (Character, Character) -> Void = { _, _ in }

    @discardableResult
    func start() -> Bool {
        guard eventTap == nil else { return true }
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
            return false
        }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent> {
        if event.getIntegerValueField(.eventSourceUserData) == Self.synthMarker {
            return Unmanaged.passUnretained(event)
        }

        guard isEnabled(), type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        let typed = characters(from: event)
        let exceptions = exceptionWords()

        for character in typed {
            guard !exceptions.contains(String(character)) else { continue }
            if let corrected = CorrectionRules.correctedSyllable(for: character) {
                onCorrection(character, corrected)
                postCorrection(replacement: corrected)
            }
        }

        return Unmanaged.passUnretained(event)
    }

    /// 잘못 입력된 음절(예: 떄)이 화면에 들어간 직후, backspace 1회로 지우고
    /// 올바른 음절(예: 때) 을 Unicode keystroke 로 다시 입력한다.
    private func postCorrection(replacement: Character) {
        guard let source = eventSource else { return }
        let tapLocation: CGEventTapLocation = .cgAnnotatedSessionEventTap

        for keyDown in [true, false] {
            guard let event = CGEvent(
                keyboardEventSource: source,
                virtualKey: Self.backspaceKeyCode,
                keyDown: keyDown
            ) else { continue }
            event.setIntegerValueField(.eventSourceUserData, value: Self.synthMarker)
            event.post(tap: tapLocation)
        }

        let utf16 = Array(String(replacement).utf16)
        utf16.withUnsafeBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            for keyDown in [true, false] {
                guard let event = CGEvent(
                    keyboardEventSource: source,
                    virtualKey: 0,
                    keyDown: keyDown
                ) else { continue }
                event.keyboardSetUnicodeString(
                    stringLength: buffer.count,
                    unicodeString: baseAddress
                )
                event.setIntegerValueField(.eventSourceUserData, value: Self.synthMarker)
                event.post(tap: tapLocation)
            }
        }
    }

    private func characters(from event: CGEvent) -> [Character] {
        var length = 0
        var buffer = [UniChar](repeating: 0, count: 8)
        buffer.withUnsafeMutableBufferPointer { pointer in
            event.keyboardGetUnicodeString(
                maxStringLength: pointer.count,
                actualStringLength: &length,
                unicodeString: pointer.baseAddress
            )
        }
        guard length > 0 else { return [] }
        let slice = Array(buffer.prefix(length))
        return Array(String(utf16CodeUnits: slice, count: length))
    }
}
