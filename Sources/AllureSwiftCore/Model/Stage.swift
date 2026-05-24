import Foundation

public enum Stage: String, Codable, Sendable, Hashable, CaseIterable {
    case scheduled
    case running
    case finished
    case pending
    case interrupted
}
