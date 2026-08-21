// swift-tools-version: 6.0
import PackageDescription

#if TUIST
import struct ProjectDescription.PackageSettings

let packageSettings = PackageSettings(
    // Default product type is .staticFramework — keep everything static and
    // link Firebase/Kakao/etc. only at app targets to avoid duplicate symbols.
    productTypes: [:],
    baseSettings: .settings(
        // External targets must know all three configurations, otherwise Xcode
        // falls back to a default config when building Stage (tuist#4597).
        configurations: [
            .debug(name: "Debug"),
            .release(name: "Stage"),
            .release(name: "Release"),
        ]
    )
)
#endif

let package = Package(
    name: "AtchaDependencies",
    dependencies: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.7.1"),
        .package(url: "https://github.com/kakao/kakao-ios-sdk", from: "2.24.4"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "11.14.0"),
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.5.2"),
        .package(url: "https://github.com/amplitude/Amplitude-Swift", branch: "main"),
    ]
)
