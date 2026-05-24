import Foundation
import os

public final class AllureLifecycle: @unchecked Sendable {
    public static let shared = AllureLifecycle()

    private struct State {
        var tests: [String: TestRecord] = [:]
        var containers: [String: ContainerRecord] = [:]
        var directory: ResultsDirectory
        var writer: FileWriter

        init(directory: ResultsDirectory) {
            self.directory = directory
            self.writer = FileWriter(directory: directory)
        }
    }

    private let lock: OSAllocatedUnfairLock<State>

    public init(directory: ResultsDirectory? = nil) {
        let dir = directory ?? ResultsDirectory.resolve()
        self.lock = OSAllocatedUnfairLock(initialState: State(directory: dir))
    }

    public func configure(directory: ResultsDirectory) {
        lock.withLock { state in
            state.directory = directory
            state.writer = FileWriter(directory: directory)
        }
    }

    public var resultsDirectory: URL {
        lock.withLock { $0.directory.url }
    }

    // MARK: - Tests

    @discardableResult
    public func scheduleTest(_ result: TestResult) -> String {
        lock.withLock { state in
            var record = TestRecord(result: result)
            if record.result.stage == nil { record.result.stage = .scheduled }
            state.tests[result.uuid] = record
            return result.uuid
        }
    }

    public func startTest(uuid: String, startTime: Int64 = Date.allureNow) {
        lock.withLock { state in
            guard var record = state.tests[uuid] else { return }
            record.result.stage = .running
            record.result.start = record.result.start ?? startTime
            state.tests[uuid] = record
        }
    }

    public func updateTest(uuid: String, _ mutator: @Sendable (inout TestResult) -> Void) {
        lock.withLock { state in
            guard var record = state.tests[uuid] else { return }
            mutator(&record.result)
            state.tests[uuid] = record
        }
    }

    public func stopTest(
        uuid: String,
        status: Status? = nil,
        details: StatusDetails? = nil,
        stopTime: Int64 = Date.allureNow
    ) {
        let toWrite: (FileWriter, TestResult)? = lock.withLock { state in
            guard var record = state.tests.removeValue(forKey: uuid) else { return nil }
            record.result.stage = .finished
            record.result.stop = record.result.stop ?? stopTime
            if let status { record.result.status = status }
            if let details { record.result.statusDetails = details }
            return (state.writer, record.result)
        }
        guard let (writer, payload) = toWrite else { return }
        do { try writer.write(testResult: payload) } catch { Self.logIO(error: error) }
    }

    // MARK: - Containers

    @discardableResult
    public func startContainer(_ container: TestResultContainer, startTime: Int64 = Date.allureNow) -> String {
        lock.withLock { state in
            var record = ContainerRecord(container: container)
            record.container.start = record.container.start ?? startTime
            state.containers[container.uuid] = record
            return container.uuid
        }
    }

    public func updateContainer(uuid: String, _ mutator: @Sendable (inout TestResultContainer) -> Void) {
        lock.withLock { state in
            guard var record = state.containers[uuid] else { return }
            mutator(&record.container)
            state.containers[uuid] = record
        }
    }

    public func stopContainer(uuid: String, stopTime: Int64 = Date.allureNow) {
        let toWrite: (FileWriter, TestResultContainer)? = lock.withLock { state in
            guard var record = state.containers.removeValue(forKey: uuid) else { return nil }
            record.container.stop = record.container.stop ?? stopTime
            return (state.writer, record.container)
        }
        guard let (writer, payload) = toWrite else { return }
        do { try writer.write(container: payload) } catch { Self.logIO(error: error) }
    }

    // MARK: - Fixtures

    public func startBeforeFixture(containerUUID: String, fixtureUUID: String, fixture: FixtureResult) {
        startFixture(containerUUID: containerUUID, fixtureUUID: fixtureUUID, fixture: fixture, isBefore: true)
    }

    public func startAfterFixture(containerUUID: String, fixtureUUID: String, fixture: FixtureResult) {
        startFixture(containerUUID: containerUUID, fixtureUUID: fixtureUUID, fixture: fixture, isBefore: false)
    }

    private func startFixture(containerUUID: String, fixtureUUID: String, fixture: FixtureResult, isBefore: Bool) {
        lock.withLock { state in
            guard var record = state.containers[containerUUID] else { return }
            var f = fixture
            f.stage = .running
            f.start = f.start ?? Date.allureNow
            record.fixturesByUUID[fixtureUUID] = FixtureEntry(isBefore: isBefore, fixture: f, stepStack: [])
            record.activeFixtureUUID = fixtureUUID
            state.containers[containerUUID] = record
        }
    }

