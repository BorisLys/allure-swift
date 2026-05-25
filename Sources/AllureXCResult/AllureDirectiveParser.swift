import Foundation
import AllureSwiftCore
import XCResultParser

/// Extracts Allure metadata directives from xcresult activity titles.
///
/// When tests use `AllureSwiftXCTest` helpers, calls like `allureId(1234)` write
/// a hidden XCTActivity titled `"allure.id:1234"` into the xcresult bundle.
/// This parser walks the activity tree, recognises those directives, and
/// converts them to typed `Label` / `Link` values and optional overrides.
///
/// Recognised formats (all case-sensitive, no surrounding whitespace):
///
/// ```
/// allure.id:<value>                   → allureId label
/// allure.name:<value>                 → test name override
/// allure.description:<value>          → test description
/// allure.label.<name>:<value>         → arbitrary label
/// allure.link.<name>[<type>]:<url>    → link with optional type
/// allure.link.<name>:<url>            → link without type
/// ```
public enum AllureDirectiveParser {

    // MARK: - Result type

    public struct Directives: Sendable {
        public var nameOverride: String?
        public var description: String?
        public var labels: [Label] = []
        public var links: [Link] = []

        public init() {}
    }

    // MARK: - Public API

    /// Returns `true` when `title` is an Allure directive marker.
    /// Use this to filter directive activities out of the step list.
    public static func isDirective(_ title: String) -> Bool {
        title.hasPrefix("allure.")
    }

    /// Walks `activities` (recursively) and returns aggregated directives.
    public static func parse(activities: [Activity]) -> Directives {
        var result = Directives()
        collect(activities, into: &result)
        return result
    }

    // MARK: - Private

    private static func collect(_ activities: [Activity], into result: inout Directives) {
        for activity in activities {
            apply(title: activity.title, to: &result)
            collect(activity.childActivities ?? [], into: &result)
        }
    }

    private static func apply(title: String, to d: inout Directives) {
        if let id = value(after: "allure.id:", in: title) {
            d.labels.append(Label(.allureId, value: id))
        } else if let name = value(after: "allure.name:", in: title) {
            if d.nameOverride == nil { d.nameOverride = name }
        } else if let desc = value(after: "allure.description:", in: title) {
            if d.description == nil { d.description = desc }
        } else if let rest = value(after: "allure.label.", in: title) {
            if let label = parseLabel(rest) { d.labels.append(label) }
        } else if let rest = value(after: "allure.link.", in: title) {
            if let link = parseLink(rest) { d.links.append(link) }
        }
    }

    /// Parses `"<labelName>:<value>"`.
    private static func parseLabel(_ rest: String) -> Label? {
        guard let colon = rest.firstIndex(of: ":") else { return nil }
        let name = String(rest[..<colon])
        let value = String(rest[rest.index(after: colon)...])
        guard !name.isEmpty, !value.isEmpty else { return nil }
        return Label(name: name, value: value)
    }

    /// Parses `"<name>[<type>]:<url>"` or `"<name>:<url>"`.
    private static func parseLink(_ rest: String) -> Link? {
        var linkName: String
        var linkType: String?
        var url: String

        if let openBracket = rest.firstIndex(of: "["),
           let closeBracket = rest[openBracket...].firstIndex(of: "]") {
            linkName = String(rest[..<openBracket])
            linkType = String(rest[rest.index(after: openBracket)..<closeBracket])
            let afterBracket = rest.index(after: closeBracket)
            guard afterBracket < rest.endIndex, rest[afterBracket] == ":" else { return nil }
            url = String(rest[rest.index(after: afterBracket)...])
        } else if let colon = rest.firstIndex(of: ":") {
            linkName = String(rest[..<colon])
            url = String(rest[rest.index(after: colon)...])
        } else {
            return nil
        }

        guard !url.isEmpty else { return nil }
        return Link(
            name: linkName.isEmpty ? nil : linkName,
            url: url,
            type: linkType
        )
    }

    private static func value(after prefix: String, in string: String) -> String? {
        guard string.hasPrefix(prefix) else { return nil }
        let v = String(string.dropFirst(prefix.count))
        return v.isEmpty ? nil : v
    }
}
