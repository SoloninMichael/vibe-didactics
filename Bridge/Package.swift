// swift-tools-version: 6.2
import PackageDescription

// The Mac side of Vibie: a small command-line bridge that Claude Code's hooks
// talk to over 127.0.0.1, and that your iPhone talks to over an end-to-end
// encrypted connection on your local network.
let package = Package(
    name: "VibieBridge",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(path: "../VibieKit")
    ],
    targets: [
        .executableTarget(
            name: "vibie",
            dependencies: [.product(name: "VibieKit", package: "VibieKit")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