    public func stopFixture(
        containerUUID: String,
        fixtureUUID: String,
        status: Status? = nil,
        details: StatusDetails? = nil
    ) {
        lock.withLock { state in
            guard var record = state.containers[containerUUID],
                  var entry = record.fixturesByUUID.removeValue(forKey: fixtureUUID) else { return }
            entry.fixture.stage = .finished
            entry.fixture.stop = entry.fixture.stop ?? Date.allureNow
            if let status { entry.fixture.status = status }
            if let details { entry.fixture.statusDetails = details }
            if entry.isBefore {
                record.container.befores.append(entry.fixture)
            } else {
                record.container.afters.append(entry.fixture)
            }
            if record.activeFixtureUUID == fixtureUUID {
                record.activeFixtureUUID = nil
            }
            state.containers[containerUUID] = record
        }
    }

    // MARK: - Steps

    public func startStep(parentUUID: String, stepUUID: String, step: StepResult) {
        lock.withLock { state in
            var prepared = step
            prepared.stage = .running
            prepared.start = prepared.start ?? Date.allureNow

            if var record = state.tests[parentUUID] {
                let parentPath = record.stepStack.map(\.index)
                let newIndex = Self.append(step: prepared, into: &record.result.steps, path: parentPath)
                record.stepStack.append(StepFrame(uuid: stepUUID, index: newIndex))
                state.tests[parentUUID] = record
                return
            }
            if var record = state.containers[parentUUID],
               let fixtureUUID = record.activeFixtureUUID,
               var entry = record.fixturesByUUID[fixtureUUID] {
                let parentPath = entry.stepStack.map(\.index)
                let newIndex = Self.append(step: prepared, into: &entry.fixture.steps, path: parentPath)
                entry.stepStack.append(StepFrame(uuid: stepUUID, index: newIndex))
                record.fixturesByUUID[fixtureUUID] = entry
                state.containers[parentUUID] = record
            }
        }
    }

    public func updateStep(parentUUID: String, stepUUID: String, _ mutator: @Sendable (inout StepResult) -> Void) {
        lock.withLock { state in
            Self.mutateStep(state: &state, parentUUID: parentUUID, stepUUID: stepUUID, mutator: mutator)
        }
    }

    public func stopStep(
        parentUUID: String,
        stepUUID: String,
        status: Status? = nil,
        details: StatusDetails? = nil
    ) {
        lock.withLock { state in
            Self.mutateStep(state: &state, parentUUID: parentUUID, stepUUID: stepUUID) { step in
                step.stage = .finished
                step.stop = step.stop ?? Date.allureNow
                if let status { step.status = status }
                if let details { step.statusDetails = details }
            }
            Self.popStep(state: &state, parentUUID: parentUUID, stepUUID: stepUUID)
        }
    }

    // MARK: - Attachments / labels / parameters / links

    public func addAttachment(parentUUID: String, attachment: Attachment) {
        lock.withLock { state in
            Self.applyToCurrent(
                state: &state,
                parentUUID: parentUUID,
                onStep: { $0.attachments.append(attachment) },
                onTest: { $0.attachments.append(attachment) },
                onFixture: { $0.attachments.append(attachment) }
            )
        }
    }

    public func addAttachmentData(
        parentUUID: String,
        name: String?,
        type: String?,
        data: Data,
        fileExtension: String?
    ) {
        let ext: String = {
            if let fileExtension, !fileExtension.isEmpty {
                return fileExtension.hasPrefix(".") ? String(fileExtension.dropFirst()) : fileExtension
            }
            if let type, let t = AttachmentType(rawValue: type) {
                return t.preferredExtension
            }
            return "bin"
        }()
        let source = "\(UUID().uuidString.lowercased())-attachment.\(ext)"
        let attachment = Attachment(name: name, source: source, type: type)
        let writer = lock.withLock { $0.writer }
        do { try writer.write(attachmentData: data, source: source) }
        catch { Self.logIO(error: error); return }
        addAttachment(parentUUID: parentUUID, attachment: attachment)
    }

    public func addLabel(testUUID: String, _ label: Label) {
        updateTest(uuid: testUUID) { $0.labels.append(label) }
    }

    public func addLink(testUUID: String, _ link: Link) {
        updateTest(uuid: testUUID) { $0.links.append(link) }
    }

    public func addParameter(parentUUID: String, _ parameter: Parameter) {
        lock.withLock { state in
            Self.applyToCurrent(
                state: &state,
                parentUUID: parentUUID,
                onStep: { $0.parameters.append(parameter) },
                onTest: { $0.parameters.append(parameter) },
                onFixture: { $0.parameters.append(parameter) }
            )
        }
    }

    // MARK: - Writer passthrough

