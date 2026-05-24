import Foundation
import XCTest
import AllureSwiftCore

public enum AllureXCTest {
    /// Register the Allure XCTest observer with `XCTestObservationCenter`.
    /// Idempotent — safe to call multiple times.
    public static func bootstrap() {
        AllureXCTestObserver.shared.register()
    }
}
