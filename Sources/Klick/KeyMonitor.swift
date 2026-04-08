import ApplicationServices
import CoreGraphics
import Foundation

class KeyMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var pressedModifiers = Set<UInt16>()
    private let audioEngine: AudioEngine
    var mouseEnabled = true

    init(audioEngine: AudioEngine) {
        self.audioEngine = audioEngine
    }

    static func checkAccessibility() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func start() -> Bool {
        var eventMask: CGEventMask = 0
        for type: CGEventType in [
            .keyDown, .keyUp, .flagsChanged,
            .leftMouseDown, .leftMouseUp,
            .rightMouseDown, .rightMouseUp,
            .otherMouseDown, .otherMouseUp,
        ] {
            eventMask |= (1 << type.rawValue)
        }

        let userInfo = Unmanaged.passUnretained(self).toOpaque()

        guard
            let tap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .listenOnly,
                eventsOfInterest: eventMask,
                callback: keyMonitorCallback,
                userInfo: userInfo
            )
        else {
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        pressedModifiers.removeAll()
    }

    fileprivate func handleEvent(type: CGEventType, event: CGEvent) {
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))

        switch type {
        case .keyDown:
            audioEngine.playSound(forKeyCode: keyCode, phase: .down)

        case .keyUp:
            audioEngine.playSound(forKeyCode: keyCode, phase: .up)

        case .flagsChanged:
            if KeyCodeMap.modifierKeyCodes.contains(keyCode) {
                if pressedModifiers.contains(keyCode) {
                    pressedModifiers.remove(keyCode)
                    audioEngine.playSound(forKeyCode: keyCode, phase: .up)
                } else {
                    pressedModifiers.insert(keyCode)
                    audioEngine.playSound(forKeyCode: keyCode, phase: .down)
                }
            }

        case .leftMouseDown:
            if mouseEnabled { audioEngine.playSound(forName: "MouseLeft", phase: .down) }
        case .leftMouseUp:
            if mouseEnabled { audioEngine.playSound(forName: "MouseLeft", phase: .up) }
        case .rightMouseDown:
            if mouseEnabled { audioEngine.playSound(forName: "MouseRight", phase: .down) }
        case .rightMouseUp:
            if mouseEnabled { audioEngine.playSound(forName: "MouseRight", phase: .up) }
        case .otherMouseDown:
            if mouseEnabled { audioEngine.playSound(forName: "MouseMiddle", phase: .down) }
        case .otherMouseUp:
            if mouseEnabled { audioEngine.playSound(forName: "MouseMiddle", phase: .up) }

        case .tapDisabledByTimeout:
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }

        default:
            break
        }
    }
}

private func keyMonitorCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo = userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let monitor = Unmanaged<KeyMonitor>.fromOpaque(userInfo).takeUnretainedValue()
    monitor.handleEvent(type: type, event: event)

    return Unmanaged.passUnretained(event)
}