    public func writeEnvironment(_ env: EnvironmentInfo) {
        let writer = lock.withLock { $0.writer }
        do { try writer.writeEnvironment(env) } catch { Self.logIO(error: error) }
    }

    public func writeExecutor(_ executor: ExecutorInfo) {
        let writer = lock.withLock { $0.writer }
        do { try writer.writeExecutor(executor) } catch { Self.logIO(error: error) }
    }

    public func writeCategories(_ categories: [Category]) {
        let writer = lock.withLock { $0.writer }
        do { try writer.writeCategories(categories) } catch { Self.logIO(error: error) }
    }

    public func flush() {
        let writer = lock.withLock { $0.writer }
        writer.flush()
    }

    // MARK: - Internals

    private static func append(step: StepResult, into steps: inout [StepResult], path: [Int]) -> Int {
        if path.isEmpty {
            steps.append(step)
            return steps.count - 1
        }
        let head = path[0]
        guard head < steps.count else {
            steps.append(step)
            return steps.count - 1
        }
        return append(step: step, into: &steps[head].steps, path: Array(path.dropFirst()))
    }

    private static func mutateStep(
        state: inout State,
        parentUUID: String,
        stepUUID: String,
        mutator: @Sendable (inout StepResult) -> Void
    ) {
        if var record = state.tests[parentUUID] {
            guard let path = pathTo(stepUUID: stepUUID, stack: record.stepStack) else { return }
            mutateStep(in: &record.result.steps, path: path, mutator: mutator)
            state.tests[parentUUID] = record
            return
        }
        if var record = state.containers[parentUUID],
           let fixtureUUID = record.activeFixtureUUID,
           var entry = record.fixturesByUUID[fixtureUUID] {
            guard let path = pathTo(stepUUID: stepUUID, stack: entry.stepStack) else { return }
            mutateStep(in: &entry.fixture.steps, path: path, mutator: mutator)
            record.fixturesByUUID[fixtureUUID] = entry
            state.containers[parentUUID] = record
        }
    }

    private static func popStep(state: inout State, parentUUID: String, stepUUID: String) {
        if var record = state.tests[parentUUID] {
            if let idx = record.stepStack.lastIndex(where: { $0.uuid == stepUUID }) {
                record.stepStack.removeSubrange(idx..<record.stepStack.count)
            }
            state.tests[parentUUID] = record
            return
        }
        if var record = state.containers[parentUUID],
           let fixtureUUID = record.activeFixtureUUID,
           var entry = record.fixturesByUUID[fixtureUUID] {
            if let idx = entry.stepStack.lastIndex(where: { $0.uuid == stepUUID }) {
                entry.stepStack.removeSubrange(idx..<entry.stepStack.count)
            }
            record.fixturesByUUID[fixtureUUID] = entry
            state.containers[parentUUID] = record
        }
    }

    private static func applyToCurrent(
        state: inout State,
        parentUUID: String,
        onStep: @Sendable (inout StepResult) -> Void,
        onTest: @Sendable (inout TestResult) -> Void,
        onFixture: @Sendable (inout FixtureResult) -> Void
    ) {
        if var record = state.tests[parentUUID] {
            if record.stepStack.isEmpty {
                onTest(&record.result)
            } else {
                let path = record.stepStack.map(\.index)
                mutateStep(in: &record.result.steps, path: path, mutator: onStep)
            }
            state.tests[parentUUID] = record
            return
        }
        if var record = state.containers[parentUUID],
           let fixtureUUID = record.activeFixtureUUID,
           var entry = record.fixturesByUUID[fixtureUUID] {
            if entry.stepStack.isEmpty {
                onFixture(&entry.fixture)
            } else {
                let path = entry.stepStack.map(\.index)
                mutateStep(in: &entry.fixture.steps, path: path, mutator: onStep)
            }
            record.fixturesByUUID[fixtureUUID] = entry
            state.containers[parentUUID] = record
        }
    }

    private static func pathTo(stepUUID: String, stack: [StepFrame]) -> [Int]? {
        guard let pos = stack.firstIndex(where: { $0.uuid == stepUUID }) else { return nil }
        return stack.prefix(through: pos).map(\.index)
    }

    private static func mutateStep(
        in steps: inout [StepResult],
        path: [Int],
        mutator: @Sendable (inout StepResult) -> Void
    ) {
        guard !path.isEmpty else { return }
        let head = path[0]
        guard head < steps.count else { return }
        if path.count == 1 {
            mutator(&steps[head])
        } else {
            mutateStep(in: &steps[head].steps, path: Array(path.dropFirst()), mutator: mutator)
        }
    }

    private static func logIO(error: Error) {
        let logger = Logger(subsystem: "io.allure.swift", category: "io")
        logger.error("allure-swift IO error: \(String(describing: error), privacy: .public)")
    }
}
