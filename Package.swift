// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Klick",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Klick",
            resources: [.copy("Resources/sound.caf")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
