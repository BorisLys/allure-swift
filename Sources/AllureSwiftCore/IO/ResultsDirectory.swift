import Foundation

public enum ResultsDirectoryError: Error, Sendable {
    case createFailed(URL, Error)
}

public struct ResultsDirectory: Sendable, Hashable {
    public static let envVar = "ALLURE_RESULTS_DIR"
    public static let defaultPath = "allure-results"

    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public static func resolve(override: URL? = nil) -> ResultsDirectory {
        if let override {
            return ResultsDirectory(url: override)
        }
        if let env = ProcessInfo.processInfo.environment[envVar], !env.isEmpty {
            let expanded = (env as NSString).expandingTildeInPath
            return ResultsDirectory(url: URL(fileURLWithPath: expanded, isDirectory: true))
        }
        let cwd = FileManager.default.currentDirectoryPath
        let base = URL(fileURLWithPath: cwd, isDirectory: true)
        return ResultsDirectory(url: base.appendingPathComponent(defaultPath, isDirectory: true))
    }

    public func ensureExists() throws {
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            throw ResultsDirectoryError.createFailed(url, error)
        }
    }
}
