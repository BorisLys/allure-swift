import Foundation

/// Top-level structure returned by `xcresulttool get test-results activities`.
public struct TestActivities: Codable, Sendable {
    public let testIdentifier: String?
    public let testIdentifierURL: String?
    public let testName: String?
    public let testRuns: [ActivityRun]?

    public init(
        testIdentifier: String? = nil,
        testIdentifierURL: String? = nil,
        testName: String? = nil,
        testRuns: [ActivityRun]? = nil
    ) {
        self.testIdentifier = testIdentifier
        self.testIdentifierURL = testIdentifierURL
        self.testName = testName
        self.testRuns = testRuns
    }
}

public struct ActivityRun: Codable, Sendable {
    public let device: Device?
    public let testPlanConfiguration: TestPlanConfiguration?
    public let activities: [Activity]?

    public init(
        device: Device? = nil,
        testPlanConfiguration: TestPlanConfiguration? = nil,
        activities: [Activity]? = nil
    ) {
        self.device = device
        self.testPlanConfiguration = testPlanConfiguration
        self.activities = activities
    }
}

/// One node inside the activity tree (recursive).
public struct Activity: Codable, Sendable {
    public let title: String
    public let startTime: Double?
    public let isAssociatedWithFailure: Bool?
    public let attachments: [ActivityAttachment]?
    public let childActivities: [Activity]?

    public init(
        title: String,
        startTime: Double? = nil,
        isAssociatedWithFailure: Bool? = nil,
        attachments: [ActivityAttachment]? = nil,
        childActivities: [Activity]? = nil
    ) {
        self.title = title
        self.startTime = startTime
        self.isAssociatedWithFailure = isAssociatedWithFailure
        self.attachments = attachments
        self.childActivities = childActivities
    }
}

public struct ActivityAttachment: Codable, Sendable, Hashable {
    public let name: String?
    public let timestamp: Double?
    public let uuid: String?
    public let payloadId: String?
    public let lifetime: String?

    public init(
        name: String? = nil,
        timestamp: Double? = nil,
        uuid: String? = nil,
        payloadId: String? = nil,
        lifetime: String? = nil
    ) {
        self.name = name
        self.timestamp = timestamp
        self.uuid = uuid
        self.payloadId = payloadId
        self.lifetime = lifetime
    }
}
