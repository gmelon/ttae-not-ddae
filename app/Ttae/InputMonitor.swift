import AppKit
import CoreGraphics
import Foundation
import TtaeCore

final class InputMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let eventSource = CGEventSource(stateID: .hidSystemState)

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
            log("tapCreate failed (Accessibility permission missing or revoked)")
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
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent> {
        if event.getIntegerValueField(.eventSourceUserData) == Self.synthMarker {
            return Unmanaged.passUnretained(event)
        }

        guard isEnabled(), type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        let typed = characters(from: event)
        let keycode = event.getIntegerValueField(.keyboardEventKeycode)
        let codepointStr = typed
            .map { String(format: "U+%04X", $0.unicodeScalars.first?.value ?? 0) }
            .joined(separator: ",")
        log("keyDown keycode=\(keycode) chars='\(typed.map(String.init).joined())' cp=\(codepointStr)")

        let exceptions = exceptionWords()

        for character in typed {
            guard !exceptions.contains(String(character)) else {
                log("  skipped (exception): \(character)")
                continue
            }
            if let corrected = CorrectionRules.correctedSyllable(for: character) {
                log("  matched: \(character) -> \(corrected)")
                onCorrection(character, corrected)
                postCorrection(replacement: corrected)
            }
        }

        return Unmanaged.passUnretained(event)
    }

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

    private func log(_ message: String) {
        NSLog("%@", "[Ttae][InputMonitor] \(message)" as NSString)
    }
}
