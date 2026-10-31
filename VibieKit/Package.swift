// swift-tools-version: 6.2
import PackageDescription

// Shared by the iPhone app and the Mac bridge: wire format, end-to-end
// encryption, diffing and secret redaction. No third-party dependencies.
let package = Package(
    name: "VibieKit",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "VibieKit", targets: ["VibieKit"])
    ],
    targets: [
        .target(
            name: "VibieKit",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "VibieKitTests",
            dependencies: ["VibieKit"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
