import Foundation

public enum AllureContext {
    @TaskLocal public static var currentUUID: String?
    @TaskLocal public static var currentStepStack: [String] = []

    public static let threadKey = "io.allure.swift.currentUUID"
    public static let threadStepStackKey = "io.allure.swift.stepStack"

    public static var current: String? {
        if let uuid = currentUUID {
            return uuid
        }
        return Thread.current.threadDictionary[threadKey] as? String
    }

    public static func setThreadCurrent(_ uuid: String?) {
        if let uuid {
            Thread.current.threadDictionary[threadKey] = uuid
        } else {
            Thread.current.threadDictionary.removeObject(forKey: threadKey)
        }
    }

    public static func withCurrent<R>(
        _ uuid: String,
        operation: () throws -> R
    ) rethrows -> R {
        let prior = Thread.current.threadDictionary[threadKey]
        Thread.current.threadDictionary[threadKey] = uuid
        defer {
            if let prior {
                Thread.current.threadDictionary[threadKey] = prior
            } else {
                Thread.current.threadDictionary.removeObject(forKey: threadKey)
            }
        }
        return try operation()
    }

    public static func withCurrentAsync<R: Sendable>(
        _ uuid: String,
        operation: @Sendable () async throws -> R
    ) async rethrows -> R {
        try await $currentUUID.withValue(uuid) {
            try await operation()
        }
    }
}
