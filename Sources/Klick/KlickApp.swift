import AppKit
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
    var isEnabled = true

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        do {
            try audioEngine.start()
        } catch {
            return
        }

        _ = KeyMonitor.checkAccessibility()

        keyMonitor = KeyMonitor(audioEngine: audioEngine)
        _ = keyMonitor!.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
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
}
