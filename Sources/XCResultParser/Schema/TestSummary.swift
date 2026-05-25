import Foundation

/// Top-level structure returned by `xcresulttool get test-results summary`.
public struct TestSummary: Codable, Sendable {
    public let title: String?
    public let environmentDescription: String?
    public let result: String?
    public let startTime: Double?
    public let finishTime: Double?
    public let totalTestCount: Int?
    public let passedTests: Int?
    public let failedTests: Int?
    public let skippedTests: Int?
    public let expectedFailures: Int?
    public let devicesAndConfigurations: [DeviceConfiguration]?
    public let testFailures: [TestFailure]?

    public init(
        title: String? = nil,
        environmentDescription: String? = nil,
        result: String? = nil,
        startTime: Double? = nil,
        finishTime: Double? = nil,
        totalTestCount: Int? = nil,
        passedTests: Int? = nil,
        failedTests: Int? = nil,
        skippedTests: Int? = nil,
        expectedFailures: Int? = nil,
        devicesAndConfigurations: [DeviceConfiguration]? = nil,
        testFailures: [TestFailure]? = nil
    ) {
        self.title = title
        self.environmentDescription = environmentDescription
        self.result = result
        self.startTime = startTime
        self.finishTime = finishTime
        self.totalTestCount = totalTestCount
        self.passedTests = passedTests
        self.failedTests = failedTests
        self.skippedTests = skippedTests
        self.expectedFailures = expectedFailures
        self.devicesAndConfigurations = devicesAndConfigurations
        self.testFailures = testFailures
    }
}

public struct DeviceConfiguration: Codable, Sendable, Hashable {
    public let device: Device
    public let testPlanConfiguration: TestPlanConfiguration?
    public let passedTests: Int?
    public let failedTests: Int?
    public let skippedTests: Int?
    public let expectedFailures: Int?

    public init(
        device: Device,
        testPlanConfiguration: TestPlanConfiguration? = nil,
        passedTests: Int? = nil,
        failedTests: Int? = nil,
        skippedTests: Int? = nil,
        expectedFailures: Int? = nil
    ) {
        self.device = device
        self.testPlanConfiguration = testPlanConfiguration
        self.passedTests = passedTests
        self.failedTests = failedTests
        self.skippedTests = skippedTests
        self.expectedFailures = expectedFailures
    }
}

public struct TestFailure: Codable, Sendable, Hashable {
    public let testName: String?
    public let targetName: String?
    public let failureText: String?
    public let testIdentifier: String?
    public let testIdentifierURL: String?

    public init(
        testName: String? = nil,
        targetName: String? = nil,
        failureText: String? = nil,
        testIdentifier: String? = nil,
        testIdentifierURL: String? = nil
    ) {
        self.testName = testName
        self.targetName = targetName
        self.failureText = failureText
        self.testIdentifier = testIdentifier
        self.testIdentifierURL = testIdentifierURL
    }
}
