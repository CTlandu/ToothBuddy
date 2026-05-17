// swift-tools-version: 6.0

// NOTE: This was originally a Swift Playgrounds auto-generated manifest.
// As of 2026-05-18 the project is Xcode 26 / CLI-driven and this file is
// HAND-MAINTAINED (see PLAN.md). Swift Playgrounds.app is no longer supported.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "ToothBuddy",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .iOSApplication(
            name: "ToothBuddy",
            targets: ["AppModule"],
            bundleIdentifier: "com.ctlandu.ToothBuddy",
            teamIdentifier: "89A8S223WV",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .box),
            accentColor: .presetColor(.green),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ],
            capabilities: [
                .camera(purposeString: "Unknown Usage Description")
            ],
            appCategory: .medical
        )
    ],
    dependencies: [
        .package(path: "ToothBuddyCore")
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            dependencies: [
                .product(name: "ToothBuddyCore", package: "ToothBuddyCore")
            ],
            path: ".",
            exclude: [
                "ToothBuddyCore",
                "ROADMAP.md",
                "PLAN.md",
                "specs",
                "README.md",
                "onboarding_preview.jsx",
                "ToothBuddy_preview.jsx",
                "toothbuddy-web.html"
            ],
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)