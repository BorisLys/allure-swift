// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "allure-swift",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
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
                // XCTest was not designed for Swift 6 strict concurrency.
                // XCTContext.runActivity is @MainActor — calling it from a nonisolated
                // generic method triggers non-Sendable T and data-race errors in Swift 6.
                // Compiling this target in Swift 5 mode downgrades them to warnings.
                // Callers in Swift 6 test targets are unaffected: the extension methods
                // are nonisolated, so no actor isolation propagates to call sites.
                .swiftLanguageMode(.v5),
            ]
        ),
        .target(
            name: "AllureSwiftTesting",
            path: "Sources/AllureSwiftTesting"
        ),
    ]
)
