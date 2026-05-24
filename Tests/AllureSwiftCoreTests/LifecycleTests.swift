import XCTest
@testable import AllureSwiftCore

final class LifecycleTests: XCTestCase {
    private var tmpDir: URL!
    private var lifecycle: AllureLifecycle!

    override func setUpWithError() throws {
        tmpDir = try makeTempDir()
        lifecycle = AllureLifecycle(directory: ResultsDirectory(url: tmpDir))
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
        tmpDir = nil
        lifecycle = nil
    }

    func testWritesTestResultFile() throws {
        let uuid = UUID().uuidString.lowercased()
        lifecycle.scheduleTest(TestResult(uuid: uuid, name: "myTest"))
        lifecycle.startTest(uuid: uuid)
        lifecycle.addLabel(testUUID: uuid, Label(.epic, value: "Smoke"))
        lifecycle.stopTest(uuid: uuid, status: .passed)
        lifecycle.flush()

        let file = tmpDir.appendingPathComponent("\(uuid)-result.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
        let data = try Data(contentsOf: file)
        let decoded = try JSONDecoder().decode(TestResult.self, from: data)
        XCTAssertEqual(decoded.status, .passed)
        XCTAssertEqual(decoded.labels.first?.name, LabelName.epic.rawValue)
        XCTAssertEqual(decoded.labels.first?.value, "Smoke")
        XCTAssertNotNil(decoded.start)
        XCTAssertNotNil(decoded.stop)
    }

    func testWritingDoesNotClearExistingResultsDirectory() throws {
        let staleFile = tmpDir.appendingPathComponent("stale-result.json")
        try Data("stale".utf8).write(to: staleFile)

        let uuid = UUID().uuidString.lowercased()
        lifecycle.scheduleTest(TestResult(uuid: uuid, name: "freshTest"))
        lifecycle.startTest(uuid: uuid)
        lifecycle.stopTest(uuid: uuid, status: .passed)
        lifecycle.flush()

        XCTAssertTrue(FileManager.default.fileExists(atPath: staleFile.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tmpDir.appendingPathComponent("\(uuid)-result.json").path))
    }

    func testPrepareResultsDirectoryClearsExistingFilesOnce() throws {
        let staleFile = tmpDir.appendingPathComponent("stale-result.json")
        try Data("stale".utf8).write(to: staleFile)

        lifecycle.prepareResultsDirectoryForTestRun()

        XCTAssertFalse(FileManager.default.fileExists(atPath: staleFile.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tmpDir.path))
    }

    func testDoesNotClearFilesWrittenAfterPrepare() throws {
        lifecycle.prepareResultsDirectoryForTestRun()

        let firstUUID = UUID().uuidString.lowercased()
        lifecycle.scheduleTest(TestResult(uuid: firstUUID, name: "firstTest"))
        lifecycle.startTest(uuid: firstUUID)
        lifecycle.stopTest(uuid: firstUUID, status: .passed)

        let secondUUID = UUID().uuidString.lowercased()
        lifecycle.scheduleTest(TestResult(uuid: secondUUID, name: "secondTest"))
        lifecycle.startTest(uuid: secondUUID)
        lifecycle.stopTest(uuid: secondUUID, status: .passed)
        lifecycle.flush()

        XCTAssertTrue(FileManager.default.fileExists(atPath: tmpDir.appendingPathComponent("\(firstUUID)-result.json").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tmpDir.appendingPathComponent("\(secondUUID)-result.json").path))
    }

    func testDoesNotPrepareDirectoryAgainForNewLifecycleWithSameDirectory() throws {
        lifecycle.prepareResultsDirectoryForTestRun()

        let firstUUID = UUID().uuidString.lowercased()
        lifecycle.scheduleTest(TestResult(uuid: firstUUID, name: "firstTest"))
        lifecycle.startTest(uuid: firstUUID)
        lifecycle.stopTest(uuid: firstUUID, status: .passed)
        lifecycle.flush()

        let nextLifecycle = AllureLifecycle(directory: ResultsDirectory(url: tmpDir))
        nextLifecycle.prepareResultsDirectoryForTestRun()
        let secondUUID = UUID().uuidString.lowercased()
        nextLifecycle.scheduleTest(TestResult(uuid: secondUUID, name: "secondTest"))
        nextLifecycle.startTest(uuid: secondUUID)
        nextLifecycle.stopTest(uuid: secondUUID, status: .passed)
        nextLifecycle.flush()

        XCTAssertTrue(FileManager.default.fileExists(atPath: tmpDir.appendingPathComponent("\(firstUUID)-result.json").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tmpDir.appendingPathComponent("\(secondUUID)-result.json").path))
    }

    func testNestedStepsTree() throws {
        let uuid = UUID().uuidString.lowercased()
        lifecycle.scheduleTest(TestResult(uuid: uuid, name: "stepsTest"))
        lifecycle.startTest(uuid: uuid)

        let s1 = UUID().uuidString.lowercased()
        let s11 = UUID().uuidString.lowercased()
        let s12 = UUID().uuidString.lowercased()
        let s2 = UUID().uuidString.lowercased()

        lifecycle.startStep(parentUUID: uuid, stepUUID: s1, step: StepResult(name: "outer"))
        lifecycle.startStep(parentUUID: uuid, stepUUID: s11, step: StepResult(name: "inner1"))
        lifecycle.stopStep(parentUUID: uuid, stepUUID: s11, status: .passed)
        lifecycle.startStep(parentUUID: uuid, stepUUID: s12, step: StepResult(name: "inner2"))
        lifecycle.stopStep(parentUUID: uuid, stepUUID: s12, status: .passed)
        lifecycle.stopStep(parentUUID: uuid, stepUUID: s1, status: .passed)
        lifecycle.startStep(parentUUID: uuid, stepUUID: s2, step: StepResult(name: "sibling"))
        lifecycle.stopStep(parentUUID: uuid, stepUUID: s2, status: .passed)

        lifecycle.stopTest(uuid: uuid, status: .passed)
        lifecycle.flush()

        let file = tmpDir.appendingPathComponent("\(uuid)-result.json")
        let decoded = try JSONDecoder().decode(TestResult.self, from: try Data(contentsOf: file))
        XCTAssertEqual(decoded.steps.count, 2)
        XCTAssertEqual(decoded.steps[0].name, "outer")
        XCTAssertEqual(decoded.steps[0].steps.count, 2)
        XCTAssertEqual(decoded.steps[0].steps[0].name, "inner1")
        XCTAssertEqual(decoded.steps[0].steps[1].name, "inner2")
        XCTAssertEqual(decoded.steps[1].name, "sibling")
        XCTAssertEqual(decoded.steps[1].steps.count, 0)
    }

    func testAttachmentInsideStep() throws {
        let uuid = UUID().uuidString.lowercased()
        lifecycle.scheduleTest(TestResult(uuid: uuid, name: "attach"))
        lifecycle.startTest(uuid: uuid)

        let s = UUID().uuidString.lowercased()
        lifecycle.startStep(parentUUID: uuid, stepUUID: s, step: StepResult(name: "step"))
        lifecycle.addAttachmentData(
            parentUUID: uuid,
            name: "log.txt",
            type: AttachmentType.textPlain.rawValue,
            data: Data("hello".utf8),
            fileExtension: nil
        )
        lifecycle.stopStep(parentUUID: uuid, stepUUID: s, status: .passed)
        lifecycle.stopTest(uuid: uuid, status: .passed)
        lifecycle.flush()

        let file = tmpDir.appendingPathComponent("\(uuid)-result.json")
        let decoded = try JSONDecoder().decode(TestResult.self, from: try Data(contentsOf: file))
        XCTAssertEqual(decoded.steps.count, 1)
        XCTAssertEqual(decoded.steps[0].attachments.count, 1)
        let source = decoded.steps[0].attachments[0].source
        XCTAssertTrue(source.hasSuffix("-attachment.txt"))
        let attachmentFile = tmpDir.appendingPathComponent(source)
        XCTAssertEqual(try String(contentsOf: attachmentFile), "hello")
    }

    func testContainerWithFixtures() throws {
        let cid = UUID().uuidString.lowercased()
        let testId = UUID().uuidString.lowercased()
        lifecycle.startContainer(TestResultContainer(uuid: cid, name: "Suite", children: [testId]))
        let fid = UUID().uuidString.lowercased()
        lifecycle.startBeforeFixture(containerUUID: cid, fixtureUUID: fid, fixture: FixtureResult(name: "setUp"))
        let stepUUID = UUID().uuidString.lowercased()
        lifecycle.startStep(parentUUID: cid, stepUUID: stepUUID, step: StepResult(name: "preparing"))
        lifecycle.stopStep(parentUUID: cid, stepUUID: stepUUID, status: .passed)
        lifecycle.stopFixture(containerUUID: cid, fixtureUUID: fid, status: .passed)
        lifecycle.stopContainer(uuid: cid)
        lifecycle.flush()

        let file = tmpDir.appendingPathComponent("\(cid)-container.json")
        let decoded = try JSONDecoder().decode(TestResultContainer.self, from: try Data(contentsOf: file))
        XCTAssertEqual(decoded.name, "Suite")
        XCTAssertEqual(decoded.children, [testId])
        XCTAssertEqual(decoded.befores.count, 1)
        XCTAssertEqual(decoded.befores[0].name, "setUp")
        XCTAssertEqual(decoded.befores[0].steps.count, 1)
        XCTAssertEqual(decoded.befores[0].steps[0].name, "preparing")
    }

    func testConcurrentTests() throws {
        let count = 50
        let lc = lifecycle!
        let group = DispatchGroup()
        for i in 0..<count {
            group.enter()
            DispatchQueue.global().async {
                let uuid = UUID().uuidString.lowercased()
                lc.scheduleTest(TestResult(uuid: uuid, name: "t\(i)"))
                lc.startTest(uuid: uuid)
                let s = UUID().uuidString.lowercased()
                lc.startStep(parentUUID: uuid, stepUUID: s, step: StepResult(name: "s\(i)"))
                lc.stopStep(parentUUID: uuid, stepUUID: s, status: .passed)
                lc.stopTest(uuid: uuid, status: .passed)
                group.leave()
            }
        }
        group.wait()
        lifecycle.flush()

        let files = try FileManager.default.contentsOfDirectory(atPath: tmpDir.path)
        let results = files.filter { $0.hasSuffix("-result.json") }
        XCTAssertEqual(results.count, count)
        for name in results {
            let url = tmpDir.appendingPathComponent(name)
            let decoded = try JSONDecoder().decode(TestResult.self, from: try Data(contentsOf: url))
            XCTAssertEqual(decoded.steps.count, 1)
            XCTAssertEqual(decoded.status, .passed)
        }
    }

    func testEnvironmentExecutorCategories() throws {
        lifecycle.writeEnvironment(EnvironmentInfo(["build": "1", "branch": "main"]))
        lifecycle.writeExecutor(ExecutorInfo(name: "GitHub", type: "ci", buildOrder: 7))
        lifecycle.writeCategories([
            Category(name: "Flaky", matchedStatuses: [.broken]),
            Category(name: "Outdated", messageRegex: ".*deprecated.*"),
        ])

        XCTAssertTrue(FileManager.default.fileExists(atPath: tmpDir.appendingPathComponent("environment.properties").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tmpDir.appendingPathComponent("executor.json").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tmpDir.appendingPathComponent("categories.json").path))
    }

    // MARK: - helpers

    private func makeTempDir() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("allure-swift-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
