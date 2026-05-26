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
            path: "Sources/AllureSwiftXCTest"
        ),
        .target(
            name: "AllureSwiftTesting",
            path: "Sources/AllureSwiftTesting"
        ),
    ],
    swiftLanguageModes: [.v6]
)
