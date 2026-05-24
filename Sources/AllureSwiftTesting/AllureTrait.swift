import Foundation
import Testing
import AllureSwiftCore

public struct AllureTrait: TestTrait, SuiteTrait, TestScoping, Sendable {
    public let isRecursive: Bool

    public init(isRecursive: Bool = true) {
        self.isRecursive = isRecursive
    }

    public func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        guard !test.isSuite else {
            try await function()
            return
        }

        let uuid = UUID().uuidString.lowercased()
        let meta = TestMetadata.build(for: test)
        let labels = TestMetadata.defaultLabels(for: test, meta: meta)

        let result = TestResult(
            uuid: uuid,
            historyId: AllureHashing.sha256Hex(meta.fullName),
            fullName: meta.fullName,
            name: meta.displayName,
            stage: .running,
            start: Date.allureNow,
            labels: labels
        )
        AllureLifecycle.shared.scheduleTest(result)
        AllureLifecycle.shared.startTest(uuid: uuid)

        // Apply metadata traits attached to this test.
        for trait in test.traits {
            if let metadata = trait as? any AllureMetadataTrait {
                metadata.apply(testUUID: uuid)
            }
        }

        var status: Status = .passed
        var details: StatusDetails?
        do {
            try await AllureContext.$currentUUID.withValue(uuid) {
                try await function()
            }
        } catch {
            if Self.isKnownIssueError(error) {
                status = .skipped
                details = StatusDetails(message: String(describing: error))
            } else {
                status = .failed
                details = StatusDetails(
                    message: String(describing: error),
                    trace: nil
                )
            }
            AllureLifecycle.shared.stopTest(uuid: uuid, status: status, details: details)
            throw error
        }
        AllureLifecycle.shared.stopTest(uuid: uuid, status: status, details: details)
    }

    private static func isKnownIssueError(_ error: Error) -> Bool {
        let name = String(describing: type(of: error))
        return name.contains("Skip") || name.contains("KnownIssue")
    }
}

public extension Trait where Self == AllureTrait {
    static var allure: Self { AllureTrait() }
    static func allure(isRecursive: Bool) -> Self { AllureTrait(isRecursive: isRecursive) }
}

public extension Trait where Self == AllureIDTrait {
    static func allureID(_ value: Int) -> Self { AllureIDTrait(value) }
    static func allureID(_ value: String) -> Self { AllureIDTrait(value) }
}

public extension Trait where Self == EpicTrait {
    static func epic(_ value: String) -> Self { EpicTrait(value) }
}

public extension Trait where Self == FeatureTrait {
    static func feature(_ value: String) -> Self { FeatureTrait(value) }
}

public extension Trait where Self == StoryTrait {
    static func story(_ value: String) -> Self { StoryTrait(value) }
}

public extension Trait where Self == SeverityTrait {
    static func severity(_ value: Severity) -> Self { SeverityTrait(value) }
}

public extension Trait where Self == OwnerTrait {
    static func owner(_ value: String) -> Self { OwnerTrait(value) }
}

public extension Trait where Self == AllureTagTrait {
    static func allureTag(_ value: String) -> Self { AllureTagTrait(value) }
}

public extension Trait where Self == LabelTrait {
    static func label(name: String, value: String) -> Self { LabelTrait(name: name, value: value) }
    static func label(_ name: LabelName, value: String) -> Self { LabelTrait(name, value: value) }
}

public extension Trait where Self == LinkTrait {
    static func link(name: String? = nil, url: String, type: String? = nil) -> Self {
        LinkTrait(name: name, url: url, type: type)
    }
    static func link(name: String? = nil, url: String, type: LinkType) -> Self {
        LinkTrait(name: name, url: url, type: type)
    }
}

public extension Trait where Self == DescriptionTrait {
    static func allureDescription(_ value: String, html: Bool = false) -> Self {
        DescriptionTrait(value, html: html)
    }
}
