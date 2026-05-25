import Foundation
import AllureSwiftCore

/// Writes Allure JSON result/container files into the output directory.
public struct ResultsWriter {
    public let outputDir: URL
    public let encoder: JSONEncoder
    private let fileManager: FileManager

    public init(outputDir: URL, fileManager: FileManager = .default) {
        self.outputDir = outputDir
        self.encoder = JSONEncoderFactory.make()
        self.fileManager = fileManager
    }

    public func ensureDirectory() throws {
        try fileManager.createDirectory(at: outputDir, withIntermediateDirectories: true)
    }

    public func cleanDirectory() throws {
        if fileManager.fileExists(atPath: outputDir.path) {
            try fileManager.removeItem(at: outputDir)
        }
        try fileManager.createDirectory(at: outputDir, withIntermediateDirectories: true)
    }

    public func write(testResult: TestResult) throws {
        let url = outputDir.appendingPathComponent("\(testResult.uuid)-result.json")
        try encoder.encode(testResult).write(to: url, options: .atomic)
    }

    public func write(container: TestResultContainer) throws {
        let url = outputDir.appendingPathComponent("\(container.uuid)-container.json")
        try encoder.encode(container).write(to: url, options: .atomic)
    }

    public func writeEnvironmentProperties(_ entries: [(String, String)]) throws {
        guard !entries.isEmpty else { return }
        let text = entries.map { "\($0.0)=\($0.1)" }.joined(separator: "\n") + "\n"
        let url = outputDir.appendingPathComponent("environment.properties")
        try Data(text.utf8).write(to: url, options: .atomic)
    }

    public func write(executor: ExecutorInfo) throws {
        let url = outputDir.appendingPathComponent("executor.json")
        try encoder.encode(executor).write(to: url, options: .atomic)
    }
}
