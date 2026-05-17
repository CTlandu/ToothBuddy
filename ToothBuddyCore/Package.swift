// swift-tools-version: 6.0
import PackageDescription

// Platform-agnostic pure logic for ToothBuddy (models + habit/streak/reminder engines).
// No SwiftUI/UIKit/AppleProductTypes — so `swift test` runs from the macOS CLI and CI.
// The .swiftpm app depends on this package via a local path.
let package = Package(
    name: "ToothBuddyCore",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "ToothBuddyCore", targets: ["ToothBuddyCore"])
    ],
    targets: [
        .target(name: "ToothBuddyCore"),
        .testTarget(
            name: "ToothBuddyCoreTests",
            dependencies: ["ToothBuddyCore"]
        )
    ],
    swiftLanguageModes: [.v6]
)
