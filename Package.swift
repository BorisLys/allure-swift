// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "allure-swift",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(name: "AllureSwiftCore", targets: ["AllureSwiftCore"]),
        .library(name: "AllureSwiftXCTest", targets: ["AllureSwiftXCTest"]),
        .library(name: "AllureSwiftTesting", targets: ["AllureSwiftTesting"]),
        .library(name: "AllureXCResult", targets: ["AllureXCResult"]),
        .executable(name: "allure-xcresult", targets: ["allure-xcresult"]),
        .plugin(name: "AllureXCResultPlugin", targets: ["AllureXCResultPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "AllureSwiftCore",
            path: "Sources/AllureSwiftCore"
        ),
        .target(
            name: "AllureSwiftXCTest",
            dependencies: ["AllureSwiftCore"],
            path: "Sources/AllureSwiftXCTest",
            swiftSettings: [
                // XCTContext.runActivity is @MainActor since Xcode 16.
                // We trust XCTest always runs on the main thread and bypass
                // strict-concurrency checking so callers need no @MainActor annotation.
                .swiftLanguageMode(.v5),
            ]
        ),
        .target(
            name: "AllureSwiftTesting",
            dependencies: ["AllureSwiftCore"],
            path: "Sources/AllureSwiftTesting"
        ),
        .target(
            name: "XCResultParser",
            dependencies: ["AllureSwiftCore"],
            path: "Sources/XCResultParser"
        ),
        .target(
            name: "AllureXCResult",
            dependencies: ["AllureSwiftCore", "XCResultParser"],
            path: "Sources/AllureXCResult"
        ),
        .executableTarget(
            name: "allure-xcresult",
            dependencies: [
                "AllureXCResult",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/allure-xcresult"
        ),
        .plugin(
            name: "AllureXCResultPlugin",
            capability: .command(
                intent: .custom(
                    verb: "allure-xcresult",
                    description: "Convert .xcresult bundle to Allure JSON results"
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "Writes allure-results/ inside the package directory"),
                ]
            ),
            dependencies: [.target(name: "allure-xcresult")],
            path: "Plugins/AllureXCResultPlugin"
        ),
        .testTarget(
            name: "AllureSwiftCoreTests",
            dependencies: ["AllureSwiftCore"],
            path: "Tests/AllureSwiftCoreTests"
        ),
        .testTarget(
            name: "XCResultParserTests",
            dependencies: ["XCResultParser"],
            path: "Tests/XCResultParserTests",
            resources: [.copy("Resources")]
        ),
        .testTarget(
            name: "AllureXCResultTests",
            dependencies: ["AllureXCResult"],
            path: "Tests/AllureXCResultTests",
            resources: [.copy("Resources")]
        ),
    ],
    swiftLanguageModes: [.v6]
)
