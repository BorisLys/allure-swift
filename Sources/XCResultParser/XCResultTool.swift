import Foundation

/// Errors raised by `XCResultTool`.
public enum XCResultToolError: Error, CustomStringConvertible {
    case toolNotFound
    case processFailed(exitCode: Int32, stderr: String)
    case decodeFailed(Error)
    case bundleMissing(URL)

    public var description: String {
        switch self {
        case .toolNotFound:
            return "xcrun xcresulttool is not available on this machine. Make sure Xcode (or Command Line Tools) is installed."
        case .processFailed(let code, let stderr):
            return "xcresulttool exited with code \(code): \(stderr)"
        case .decodeFailed(let err):
            return "Failed to decode xcresulttool output: \(err)"
        case .bundleMissing(let url):
            return "xcresult bundle does not exist at: \(url.path)"
        }
    }
}

/// Thin Process wrapper around `xcrun xcresulttool`.
///
/// All methods are synchronous and return raw stdout bytes; the caller
/// decodes JSON via `decode(...)` or runs export-style commands that
/// produce side-effects on disk.
public struct XCResultTool: Sendable {
    public let executable: String

    public init(executable: String = "/usr/bin/xcrun") {
        self.executable = executable
    }

    // MARK: - High-level wrappers

    public func getTests(bundle: URL) throws -> TestsTree {
        let data = try run([
            "xcresulttool", "get", "test-results", "tests",
            "--path", bundle.path,
            "--format", "json",
        ])
        return try Self.decode(TestsTree.self, from: data)
    }

    public func getSummary(bundle: URL) throws -> TestSummary {
        let data = try run([
            "xcresulttool", "get", "test-results", "summary",
            "--path", bundle.path,
            "--format", "json",
        ])
        return try Self.decode(TestSummary.self, from: data)
    }

    public func getTestDetails(bundle: URL, testIdURL: String) throws -> TestDetails {
        let data = try run([
            "xcresulttool", "get", "test-results", "test-details",
            "--path", bundle.path,
            "--test-id", testIdURL,
            "--format", "json",
        ])
        return try Self.decode(TestDetails.self, from: data)
    }

    public func getActivities(bundle: URL, testIdURL: String) throws -> TestActivities {
        let data = try run([
            "xcresulttool", "get", "test-results", "activities",
            "--path", bundle.path,
            "--test-id", testIdURL,
            "--format", "json",
        ])
        return try Self.decode(TestActivities.self, from: data)
    }

    /// Exports every attachment in the bundle into `outputDir`. Returns the
    /// parsed `manifest.json` content.
    public func exportAttachments(bundle: URL, outputDir: URL) throws -> AttachmentManifest {
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        _ = try run([
            "xcresulttool", "export", "attachments",
            "--path", bundle.path,
            "--output-path", outputDir.path,
        ])
        let manifestURL = outputDir.appendingPathComponent("manifest.json")
        guard FileManager.default.fileExists(atPath: manifestURL.path) else { return [] }
        let data = try Data(contentsOf: manifestURL)
        return try Self.decode(AttachmentManifest.self, from: data)
    }

    // MARK: - Process plumbing

    @discardableResult
    public func run(_ arguments: [String]) throws -> Data {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: executable)
        proc.arguments = arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        proc.standardOutput = stdoutPipe
        proc.standardError = stderrPipe

        do {
            try proc.run()
        } catch {
            throw XCResultToolError.toolNotFound
        }
        proc.waitUntilExit()

        let stdout = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        if proc.terminationStatus != 0 {
            let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw XCResultToolError.processFailed(exitCode: proc.terminationStatus, stderr: stderr)
        }
        return stdout
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw XCResultToolError.decodeFailed(error)
        }
    }
}
