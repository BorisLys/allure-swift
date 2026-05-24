import Foundation
import XCTest
import AllureSwiftCore

/// Optional base class that wires the current Allure test UUID into the
/// thread-local context on the same thread that executes the test body.
/// Subclassing is not required — tests can also call `Allure.bind(self)`
/// in their own `setUp()` if they cannot change base class.
open class AllureTestCase: XCTestCase {

    open override class func setUp() {
        super.setUp()
        AllureXCTest.bootstrap()
    }

    open override func setUp() {
        super.setUp()
        bindAllure()
    }

    open override func tearDown() {
        AllureContext.setThreadCurrent(nil)
        super.tearDown()
    }

    public func bindAllure() {
        if let uuid = AllureXCTestObserver.shared.uuid(for: self) {
            AllureContext.setThreadCurrent(uuid)
        }
    }
}

extension Allure {
    /// Bind the current thread to the Allure UUID associated with this XCTestCase.
    /// Call from your `setUp()` if you cannot subclass `AllureTestCase`.
    public static func bind(_ testCase: XCTestCase) {
        AllureXCTest.bootstrap()
        if let uuid = AllureXCTestObserver.shared.uuid(for: testCase) {
            AllureContext.setThreadCurrent(uuid)
        }
    }

    /// Clear the thread-local UUID. Call from your `tearDown()`.
    public static func unbind() {
        AllureContext.setThreadCurrent(nil)
    }
}
