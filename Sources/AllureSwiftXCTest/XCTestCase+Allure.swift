@preconcurrency import XCTest

// MARK: - Severity

/// Test severity level used in Allure reports.
public enum Severity: String, Sendable {
    case blocker
    case critical
    case normal
    case minor
    case trivial
}

/// XCTestCase helpers that embed Allure metadata as XCTActivity entries.
///
/// Each method writes a hidden activity whose title is an `allure.*` directive.
/// The `allure-xcresult convert` step reads these directives from the xcresult
/// bundle and maps them to Allure labels, links, name overrides, and descriptions.
///
/// Usage — add calls at the top of each test method:
///
/// ```swift
/// func testCheckout() throws {
///     allureId(1234)
///     allureEpic("Cart")
///     allureFeature("Checkout")
///     allureSeverity(.critical)
///     allureOwner("b.lysikov")
///
///     try allureStep("Open cart") {
///         // …
///     }
/// }
/// ```
extension XCTestCase {

    // MARK: - Identity

    /// Sets the Allure test ID (links the test to a management system entry).
    @nonobjc public func allureId(_ id: Int) {
        writeDirective("allure.id:\(id)")
    }

    /// Sets the Allure test ID from a string value.
    @nonobjc public func allureId(_ id: String) {
        writeDirective("allure.id:\(id)")
    }

    /// Overrides the test name shown in the Allure report.
    @nonobjc public func allureName(_ name: String) {
        writeDirective("allure.name:\(name)")
    }

    /// Sets the test description shown in the Allure report.
    @nonobjc public func allureDescription(_ text: String) {
        writeDirective("allure.description:\(text)")
    }

    // MARK: - Labels

    /// Attaches an arbitrary Allure label.
    @nonobjc public func allureLabel(_ name: String, value: String) {
        writeDirective("allure.label.\(name):\(value)")
    }

    /// Sets test severity. Uses `Severity` from `AllureSwiftCore`.
    @nonobjc public func allureSeverity(_ level: Severity) {
        writeDirective("allure.label.severity:\(level.rawValue)")
    }

    @nonobjc public func allureEpic(_ value: String) {
        writeDirective("allure.label.epic:\(value)")
    }

    @nonobjc public func allureFeature(_ value: String) {
        writeDirective("allure.label.feature:\(value)")
    }

    @nonobjc public func allureStory(_ value: String) {
        writeDirective("allure.label.story:\(value)")
    }

    @nonobjc public func allureOwner(_ value: String) {
        writeDirective("allure.label.owner:\(value)")
    }

    @nonobjc public func allureTag(_ value: String) {
        writeDirective("allure.label.tag:\(value)")
    }

    @nonobjc public func allureLayer(_ value: String) {
        writeDirective("allure.label.layer:\(value)")
    }

    @nonobjc public func allureSuite(_ value: String) {
        writeDirective("allure.label.suite:\(value)")
    }

    @nonobjc public func allureParentSuite(_ value: String) {
        writeDirective("allure.label.parentSuite:\(value)")
    }

    @nonobjc public func allureSubSuite(_ value: String) {
        writeDirective("allure.label.subSuite:\(value)")
    }

    // MARK: - Links

    /// Attaches a generic link.
    @nonobjc public func allureLink(name: String? = nil, url: String, type: String? = nil) {
        let linkName = name ?? url
        if let type {
            writeDirective("allure.link.\(linkName)[\(type)]:\(url)")
        } else {
            writeDirective("allure.link.\(linkName):\(url)")
        }
    }

    /// Attaches an issue tracker link.
    @nonobjc public func allureIssue(name: String? = nil, url: String) {
        allureLink(name: name ?? url, url: url, type: "issue")
    }

    /// Attaches a TMS (test management system) link.
    @nonobjc public func allureTms(name: String? = nil, url: String) {
        allureLink(name: name ?? url, url: url, type: "tms")
    }

    // MARK: - Steps

    /// Wraps `block` in an Allure step. The step appears in the report with the
    /// given name and inherits the pass/fail status of the block.
    @nonobjc @discardableResult
    public func allureStep<T>(_ name: String, _ block: () throws -> T) rethrows -> T {
        try XCTContext.runActivity(named: name) { _ in try block() }
    }

    // MARK: - Attachments

    /// Adds a binary attachment to the current test.
    @nonobjc public func allureAttachment(name: String, data: Data, type: String) {
        XCTContext.runActivity(named: name) { activity in
            let att = XCTAttachment(data: data, uniformTypeIdentifier: type)
            att.name = name
            att.lifetime = .keepAlways
            activity.add(att)
        }
    }

    /// Adds a plain-text attachment to the current test.
    @nonobjc public func allureAttachment(name: String, string: String, type: String = "text/plain") {
        guard let data = string.data(using: .utf8) else { return }
        allureAttachment(name: name, data: data, type: type)
    }

    // MARK: - Private

    private func writeDirective(_ directive: String) {
        XCTContext.runActivity(named: directive) { _ in }
    }
}
