// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "allure-swift",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .library(name: "AllureSwift", targets: ["AllureSwift"]),
        .library(name: "AllureSwiftCore", targets: ["AllureSwiftCore"]),
        .library(name: "AllureSwiftXCTest", targets: ["AllureSwiftXCTest"]),
        .library(name: "AllureSwiftTesting", targets: ["AllureSwiftTesting"]),
    ],
    targets: [
        .target(
            name: "AllureSwiftCore",
            path: "Sources/AllureSwiftCore"
        ),
        .target(
            name: "AllureSwiftXCTest",
            dependencies: ["AllureSwiftCore"],
            path: "Sources/AllureSwiftXCTest"
        ),
        .target(
            name: "AllureSwiftTesting",
            dependencies: ["AllureSwiftCore"],
            path: "Sources/AllureSwiftTesting"
        ),
        .target(
            name: "AllureSwift",
            dependencies: ["AllureSwiftCore", "AllureSwiftXCTest", "AllureSwiftTesting"],
            path: "Sources/AllureSwift"
        ),
        .testTarget(
            name: "AllureSwiftCoreTests",
            dependencies: ["AllureSwiftCore"],
            path: "Tests/AllureSwiftCoreTests"
        ),
        .testTarget(
            name: "AllureSwiftTestingTests",
            dependencies: ["AllureSwiftCore", "AllureSwiftTesting"],
            path: "Tests/AllureSwiftTestingTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
