import AVFoundation
import Foundation

enum KeyPhase {
    case down
    case up
}

class AudioEngine {
    private let engine = AVAudioEngine()
    private var playerNodes: [AVAudioPlayerNode] = []
    private var audioFile: AVAudioFile?
    private var sampleRate: Double = 44100
    private var nodeIndex = 0
    private let poolSize = 12

    private static func findSoundURL() -> URL? {
        // 1. SPM resource bundle (swift build / development)
        if let url = Bundle.module.url(forResource: "sound", withExtension: "caf") {
            return url
        }
        // 2. Main bundle Resources/ (packaged .app)
        if let url = Bundle.main.url(forResource: "sound", withExtension: "caf") {
            return url
        }
        // 3. Look next to the executable
        let execURL = Bundle.main.executableURL?.deletingLastPathComponent()
        if let url = execURL?.appendingPathComponent("sound.caf"), FileManager.default.fileExists(atPath: url.path) {
            return url
        }
        // 4. Look in ../Resources relative to executable
        if let url = execURL?.deletingLastPathComponent().appendingPathComponent("Resources/sound.caf"),
           FileManager.default.fileExists(atPath: url.path) {
            return url
        }
        return nil
    }

    func start() throws {
        guard let url = Self.findSoundURL() else {
            fatalError("sound.caf not found in bundle")
        }
        audioFile = try AVAudioFile(forReading: url)
        sampleRate = audioFile!.processingFormat.sampleRate

        for _ in 0..<poolSize {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: audioFile!.processingFormat)
            playerNodes.append(node)
        }

        try engine.start()

        for node in playerNodes {
            node.play()
        }
    }

    func stop() {
        for node in playerNodes {
            node.stop()
        }
        engine.stop()
    }

    func playSound(forKeyCode keyCode: UInt16, phase: KeyPhase) {
        guard let keyName = KeyCodeMap.name(for: keyCode) else { return }
        guard let file = audioFile else { return }

        let table = phase == .down ? SoundDefines.down : SoundDefines.up
        guard let (startMs, durationMs) = table[keyName] else { return }

        let startFrame = AVAudioFramePosition(Double(startMs) * sampleRate / 1000.0)
        let frameCount = AVAudioFrameCount(Double(durationMs) * sampleRate / 1000.0)

        let node = playerNodes[nodeIndex % poolSize]
        nodeIndex += 1

        node.stop()
        node.scheduleSegment(file, startingFrame: startFrame, frameCount: frameCount, at: nil)
        node.play()
    }
}
