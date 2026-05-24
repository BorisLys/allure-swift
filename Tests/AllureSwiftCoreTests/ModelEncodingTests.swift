import XCTest
@testable import AllureSwiftCore

final class ModelEncodingTests: XCTestCase {
    func testStatusLowercase() throws {
        let encoder = JSONEncoderFactory.make()
        for s in Status.allCases {
            let json = String(data: try encoder.encode([s]), encoding: .utf8)!
            XCTAssertEqual(json, "[\"\(s.rawValue)\"]")
            XCTAssertEqual(s.rawValue, s.rawValue.lowercased())
        }
    }

    func testStageLowercase() throws {
        for s in Stage.allCases {
            XCTAssertEqual(s.rawValue, s.rawValue.lowercased())
        }
    }

    func testTestResultRoundTrip() throws {
        let encoder = JSONEncoderFactory.make()
        let decoder = JSONDecoder()
        let result = TestResult(
            uuid: "abc",
            historyId: "hist",
            fullName: "Module.Class.test",
            name: "test",
            description: "desc",
            status: .passed,
            stage: .finished,
            start: 1,
            stop: 2,
            labels: [Label(.epic, value: "E"), Label(.feature, value: "F")],
            links: [Link(name: "n", url: "https://x", type: "issue")],
            parameters: [Parameter(name: "p", value: "v")],
            steps: [
                StepResult(
                    name: "step1",
                    status: .passed,
                    stage: .finished,
                    start: 1,
                    stop: 2,
                    steps: [StepResult(name: "sub", status: .passed, stage: .finished)],
                    attachments: [Attachment(name: "log", source: "uuid-attachment.txt", type: "text/plain")]
                )
            ],
            attachments: [Attachment(name: "top", source: "x-attachment.txt", type: "text/plain")]
        )

        let data = try encoder.encode(result)
        let decoded = try decoder.decode(TestResult.self, from: data)
        XCTAssertEqual(decoded, result)
    }

    func testTestResultOmitsNilFields() throws {
        let encoder = JSONEncoderFactory.make()
        let result = TestResult(uuid: "abc", name: "t")
        let json = String(data: try encoder.encode(result), encoding: .utf8)!
        XCTAssertFalse(json.contains("\"description\""))
        XCTAssertFalse(json.contains("\"historyId\""))
        XCTAssertFalse(json.contains("\"status\""))
        XCTAssertTrue(json.contains("\"uuid\":\"abc\""))
        XCTAssertTrue(json.contains("\"name\":\"t\""))
    }

    func testContainerRoundTrip() throws {
        let encoder = JSONEncoderFactory.make()
        let container = TestResultContainer(
            uuid: "c-1",
            name: "Suite",
            children: ["child-1", "child-2"],
            befores: [FixtureResult(name: "setUp", status: .passed, stage: .finished, start: 0, stop: 1)],
            afters: [FixtureResult(name: "tearDown", status: .passed, stage: .finished, start: 2, stop: 3)],
            start: 0,
            stop: 10
        )
        let data = try encoder.encode(container)
        let decoded = try JSONDecoder().decode(TestResultContainer.self, from: data)
        XCTAssertEqual(decoded, container)
    }

    func testEnvironmentRender() {
        let env = EnvironmentInfo(["build": "42", "branch": "main"])
        let rendered = env.render()
        XCTAssertTrue(rendered.contains("branch=main"))
        XCTAssertTrue(rendered.contains("build=42"))
    }

    func testAttachmentTypeExtensions() {
        XCTAssertEqual(AttachmentType.imagePng.preferredExtension, "png")
        XCTAssertEqual(AttachmentType.applicationJson.preferredExtension, "json")
        XCTAssertEqual(AttachmentType.textPlain.preferredExtension, "txt")
    }
}
