import Foundation

/// Top-level structure returned by `xcresulttool get test-results tests`.
public struct TestsTree: Codable, Sendable {
    public let devices: [Device]?
    public let testNodes: [TestNode]
    public let testPlanConfigurations: [TestPlanConfiguration]?

    public init(
        devices: [Device]? = nil,
        testNodes: [TestNode],
        testPlanConfigurations: [TestPlanConfiguration]? = nil
    ) {
        self.devices = devices
        self.testNodes = testNodes
        self.testPlanConfigurations = testPlanConfigurations
    }
}

/// One node in the test result tree.
///
/// `nodeType` walks the hierarchy: `Test Plan` → `Unit test bundle` → `Test Suite`
/// → `Test Case` → `Repetition` → `Failure Message` / inner messages.
public struct TestNode: Codable, Sendable {
    public let name: String
    public let nodeType: String
    public let nodeIdentifier: String?
    public let nodeIdentifierURL: String?
    public let result: String?
    public let duration: String?
    public let durationInSeconds: Double?
    public let children: [TestNode]?
    public let details: String?
    public let tags: [String]?

    public init(
        name: String,
        nodeType: String,
        nodeIdentifier: String? = nil,
        nodeIdentifierURL: String? = nil,
        result: String? = nil,
        duration: String? = nil,
        durationInSeconds: Double? = nil,
        children: [TestNode]? = nil,
        details: String? = nil,
        tags: [String]? = nil
    ) {
        self.name = name
        self.nodeType = nodeType
        self.nodeIdentifier = nodeIdentifier
        self.nodeIdentifierURL = nodeIdentifierURL
        self.result = result
        self.duration = duration
        self.durationInSeconds = durationInSeconds
        self.children = children
        self.details = details
        self.tags = tags
    }
}

public struct Device: Codable, Sendable, Hashable {
    public let architecture: String?
    public let deviceId: String?
    public let deviceName: String?
    public let modelName: String?
    public let osBuildNumber: String?
    public let osVersion: String?
    public let platform: String?

    public init(
        architecture: String? = nil,
        deviceId: String? = nil,
        deviceName: String? = nil,
        modelName: String? = nil,
        osBuildNumber: String? = nil,
        osVersion: String? = nil,
        platform: String? = nil
    ) {
        self.architecture = architecture
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.modelName = modelName
        self.osBuildNumber = osBuildNumber
        self.osVersion = osVersion
        self.platform = platform
    }
}

public struct TestPlanConfiguration: Codable, Sendable, Hashable {
    public let configurationId: String
    public let configurationName: String

    public init(configurationId: String, configurationName: String) {
        self.configurationId = configurationId
        self.configurationName = configurationName
    }
}

extension TestNode {
    /// All test-case leaves under this node, flattened.
    public func flattenedTestCases() -> [TestNode] {
        if nodeType == "Test Case" {
            return [self]
        }
        return (children ?? []).flatMap { $0.flattenedTestCases() }
    }
}

extension TestsTree {
    /// All test cases across the whole tree.
    public func allTestCases() -> [TestNode] {
        testNodes.flatMap { $0.flattenedTestCases() }
    }
}
