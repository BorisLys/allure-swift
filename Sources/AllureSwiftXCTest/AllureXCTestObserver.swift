import Foundation
import XCTest
import AllureSwiftCore

public final class AllureXCTestObserver: NSObject, XCTestObservation, @unchecked Sendable {
    public static let shared = AllureXCTestObserver()

    private let lock = NSLock()
    private var uuidByTestCase: [ObjectIdentifier: String] = [:]
    private var failuresByTestCase: [ObjectIdentifier: [XCTIssue]] = [:]
    private var registered = false

    public override init() {
        super.init()
    }

    public func register() {
        lock.lock()
        defer { lock.unlock() }
        guard !registered else { return }
        XCTestObservationCenter.shared.addTestObserver(self)
        registered = true
    }

    public func uuid(for testCase: XCTestCase) -> String? {
        lock.lock(); defer { lock.unlock() }
        return uuidByTestCase[ObjectIdentifier(testCase)]
    }

    // MARK: - XCTestObservation

    public func testCaseWillStart(_ testCase: XCTestCase) {
        let uuid = UUID().uuidString.lowercased()
        let className = String(describing: type(of: testCase))
        let selector = testCase.name
        let (parsedClass, parsedMethod) = Self.parseTestName(testCase.name)
        let fullName = "\(parsedClass).\(parsedMethod)"
        let historyId = Self.sha256Hex(fullName)

        var labels: [Label] = [
            Label(.framework, value: "XCTest"),
            Label(.language, value: "swift"),
            Label(.testClass, value: parsedClass.isEmpty ? className : parsedClass),
            Label(.testMethod, value: parsedMethod.isEmpty ? selector : parsedMethod),
            Label(.suite, value: parsedClass.isEmpty ? className : parsedClass),
        ]
        if let host = ProcessInfo.processInfo.hostName.nonEmpty {
            labels.append(Label(.host, value: host))
        }

        let result = TestResult(
            uuid: uuid,
            historyId: historyId,
            fullName: fullName,
            name: parsedMethod.isEmpty ? selector : parsedMethod,
            stage: .running,
            start: Date.allureNow,
            labels: labels
        )
        AllureLifecycle.shared.scheduleTest(result)
        AllureLifecycle.shared.startTest(uuid: uuid)

        lock.lock()
        uuidByTestCase[ObjectIdentifier(testCase)] = uuid
        failuresByTestCase[ObjectIdentifier(testCase)] = []
        lock.unlock()

        AllureContext.setThreadCurrent(uuid)
    }

    public func testCase(_ testCase: XCTestCase, didRecord issue: XCTIssue) {
        lock.lock()
        failuresByTestCase[ObjectIdentifier(testCase), default: []].append(issue)
        lock.unlock()
    }

    public func testCaseDidFinish(_ testCase: XCTestCase) {
        let key = ObjectIdentifier(testCase)
        lock.lock()
        let uuid = uuidByTestCase.removeValue(forKey: key)
        let issues = failuresByTestCase.removeValue(forKey: key) ?? []
        lock.unlock()
        guard let uuid else { return }

        let (status, details) = Self.deriveStatus(from: issues, testCase: testCase)
        AllureLifecycle.shared.stopTest(uuid: uuid, status: status, details: details)
        AllureContext.setThreadCurrent(nil)
    }

    // MARK: - Helpers

    static func parseTestName(_ raw: String) -> (className: String, method: String) {
        let trimmed = raw.trimmingCharacters(in: CharacterSet(charactersIn: "-[] "))
        let parts = trimmed.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        if parts.count == 2 {
            return (String(parts[0]), String(parts[1]))
        }
        return ("", trimmed)
    }

    static func deriveStatus(from issues: [XCTIssue], testCase: XCTestCase) -> (Status, StatusDetails?) {
        if issues.isEmpty {
            return (.passed, nil)
        }
        var hasBroken = false
        var hasFailed = false
        var messages: [String] = []
        var traces: [String] = []
        for issue in issues {
            switch issue.type {
            case .assertionFailure, .unmatchedExpectedFailure:
                hasFailed = true
            case .thrownError, .uncaughtException, .system:
                hasBroken = true
            case .performanceRegression:
                hasFailed = true
            @unknown default:
                hasBroken = true
            }
            messages.append(issue.compactDescription)
            if let trace = issue.detailedDescription {
                traces.append(trace)
            }
        }
        let status: Status = hasBroken && !hasFailed ? .broken : .failed
        let details = StatusDetails(
            message: messages.joined(separator: "\n").nonEmpty,
            trace: traces.joined(separator: "\n").nonEmpty
        )
        return (status, details)
    }

    static func sha256Hex(_ value: String) -> String {
        AllureHashing.sha256Hex(value)
    }
}

private extension Optional where Wrapped == String {
    var nonEmpty: String? {
        guard let v = self, !v.isEmpty else { return nil }
        return v
    }
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
