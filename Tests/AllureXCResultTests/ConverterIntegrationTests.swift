import XCTest
import AllureSwiftCore
@testable import AllureXCResult

final class ConverterIntegrationTests: XCTestCase {
    private var bundleURL: URL!

    override func setUpWithError() throws {
        guard let url = Bundle.module.url(forResource: "sample", withExtension: "xcresult", subdirectory: "Resources")
            ?? Bundle.module.url(forResource: "sample", withExtension: "xcresult") else {
            throw XCTSkip("sample.xcresult fixture not bundled")
        }
        self.bundleURL = url
    }

    func testEndToEndConversion() throws {
        let outDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("allure-swift-it-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: outDir) }

        let converter = try Converter(
            bundleURL: bundleURL,
            outputDir: outDir,
            options: ConverterOptions(includeAttachments: true, cleanOutputDirectory: true)
        )
        let result = try converter.run()

        XCTAssertEqual(result.testsConverted, 1)

        let jsonFiles = try FileManager.default.contentsOfDirectory(atPath: outDir.path)
            .filter { $0.hasSuffix("-result.json") }
        XCTAssertEqual(jsonFiles.count, 1)

        let data = try Data(contentsOf: outDir.appendingPathComponent(jsonFiles[0]))
        let decoded = try JSONDecoder().decode(TestResult.self, from: data)
        XCTAssertEqual(decoded.name, "example()")
        XCTAssertEqual(decoded.status, .passed)
        XCTAssertEqual(decoded.stage, .finished)
        XCTAssertNotNil(decoded.historyId)
        XCTAssertNotNil(decoded.start)
        XCTAssertNotNil(decoded.stop)
        XCTAssertTrue(decoded.labels.contains(where: { $0.name == "framework" && $0.value == "XCTest" }))
        XCTAssertTrue(decoded.labels.contains(where: { $0.name == "testClass" }))
        XCTAssertTrue(decoded.labels.contains(where: { $0.name == "testMethod" }))

        XCTAssertTrue(FileManager.default.fileExists(atPath: outDir.appendingPathComponent("environment.properties").path))
    }

    func testLabelExtractorDashed() {
        let labels = LabelExtractor.extract(testName: "Happy path Epic-Cart Severity-critical AllureID-1234 Owner-blysikov")
        XCTAssertTrue(labels.contains(Label(.allureId, value: "1234")))
        XCTAssertTrue(labels.contains(Label(.epic, value: "Cart")))
        XCTAssertTrue(labels.contains(Label(.severity, value: "critical")))
        XCTAssertTrue(labels.contains(Label(.owner, value: "blysikov")))
    }

    func testLabelExtractorCamelCase() {
        let labels = LabelExtractor.extract(testName: "testCheckout_EpicCart_FeatureCart_SeverityCritical_AllureID1234_OwnerBLysikov")
        XCTAssertTrue(labels.contains(Label(.allureId, value: "1234")))
        XCTAssertTrue(labels.contains(Label(.epic, value: "Cart")))
        XCTAssertTrue(labels.contains(Label(.feature, value: "Cart")))
        XCTAssertTrue(labels.contains(Label(.severity, value: "Critical")))
        XCTAssertTrue(labels.contains(Label(.owner, value: "BLysikov")))
    }

    func testLabelExtractorTagsArray() {
        let labels = LabelExtractor.extract(testName: "happyPath", tags: ["Epic-Cart", "smoke", "Severity-critical"])
        XCTAssertTrue(labels.contains(Label(.epic, value: "Cart")))
        XCTAssertTrue(labels.contains(Label(.severity, value: "critical")))
        // Untagged "smoke" doesn't match any prefix and is ignored.
        XCTAssertFalse(labels.contains(where: { $0.name == "tag" && $0.value == "smoke" }))
    }

    func testStatusMapping() {
        XCTAssertEqual(StatusMapper.map("Passed"), .passed)
        XCTAssertEqual(StatusMapper.map("Failed"), .failed)
        XCTAssertEqual(StatusMapper.map("Skipped"), .skipped)
        XCTAssertEqual(StatusMapper.map("Expected Failure"), .skipped)
        XCTAssertTrue(StatusMapper.isExpectedFailure("Expected Failure"))
        XCTAssertEqual(StatusMapper.map("Mysterious"), .broken)
    }
}
