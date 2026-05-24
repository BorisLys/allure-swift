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
        let env = ProcessInfo.processInfo.environment
        if let explicit = env[envVar], !explicit.isEmpty {
            let expanded = (explicit as NSString).expandingTildeInPath
            return ResultsDirectory(url: URL(fileURLWithPath: expanded, isDirectory: true))
        }
        // Xcode build settings visible in the test process (macOS unit tests / mac-designed targets)
        for key in ["SOURCE_ROOT", "SRCROOT", "PROJECT_DIR"] {
            if let root = env[key], !root.isEmpty {
                return ResultsDirectory(url: URL(fileURLWithPath: root, isDirectory: true)
                    .appendingPathComponent(defaultPath, isDirectory: true))
            }
        }
        // iOS Simulator injects SIMULATOR_HOST_HOME → use the Mac home dir
        if let simHome = env["SIMULATOR_HOST_HOME"], !simHome.isEmpty {
            return ResultsDirectory(url: URL(fileURLWithPath: simHome, isDirectory: true)
                .appendingPathComponent(defaultPath, isDirectory: true))
        }
        // Generic fallback: /tmp/allure-results (always writable)
        return ResultsDirectory(url: URL(fileURLWithPath: "/tmp/\(defaultPath)", isDirectory: true))
    }

    public func ensureExists() throws {
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            throw ResultsDirectoryError.createFailed(url, error)
        }
    }
}
