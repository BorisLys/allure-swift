import Foundation

public enum Allure {
    // MARK: - Configuration

    public static func configure(directory: URL) {
        AllureLifecycle.shared.configure(directory: ResultsDirectory(url: directory))
        AllureLifecycle.shared.prepareResultsDirectoryForTestRun()
    }

    public static var resultsDirectoryURL: URL {
        AllureLifecycle.shared.resultsDirectory
    }

    public static var lifecycle: AllureLifecycle { .shared }

    public static var currentTestUUID: String? { AllureContext.current }

    // MARK: - Lifecycle entry points (used by framework integrations)

    @discardableResult
    public static func startTest(_ result: TestResult) -> String {
        let uuid = AllureLifecycle.shared.scheduleTest(result)
        AllureLifecycle.shared.startTest(uuid: uuid)
        return uuid
    }

    public static func stopTest(uuid: String, status: Status? = nil, details: StatusDetails? = nil) {
        AllureLifecycle.shared.stopTest(uuid: uuid, status: status, details: details)
    }

    @discardableResult
    public static func startContainer(_ container: TestResultContainer) -> String {
        AllureLifecycle.shared.startContainer(container)
    }

    public static func stopContainer(uuid: String) {
        AllureLifecycle.shared.stopContainer(uuid: uuid)
    }

    // MARK: - Steps

    @discardableResult
    public static func step<R>(_ name: String, perform: () throws -> R) rethrows -> R {
        guard let parentUUID = AllureContext.current else {
            return try perform()
        }
        let stepUUID = UUID().uuidString.lowercased()
        let step = StepResult(name: name)
        AllureLifecycle.shared.startStep(parentUUID: parentUUID, stepUUID: stepUUID, step: step)
        do {
            let result = try perform()
            AllureLifecycle.shared.stopStep(parentUUID: parentUUID, stepUUID: stepUUID, status: .passed)
            return result
        } catch {
            AllureLifecycle.shared.stopStep(
                parentUUID: parentUUID,
                stepUUID: stepUUID,
                status: errorStatus(error),
                details: StatusDetails(message: String(describing: error))
            )
            throw error
        }
    }

    @discardableResult
    public static func step<R: Sendable>(
        _ name: String,
        perform: () async throws -> R
    ) async rethrows -> R {
        guard let parentUUID = AllureContext.current else {
            return try await perform()
        }
        let stepUUID = UUID().uuidString.lowercased()
        let step = StepResult(name: name)
        AllureLifecycle.shared.startStep(parentUUID: parentUUID, stepUUID: stepUUID, step: step)
        do {
            let result = try await perform()
            AllureLifecycle.shared.stopStep(parentUUID: parentUUID, stepUUID: stepUUID, status: .passed)
            return result
        } catch {
            AllureLifecycle.shared.stopStep(
                parentUUID: parentUUID,
                stepUUID: stepUUID,
                status: errorStatus(error),
                details: StatusDetails(message: String(describing: error))
            )
            throw error
        }
    }

    private static func errorStatus(_ error: Error) -> Status {
        // assertion-style errors map to .failed; others to .broken.
        // Default to .broken; XCTest/Swift Testing integrations can override.
        .broken
    }

    // MARK: - Attachments

    public static func addAttachment(name: String, type: AttachmentType = .textPlain, content: String) {
        guard let parent = AllureContext.current else { return }
        AllureLifecycle.shared.addAttachmentData(
            parentUUID: parent,
            name: name,
            type: type.rawValue,
            data: Data(content.utf8),
            fileExtension: type.preferredExtension
        )
    }

    public static func addAttachment(
        name: String,
        type: String,
        data: Data,
        fileExtension: String? = nil
    ) {
        guard let parent = AllureContext.current else { return }
        AllureLifecycle.shared.addAttachmentData(
            parentUUID: parent,
            name: name,
            type: type,
            data: data,
            fileExtension: fileExtension
        )
    }

    public static func addAttachment(
        name: String,
        type: AttachmentType,
        data: Data,
        fileExtension: String? = nil
    ) {
        addAttachment(name: name, type: type.rawValue, data: data, fileExtension: fileExtension ?? type.preferredExtension)
    }

    // MARK: - Labels

    public static func label(name: String, value: String) {
        guard let uuid = AllureContext.current else { return }
        AllureLifecycle.shared.addLabel(testUUID: uuid, Label(name: name, value: value))
    }

    public static func label(_ name: LabelName, value: String) {
        label(name: name.rawValue, value: value)
    }

    public static func epic(_ value: String) { label(.epic, value: value) }
    public static func feature(_ value: String) { label(.feature, value: value) }
    public static func story(_ value: String) { label(.story, value: value) }
    public static func owner(_ value: String) { label(.owner, value: value) }
    public static func tag(_ value: String) { label(.tag, value: value) }
    public static func severity(_ value: Severity) { label(.severity, value: value.rawValue) }
    public static func suite(_ value: String) { label(.suite, value: value) }
    public static func parentSuite(_ value: String) { label(.parentSuite, value: value) }
    public static func subSuite(_ value: String) { label(.subSuite, value: value) }
    public static func id(_ value: Int) { label(.allureId, value: String(value)) }
    public static func id(_ value: String) { label(.allureId, value: value) }

    public static func description(_ value: String) {
        guard let uuid = AllureContext.current else { return }
        AllureLifecycle.shared.updateTest(uuid: uuid) { $0.description = value }
    }

    public static func descriptionHtml(_ value: String) {
        guard let uuid = AllureContext.current else { return }
        AllureLifecycle.shared.updateTest(uuid: uuid) { $0.descriptionHtml = value }
    }

    public static func displayName(_ value: String) {
        guard let uuid = AllureContext.current else { return }
        AllureLifecycle.shared.updateTest(uuid: uuid) { $0.name = value }
    }

    // MARK: - Links

    public static func link(name: String? = nil, url: String, type: String? = nil) {
        guard let uuid = AllureContext.current else { return }
        AllureLifecycle.shared.addLink(testUUID: uuid, Link(name: name, url: url, type: type))
    }

    public static func link(name: String? = nil, url: String, type: LinkType) {
        link(name: name, url: url, type: type.rawValue)
    }

    public static func issue(name: String? = nil, url: String) {
        link(name: name, url: url, type: .issue)
    }

    public static func tms(name: String? = nil, url: String) {
        link(name: name, url: url, type: .tms)
    }

    // MARK: - Parameters

    public static func parameter(
        name: String,
        value: String,
        excluded: Bool? = nil,
        mode: Parameter.Mode? = nil
    ) {
        guard let parent = AllureContext.current else { return }
        AllureLifecycle.shared.addParameter(
            parentUUID: parent,
            Parameter(name: name, value: value, excluded: excluded, mode: mode)
        )
    }

    // MARK: - Environment / executor / categories

    public static func writeEnvironment(_ env: EnvironmentInfo) {
        AllureLifecycle.shared.writeEnvironment(env)
    }

    public static func writeExecutor(_ executor: ExecutorInfo) {
        AllureLifecycle.shared.writeExecutor(executor)
    }

    public static func writeCategories(_ categories: [Category]) {
        AllureLifecycle.shared.writeCategories(categories)
    }
}
