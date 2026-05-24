import XCTest
import AllureSwiftCore
@testable import AllureSwiftXCTest

final class FailureDiagnosticsTests: XCTestCase {
    private var tmpDir: URL!

    override func setUpWithError() throws {
        tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent("allure-xctest-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        Allure.configure(directory: tmpDir)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
        tmpDir = nil
    }

    func testFormatsFailureIssuesAsAssertionAttachmentText() {
        let location = XCTSourceCodeLocation(filePath: "/tmp/LoginTests.swift", lineNumber: 42)
        let context = XCTSourceCodeContext(location: location)
        let issue = XCTIssue(
            type: .assertionFailure,
            compactDescription: "XCTAssertTrue failed",
            detailedDescription: "Expected login button to be visible",
            sourceCodeContext: context,
            associatedError: nil,
            attachments: []
        )

        let text = AllureFailureDiagnostics.assertionsText(from: [issue])

        XCTAssertTrue(text.contains("Failure #1"))
        XCTAssertTrue(text.contains("Type: assertionFailure"))
        XCTAssertTrue(text.contains("Message: XCTAssertTrue failed"))
        XCTAssertTrue(text.contains("Details: Expected login button to be visible"))
        XCTAssertTrue(text.contains("Location: /tmp/LoginTests.swift:42"))
    }

    func testAttachesAssertionsUIHierarchyAndScreenshotToFailedTest() throws {
        let uuid = UUID().uuidString.lowercased()
        let issue = XCTIssue(type: .assertionFailure, compactDescription: "Missing title")
        Allure.startTest(TestResult(uuid: uuid, name: "failedUITest"))

        AllureFailureDiagnostics.attachFailureDiagnostics(
            testUUID: uuid,
            issues: [issue],
            uiHierarchy: { "Application hierarchy" },
            screenshotPNG: { Data([0x89, 0x50, 0x4e, 0x47]) }
        )
        Allure.stopTest(uuid: uuid, status: .failed)
        AllureLifecycle.shared.flush()

        let resultFile = tmpDir.appendingPathComponent("\(uuid)-result.json")
        let result = try JSONDecoder().decode(TestResult.self, from: try Data(contentsOf: resultFile))
        XCTAssertEqual(result.attachments.map(\.name), [
            "failure-assertions",
            "ui-hierarchy",
            "screenshot",
        ])
        XCTAssertEqual(result.attachments.map(\.type), [
            AttachmentType.textPlain.rawValue,
            AttachmentType.textPlain.rawValue,
            AttachmentType.imagePng.rawValue,
        ])
        for attachment in result.attachments {
            XCTAssertTrue(FileManager.default.fileExists(atPath: tmpDir.appendingPathComponent(attachment.source).path))
        }
    }
}
