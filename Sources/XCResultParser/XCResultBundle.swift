import Foundation

/// Entry-point façade for parsing an `.xcresult` bundle.
///
/// Hides the multiple `xcresulttool` invocations behind a single value type.
/// Reads everything eagerly except per-test details/activities, which are
/// loaded lazily so the converter can iterate without re-running `tests` or
/// `summary` lookups.
public struct XCResultBundle: Sendable {
    public let url: URL
    public let tool: XCResultTool

    public init(url: URL, tool: XCResultTool = XCResultTool()) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw XCResultToolError.bundleMissing(url)
        }
        self.url = url
        self.tool = tool
    }

    public func summary() throws -> TestSummary {
        try tool.getSummary(bundle: url)
    }

    public func tests() throws -> TestsTree {
        try tool.getTests(bundle: url)
    }

    public func details(forTestURL testIdURL: String) throws -> TestDetails {
        try tool.getTestDetails(bundle: url, testIdURL: testIdURL)
    }

    public func activities(forTestURL testIdURL: String) throws -> TestActivities {
        try tool.getActivities(bundle: url, testIdURL: testIdURL)
    }

    /// Exports all attachments into `outputDir` (created if missing) and
    /// returns the indexed manifest.
    public func exportAttachments(to outputDir: URL) throws -> AttachmentIndex {
        try AttachmentExporter(tool: tool).export(bundle: url, outputDir: outputDir)
    }
}
