// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "allure-swift",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .library(name: "AllureSwiftXCTest", targets: ["AllureSwiftXCTest"]),
        .library(name: "AllureSwiftTesting", targets: ["AllureSwiftTesting"]),
    ],
    targets: [
        .target(
            name: "AllureSwiftXCTest",
            path: "Sources/AllureSwiftXCTest",
            swiftSettings: [
                // XCTContext.runActivity is @MainActor since Xcode 16.
                // XCTest always runs on the main thread — bypass strict-concurrency
                // so callers need no @MainActor annotation on their test classes.
                .swiftLanguageMode(.v5),
            ]
        ),
        .target(
            name: "AllureSwiftTesting",
            path: "Sources/AllureSwiftTesting"
        ),
    ],
    swiftLanguageModes: [.v6]
)
