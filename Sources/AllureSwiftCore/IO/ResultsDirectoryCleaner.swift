import Foundation

final class ResultsDirectoryCleaner: @unchecked Sendable {
    private let lock = NSLock()
    private var preparedPaths: Set<String> = []
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func prepareForTestRun(_ directory: ResultsDirectory) throws {
        let path = directory.url.standardizedFileURL.path
        lock.lock()
        defer { lock.unlock() }
        guard !preparedPaths.contains(path) else { return }

        if fileManager.fileExists(atPath: directory.url.path) {
            let contents = try fileManager.contentsOfDirectory(
                at: directory.url,
                includingPropertiesForKeys: nil
            )
            for item in contents {
                try fileManager.removeItem(at: item)
            }
        } else {
            try directory.ensureExists()
        }

        preparedPaths.insert(path)
    }
}
