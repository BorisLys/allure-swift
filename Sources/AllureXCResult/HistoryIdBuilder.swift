import Foundation
import AllureSwiftCore

/// Builds a stable `historyId` for a test result.
public enum HistoryIdBuilder {
    /// SHA-256 hex of the test's full name (target/class/method).
    public static func build(fullName: String) -> String {
        AllureHashing.sha256Hex(fullName)
    }
}
