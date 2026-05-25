import XCTest
@testable import XCResultParser

final class XCResultBundleTests: XCTestCase {
    private var bundleURL: URL!

    override func setUpWithError() throws {
        guard let url = Bundle.module.url(forResource: "sample", withExtension: "xcresult", subdirectory: "Resources")
            ?? Bundle.module.url(forResource: "sample", withExtension: "xcresult") else {
            throw XCTSkip("sample.xcresult fixture not bundled")
        }
        self.bundleURL = url
    }

    func testSummaryDecodes() throws {
        let bundle = try XCResultBundle(url: bundleURL)
        let summary = try bundle.summary()
        XCTAssertEqual(summary.passedTests, 1)
        XCTAssertEqual(summary.failedTests, 0)
        XCTAssertNotNil(summary.startTime)
        XCTAssertNotNil(summary.devicesAndConfigurations?.first?.device.deviceName)
    }

    func testTestsTreeDecodes() throws {
        let bundle = try XCResultBundle(url: bundleURL)
        let tree = try bundle.tests()
        let cases = tree.allTestCases()
        XCTAssertEqual(cases.count, 1)
        XCTAssertEqual(cases.first?.name, "example()")
        XCTAssertEqual(cases.first?.result, "Passed")
    }

    func testTestDetailsForKnownTest() throws {
        let bundle = try XCResultBundle(url: bundleURL)
        let tree = try bundle.tests()
        let testURL = try XCTUnwrap(tree.allTestCases().first?.nodeIdentifierURL)
        let details = try bundle.details(forTestURL: testURL)
        XCTAssertEqual(details.testResult, "Passed")
        XCTAssertEqual(details.testName, "example()")
    }

    func testActivitiesAreEmptyForUnitTest() throws {
        let bundle = try XCResultBundle(url: bundleURL)
        let tree = try bundle.tests()
        let testURL = try XCTUnwrap(tree.allTestCases().first?.nodeIdentifierURL)
        let activities = try bundle.activities(forTestURL: testURL)
        // A passing unit test has no XCUI activities; the run array should
        // still come back populated with the device entry.
        XCTAssertEqual(activities.testRuns?.count ?? 0, 1)
    }

    func testAttachmentExportSucceeds() throws {
        let bundle = try XCResultBundle(url: bundleURL)
        let outDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("allure-swift-test-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: outDir) }

        let index = try bundle.exportAttachments(to: outDir)
        // Unit test has no attachments, but manifest.json should still exist.
        XCTAssertTrue(FileManager.default.fileExists(atPath: outDir.appendingPathComponent("manifest.json").path))
        XCTAssertNotNil(index)
    }
}
