import AppKit
import CoreGraphics
import Foundation
import TtaeCore

final class InputMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

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
        guard isEnabled(), type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        let typed = characters(from: event)
        let exceptions = exceptionWords()

        for character in typed {
            guard !exceptions.contains(String(character)) else { continue }
            if let corrected = CorrectionRules.correctedSyllable(for: character) {
                onCorrection(character, corrected)
            }
        }

        return Unmanaged.passUnretained(event)
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
