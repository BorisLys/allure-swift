import Foundation

public enum Severity: String, Codable, Sendable, Hashable, CaseIterable {
    case blocker
    case critical
    case normal
    case minor
    case trivial
}
