import Foundation

/// Top-level structure of the `manifest.json` written by
/// `xcresulttool export attachments --output-path <dir>`.
public typealias AttachmentManifest = [ManifestEntry]

/// One entry per test case in the manifest.
public struct ManifestEntry: Codable, Sendable {
    public let testIdentifier: String?
    public let testIdentifierURL: String?
    public let attachments: [ManifestAttachment]

    public init(
        testIdentifier: String? = nil,
        testIdentifierURL: String? = nil,
        attachments: [ManifestAttachment]
    ) {
        self.testIdentifier = testIdentifier
        self.testIdentifierURL = testIdentifierURL
        self.attachments = attachments
    }
}

public struct ManifestAttachment: Codable, Sendable, Hashable {
    public let exportedFileName: String
    public let suggestedHumanReadableName: String?
    public let configurationName: String?
    public let deviceId: String?
    public let deviceName: String?
    public let repetitionNumber: Int?
    public let isAssociatedWithFailure: Bool?
    public let timestamp: Double?

    public init(
        exportedFileName: String,
        suggestedHumanReadableName: String? = nil,
        configurationName: String? = nil,
        deviceId: String? = nil,
        deviceName: String? = nil,
        repetitionNumber: Int? = nil,
        isAssociatedWithFailure: Bool? = nil,
        timestamp: Double? = nil
    ) {
        self.exportedFileName = exportedFileName
        self.suggestedHumanReadableName = suggestedHumanReadableName
        self.configurationName = configurationName
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.repetitionNumber = repetitionNumber
        self.isAssociatedWithFailure = isAssociatedWithFailure
        self.timestamp = timestamp
    }
}
