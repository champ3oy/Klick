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

    /// Whether to auto-duck when other audio is playing
    var smartVolume = false

    /// Whether other audio is currently playing (set by SystemAudioMonitor)
    var otherAudioPlaying = false {
        didSet { applyVolume() }
    }

    private let normalVolume: Float = 0.5
    private let duckedVolume: Float = 0.25

    private func applyVolume() {
        engine.mainMixerNode.outputVolume = (smartVolume && otherAudioPlaying)
            ? duckedVolume
            : normalVolume
    }

    private static func findSoundURL() -> URL? {
        return Bundle.klickResources.url(forResource: "sound", withExtension: "caf")
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
        applyVolume()

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
        playSound(forName: keyName, phase: phase)
    }

    func playSound(forName name: String, phase: KeyPhase) {
        guard let file = audioFile else { return }

        let table = phase == .down ? SoundDefines.down : SoundDefines.up
        guard let (startMs, durationMs) = table[name] else { return }

        let startFrame = AVAudioFramePosition(Double(startMs) * sampleRate / 1000.0)
        let frameCount = AVAudioFrameCount(Double(durationMs) * sampleRate / 1000.0)

        let node = playerNodes[nodeIndex % poolSize]
        nodeIndex += 1

        node.stop()
        node.scheduleSegment(file, startingFrame: startFrame, frameCount: frameCount, at: nil)
        node.play()
    }
}
