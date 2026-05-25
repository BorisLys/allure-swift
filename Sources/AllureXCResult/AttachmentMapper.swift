import Foundation
import AllureSwiftCore
import XCResultParser

/// Copies xcresult-exported attachments into the Allure results directory
/// (with `<uuid>-attachment.<ext>` names) and produces matching `Attachment`
/// records.
public struct AttachmentMapper {
    public let outputDir: URL
    private let fileManager: FileManager

    public init(outputDir: URL, fileManager: FileManager = .default) {
        self.outputDir = outputDir
        self.fileManager = fileManager
    }

    /// Maps each exported attachment to an Allure `Attachment` and copies
    /// the file. Returns the records to embed into the surrounding
    /// `TestResult` / `StepResult`.
    public func map(_ attachments: [ManifestAttachment], index: AttachmentIndex) -> [Attachment] {
        attachments.compactMap { entry in
            let source = index.fileURL(for: entry)
            guard fileManager.fileExists(atPath: source.path) else { return nil }
            let ext = Self.extension(for: source)
            let allureSource = "\(UUID().uuidString.lowercased())-attachment.\(ext)"
            let destination = outputDir.appendingPathComponent(allureSource)
            do {
                try? fileManager.removeItem(at: destination)
                try fileManager.copyItem(at: source, to: destination)
            } catch {
                return nil
            }
            return Attachment(
                name: entry.suggestedHumanReadableName ?? source.lastPathComponent,
                source: allureSource,
                type: Self.mimeType(for: ext)
            )
        }
    }

    private static func `extension`(for url: URL) -> String {
        let ext = url.pathExtension
        if !ext.isEmpty { return ext }
        // Many xcresult attachments come without an extension (e.g. raw
        // synthesized events). Default to "bin" so the file is still copied
        // and the report can still reference it.
        return "bin"
    }

    private static func mimeType(for ext: String) -> String? {
        switch ext.lowercased() {
        case "png":  return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif":  return "image/gif"
        case "svg":  return "image/svg+xml"
        case "mp4":  return "video/mp4"
        case "mov":  return "video/quicktime"
        case "json": return "application/json"
        case "xml":  return "application/xml"
        case "pdf":  return "application/pdf"
        case "zip":  return "application/zip"
        case "html": return "text/html"
        case "csv":  return "text/csv"
        case "txt", "log": return "text/plain"
        default:     return nil
        }
    }
}
