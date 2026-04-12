import AppKit
import ServiceManagement
import SwiftUI

@main
struct KlickApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Klick", systemImage: "keyboard") {
            Toggle("Enabled", isOn: Binding(
                get: { appDelegate.isEnabled },
                set: { appDelegate.setEnabled($0) }
            ))
            Toggle("Mouse Sounds", isOn: Binding(
                get: { appDelegate.mouseEnabled },
                set: { appDelegate.setMouseEnabled($0) }
            ))
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private let audioEngine = AudioEngine()
    private var keyMonitor: KeyMonitor?
    private var accessibilityTimer: Timer?
    private let systemAudioMonitor = SystemAudioMonitor()

    var isEnabled = true
    var mouseEnabled = true

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        try? SMAppService.mainApp.register()

        audioEngine.smartVolume = true

        do {
            try audioEngine.start()
        } catch {
            return
        }

        startAudioMonitor()

        requestAccessibilityIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        accessibilityTimer?.invalidate()
        systemAudioMonitor.stop()
        keyMonitor?.stop()
        audioEngine.stop()
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if enabled {
            if keyMonitor == nil {
                keyMonitor = KeyMonitor(audioEngine: audioEngine)
            }
            _ = keyMonitor?.start()
        } else {
            keyMonitor?.stop()
        }
    }

    func setMouseEnabled(_ enabled: Bool) {
        mouseEnabled = enabled
        keyMonitor?.mouseEnabled = enabled
    }

    private func startAudioMonitor() {
        systemAudioMonitor.onAudioStateChanged = { [weak self] isPlaying in
            self?.audioEngine.otherAudioPlaying = isPlaying
        }
        systemAudioMonitor.start()
    }

    private func requestAccessibilityIfNeeded() {
        if KeyMonitor.checkAccessibility() {
            startKeyMonitor()
            return
        }

        showAccessibilityAlert()
        pollForAccessibility()
    }

    private func showAccessibilityAlert() {
        // Briefly become a regular app so the alert can appear in front
        NSApp.setActivationPolicy(.regular)

        let alert = NSAlert()
        alert.messageText = "Klick Needs Accessibility Access"
        alert.informativeText = "Klick needs Accessibility permission to listen for keystrokes.\n\nClick \"Open Settings\" then add Klick to the Accessibility list and enable it."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()

        // Go back to accessory (menu bar only)
        NSApp.setActivationPolicy(.accessory)

        if response == .alertFirstButtonReturn {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }
    }

    private func pollForAccessibility() {
        accessibilityTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            if KeyMonitor.checkAccessibility() {
                timer.invalidate()
                self?.accessibilityTimer = nil
                self?.startKeyMonitor()
            }
        }
    }

    private func startKeyMonitor() {
        guard isEnabled else { return }
        keyMonitor = KeyMonitor(audioEngine: audioEngine)
        _ = keyMonitor?.start()
    }
}
