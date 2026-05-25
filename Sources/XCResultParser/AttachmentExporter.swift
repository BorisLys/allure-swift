import Foundation

/// Convenience wrapper around `xcresulttool export attachments`.
///
/// Exports every attachment into `outputDir`, parses the manifest, and
/// indexes entries by `testIdentifierURL` for O(1) lookup during conversion.
public struct AttachmentExporter: Sendable {
    public let tool: XCResultTool

    public init(tool: XCResultTool = XCResultTool()) {
        self.tool = tool
    }

    /// Exports the attachments and returns the indexed manifest.
    public func export(bundle: URL, outputDir: URL) throws -> AttachmentIndex {
        let manifest = try tool.exportAttachments(bundle: bundle, outputDir: outputDir)
        return AttachmentIndex(entries: manifest, exportDir: outputDir)
    }
}

/// Indexed view over an `AttachmentManifest`.
public struct AttachmentIndex: Sendable {
    public let entries: AttachmentManifest
    public let exportDir: URL

    private let byTestURL: [String: ManifestEntry]
    private let byTestId: [String: ManifestEntry]

    public init(entries: AttachmentManifest, exportDir: URL) {
        self.entries = entries
        self.exportDir = exportDir
        var byURL: [String: ManifestEntry] = [:]
        var byId: [String: ManifestEntry] = [:]
        for entry in entries {
            if let url = entry.testIdentifierURL {
                byURL[url] = entry
                byURL[Self.normalize(url)] = entry
            }
            if let id = entry.testIdentifier {
                byId[id] = entry
            }
        }
        self.byTestURL = byURL
        self.byTestId = byId
    }

    /// Returns the manifest entry for a given test, looked up by URL or id.
    public func entry(forTestURL url: String?, testId: String? = nil) -> ManifestEntry? {
        if let url, let hit = byTestURL[url] ?? byTestURL[Self.normalize(url)] {
            return hit
        }
        if let testId, let hit = byTestId[testId] {
            return hit
        }
        return nil
    }

    /// Resolves the on-disk URL for an attachment from its manifest entry.
    public func fileURL(for attachment: ManifestAttachment) -> URL {
        exportDir.appendingPathComponent(attachment.exportedFileName)
    }

    /// Test identifier URLs can be reported with or without trailing `()`.
    /// Normalize for fuzzy matches.
    private static func normalize(_ url: String) -> String {
        if url.hasSuffix("()") { return String(url.dropLast(2)) }
        return url + "()"
    }
}
