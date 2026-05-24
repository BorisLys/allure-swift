import Foundation

public final class FileWriter: @unchecked Sendable {
    public enum WriteError: Error, Sendable {
        case encodeFailed(Error)
        case writeFailed(URL, Error)
    }

    private let directory: ResultsDirectory
    private let encoder: JSONEncoder
    private let queue: DispatchQueue
    private let fileManager = FileManager.default

    public init(directory: ResultsDirectory, encoder: JSONEncoder = JSONEncoderFactory.make()) {
        self.directory = directory
        self.encoder = encoder
        self.queue = DispatchQueue(label: "io.allure.swift.filewriter", qos: .utility)
    }

    public var directoryURL: URL { directory.url }

    public func write(testResult: TestResult) throws {
        try ensureDirectory()
        let url = directory.url.appendingPathComponent("\(testResult.uuid)-result.json", isDirectory: false)
        try writeJSON(testResult, to: url)
    }

    public func write(container: TestResultContainer) throws {
        try ensureDirectory()
        let url = directory.url.appendingPathComponent("\(container.uuid)-container.json", isDirectory: false)
        try writeJSON(container, to: url)
    }

    public func write(attachmentData: Data, source: String) throws {
        try ensureDirectory()
        let url = directory.url.appendingPathComponent(source, isDirectory: false)
        do {
            try attachmentData.write(to: url, options: .atomic)
        } catch {
            throw WriteError.writeFailed(url, error)
        }
    }

    public func writeEnvironment(_ env: EnvironmentInfo) throws {
        try ensureDirectory()
        let url = directory.url.appendingPathComponent("environment.properties", isDirectory: false)
        let data = Data(env.render().utf8)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw WriteError.writeFailed(url, error)
        }
    }

    public func writeExecutor(_ executor: ExecutorInfo) throws {
        try ensureDirectory()
        let url = directory.url.appendingPathComponent("executor.json", isDirectory: false)
        try writeJSON(executor, to: url)
    }

    public func writeCategories(_ categories: [Category]) throws {
        try ensureDirectory()
        let url = directory.url.appendingPathComponent("categories.json", isDirectory: false)
        try writeJSON(categories, to: url)
    }

    public func writeAsync<T: Sendable>(_ work: @escaping @Sendable (FileWriter) -> T) {
        queue.async { _ = work(self) }
    }

    public func flush() {
        queue.sync { }
    }

    private func ensureDirectory() throws {
        if !fileManager.fileExists(atPath: directory.url.path) {
            try directory.ensureExists()
        }
    }

    private func writeJSON<T: Encodable>(_ value: T, to url: URL) throws {
        let data: Data
        do {
            data = try encoder.encode(value)
        } catch {
            throw WriteError.encodeFailed(error)
        }
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw WriteError.writeFailed(url, error)
        }
    }
}
