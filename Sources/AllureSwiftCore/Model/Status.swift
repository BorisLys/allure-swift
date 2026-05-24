import Foundation

public enum Status: String, Codable, Sendable, Hashable, CaseIterable {
    case passed
    case failed
    case broken
    case skipped
}
