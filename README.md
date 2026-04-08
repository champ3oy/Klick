# Klick

A macOS menu bar app that plays mechanical keyboard sounds on every keypress.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- Realistic mechanical keyboard sounds with unique down/up sounds per key
- Runs silently in the menu bar
- Toggle on/off from the menu bar
- Low-latency audio playback (~5ms) using AVAudioEngine
- Lightweight — single audio sprite file, no external dependencies

## Install

### Download

Download the latest `Klick.dmg` from [Releases](../../releases), open it, and drag Klick to Applications.

### Build from source

```bash
git clone https://github.com/cirx/klick.git
cd klick
swift build
.build/debug/Klick
```

## Permissions

Klick requires **Accessibility** permission to listen for global keypresses.

On first launch, go to **System Settings > Privacy & Security > Accessibility** and enable Klick.

## Building for distribution

Requires an Apple Developer account with a Developer ID Application certificate.

```bash
# Store notarization credentials (one-time)
xcrun notarytool store-credentials klick-notary

# Build, sign, notarize, and create DMG
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./scripts/bundle.sh
```

## How it works

Klick uses a single audio sprite file containing individual mechanical key sounds. Each keypress triggers a slice of the audio at the correct offset using `AVAudioEngine` with a pool of 12 `AVAudioPlayerNode` instances for overlapping playback. Global key events are captured via a `CGEvent` tap.

Sound definitions are ported from [klickboard](https://github.com/nicknisi/klickboard).

## License

MIT
