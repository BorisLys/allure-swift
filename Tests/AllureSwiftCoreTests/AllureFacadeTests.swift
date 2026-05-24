import XCTest
@testable import AllureSwiftCore

final class AllureFacadeTests: XCTestCase {
    private var tmpDir: URL!

    override func setUpWithError() throws {
        tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent("allure-facade-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        Allure.configure(directory: tmpDir)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
        AllureContext.setThreadCurrent(nil)
    }

    func testStepAndLabelsAndAttachments() throws {
        let uuid = UUID().uuidString.lowercased()
        Allure.startTest(TestResult(uuid: uuid, name: "facadeTest"))
        AllureContext.setThreadCurrent(uuid)

        Allure.epic("EpicX")
        Allure.feature("FeatureY")
        Allure.story("StoryZ")
        Allure.severity(.critical)
        Allure.owner("alice")
        Allure.tag("smoke")
        Allure.id(42)
        Allure.description("desc")
        Allure.link(name: "issue", url: "https://example/1", type: .issue)
        Allure.parameter(name: "p1", value: "v1")

        Allure.step("outer") {
            Allure.addAttachment(name: "info", type: .textPlain, content: "hello")
            Allure.step("inner") {
                Allure.parameter(name: "innerParam", value: "ok")
            }
        }

        Allure.stopTest(uuid: uuid, status: .passed)
        AllureLifecycle.shared.flush()
        AllureContext.setThreadCurrent(nil)

        let file = tmpDir.appendingPathComponent("\(uuid)-result.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
        let decoded = try JSONDecoder().decode(TestResult.self, from: try Data(contentsOf: file))
        let labelNames = Set(decoded.labels.map { "\($0.name)=\($0.value)" })
        XCTAssertTrue(labelNames.contains("epic=EpicX"))
        XCTAssertTrue(labelNames.contains("feature=FeatureY"))
        XCTAssertTrue(labelNames.contains("story=StoryZ"))
        XCTAssertTrue(labelNames.contains("severity=critical"))
        XCTAssertTrue(labelNames.contains("owner=alice"))
        XCTAssertTrue(labelNames.contains("tag=smoke"))
        XCTAssertTrue(labelNames.contains("AS_ID=42"))
        XCTAssertEqual(decoded.description, "desc")
        XCTAssertEqual(decoded.links.first?.url, "https://example/1")
        XCTAssertEqual(decoded.parameters.first?.name, "p1")
        XCTAssertEqual(decoded.steps.count, 1)
        XCTAssertEqual(decoded.steps[0].name, "outer")
        XCTAssertEqual(decoded.steps[0].attachments.count, 1)
        XCTAssertEqual(decoded.steps[0].steps.count, 1)
        XCTAssertEqual(decoded.steps[0].steps[0].name, "inner")
        XCTAssertEqual(decoded.steps[0].steps[0].parameters.first?.name, "innerParam")
    }

    func testStepFailurePropagatesAndMarksBroken() {
        struct Boom: Error {}
        let uuid = UUID().uuidString.lowercased()
        Allure.startTest(TestResult(uuid: uuid, name: "boom"))
        AllureContext.setThreadCurrent(uuid)

        XCTAssertThrowsError(try Allure.step("willFail") { throw Boom() })

        Allure.stopTest(uuid: uuid, status: .broken, details: StatusDetails(message: "Boom"))
        AllureLifecycle.shared.flush()
        AllureContext.setThreadCurrent(nil)

        let file = tmpDir.appendingPathComponent("\(uuid)-result.json")
        let decoded = try! JSONDecoder().decode(TestResult.self, from: try! Data(contentsOf: file))
        XCTAssertEqual(decoded.steps.first?.status, .broken)
        XCTAssertEqual(decoded.status, .broken)
    }
}
