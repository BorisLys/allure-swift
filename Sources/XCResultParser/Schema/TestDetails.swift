import Foundation

/// Top-level structure returned by `xcresulttool get test-results test-details`.
public struct TestDetails: Codable, Sendable {
    public let testIdentifier: String?
    public let testIdentifierURL: String?
    public let testName: String?
    public let testDescription: String?
    public let testResult: String?
    public let duration: String?
    public let durationInSeconds: Double?
    public let hasMediaAttachments: Bool?
    public let hasPerformanceMetrics: Bool?
    public let devices: [Device]?
    public let testPlanConfigurations: [TestPlanConfiguration]?
    public let testRuns: [TestNode]?

    public init(
        testIdentifier: String? = nil,
        testIdentifierURL: String? = nil,
        testName: String? = nil,
        testDescription: String? = nil,
        testResult: String? = nil,
        duration: String? = nil,
        durationInSeconds: Double? = nil,
        hasMediaAttachments: Bool? = nil,
        hasPerformanceMetrics: Bool? = nil,
        devices: [Device]? = nil,
        testPlanConfigurations: [TestPlanConfiguration]? = nil,
        testRuns: [TestNode]? = nil
    ) {
        self.testIdentifier = testIdentifier
        self.testIdentifierURL = testIdentifierURL
        self.testName = testName
        self.testDescription = testDescription
        self.testResult = testResult
        self.duration = duration
        self.durationInSeconds = durationInSeconds
        self.hasMediaAttachments = hasMediaAttachments
        self.hasPerformanceMetrics = hasPerformanceMetrics
        self.devices = devices
        self.testPlanConfigurations = testPlanConfigurations
        self.testRuns = testRuns
    }
}
