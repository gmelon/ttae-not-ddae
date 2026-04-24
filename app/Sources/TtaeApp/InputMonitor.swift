import CoreGraphics
import Foundation
import TtaeCore

public final class InputMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    public init() {}

    @discardableResult
    public func start() -> Bool {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

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
            userInfo: selfPointer
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

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent> {
        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        let typed = characters(from: event)
        for character in typed {
            if let corrected = CorrectionRules.correctedSyllable(for: character) {
                FileHandle.standardOutput.write(Data("[!] 감지: \(character) → \(corrected)\n".utf8))
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
