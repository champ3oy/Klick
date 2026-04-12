import CoreAudio
import Foundation

/// Monitors whether other apps are actively producing audio using Core Audio's process object list.
class SystemAudioMonitor {
    private var timer: Timer?
    private let myPID = ProcessInfo.processInfo.processIdentifier
    var onAudioStateChanged: ((Bool) -> Void)?
    private(set) var isOtherAudioPlaying = false

    func start() {
        // Poll every 2 seconds — lightweight Core Audio property reads
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.poll()
        }
        // Initial check
        poll()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        let playing = checkOtherAudioProcesses()
        if playing != isOtherAudioPlaying {
            isOtherAudioPlaying = playing
            onAudioStateChanged?(playing)
        }
    }

    /// Uses kAudioHardwarePropertyProcessObjectList to enumerate audio processes,
    /// then checks each one's running state, skipping our own PID.
    private func checkOtherAudioProcesses() -> Bool {
        let systemObject = AudioObjectID(kAudioObjectSystemObject)

        // Get process object list
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyProcessObjectList,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var size: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(systemObject, &address, 0, nil, &size)
        guard status == noErr, size > 0 else { return false }

        let count = Int(size) / MemoryLayout<AudioObjectID>.size
        var processObjects = [AudioObjectID](repeating: 0, count: count)
        status = AudioObjectGetPropertyData(systemObject, &address, 0, nil, &size, &processObjects)
        guard status == noErr else { return false }

        for processObject in processObjects {
            // Get this process's PID
            var pid: pid_t = 0
            var pidSize = UInt32(MemoryLayout<pid_t>.size)
            var pidAddress = AudioObjectPropertyAddress(
                mSelector: kAudioProcessPropertyPID,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            let pidStatus = AudioObjectGetPropertyData(processObject, &pidAddress, 0, nil, &pidSize, &pid)
            guard pidStatus == noErr else { continue }

            // Skip our own process
            if pid == myPID { continue }

            // Check if this process is actively running audio
            var isRunning: UInt32 = 0
            var runSize = UInt32(MemoryLayout<UInt32>.size)
            var runAddress = AudioObjectPropertyAddress(
                mSelector: kAudioProcessPropertyIsRunning,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            let runStatus = AudioObjectGetPropertyData(processObject, &runAddress, 0, nil, &runSize, &isRunning)
            guard runStatus == noErr else { continue }

            if isRunning != 0 {
                return true
            }
        }

        return false
    }
}
