import Foundation
import AllureSwiftCore
import XCResultParser

/// Extracts Allure metadata from test naming conventions.
///
/// Two notations are recognised so the same converter handles both
/// frameworks:
///
/// **Dashed** — values prefixed with a known label and separated by `-` or
/// `=`. Suitable for Swift Testing `@Test("…")` display names and
/// `@Tag` values, both of which accept arbitrary characters.
///
/// ```
/// @Test("Happy path Epic-Cart Severity-critical AllureID-1234")
/// ```
///
/// **CamelCase** — values appended directly to the prefix without any
/// separator, used inside XCTest function names (Swift identifiers cannot
/// contain `-`). Tokens are separated by `_`.
///
/// ```swift
/// func testHappyPath_EpicCart_SeverityCritical_AllureID1234() { … }
/// ```
///
/// Recognised prefixes (case-insensitive): `AllureID`, `Epic`, `Feature`,
/// `Story`, `Severity`, `Owner`, `Tag`, `Layer`, `Lead`, `Framework`,
/// `Language`, `Package`, `Suite`, `ParentSuite`, `SubSuite`, `Host`,
/// `Thread`. Anything not matching a known prefix is ignored.
public enum LabelExtractor {
    /// Recognised label prefix (lowercased) → Allure `LabelName`. Ordered
    /// from longest to shortest so `parentsuite` wins over `suite`.
    private static let prefixMap: [(prefix: String, label: LabelName)] = [
        ("parentsuite", .parentSuite),
        ("subsuite",    .subSuite),
        ("allureid",    .allureId),
        ("framework",   .framework),
        ("language",    .language),
        ("severity",    .severity),
        ("feature",     .feature),
        ("package",     .package),
        ("thread",      .thread),
        ("layer",       .layer),
        ("owner",       .owner),
        ("story",       .story),
        ("suite",       .suite),
        ("epic",        .epic),
        ("host",        .host),
        ("lead",        .lead),
        ("tag",         .tag),
    ]

    /// Extracts labels from the test name and the (optional) tag list.
    public static func extract(testName: String, tags: [String]? = nil) -> [Label] {
        var labels: [Label] = []
        labels.append(contentsOf: parseTokens(in: testName))
        for tag in tags ?? [] {
            labels.append(contentsOf: parseTokens(in: tag))
        }
        return deduplicate(labels)
    }

    /// Splits a string on `_`, ` `, `,`, `;`, `/`, `(`, `)` and tries each
    /// chunk against both notations.
    private static func parseTokens(in source: String) -> [Label] {
        let separators = CharacterSet(charactersIn: "_ ,;/()")
        let tokens = source.components(separatedBy: separators)
        var out: [Label] = []
        for token in tokens where !token.isEmpty {
            if let label = parseDashed(token) {
                out.append(label)
            } else if let label = parseCamelCase(token) {
                out.append(label)
            }
        }
        return out
    }

    /// Tries the dashed/equals form: `prefix-value` or `prefix=value`.
    private static func parseDashed(_ token: String) -> Label? {
        let dash = token.firstIndex(of: "-")
        let eq = token.firstIndex(of: "=")
        let separator: String.Index?
        if let dash, let eq { separator = dash < eq ? dash : eq }
        else { separator = dash ?? eq }

        guard let sep = separator else { return nil }
        let prefix = String(token[..<sep]).lowercased()
        let value = String(token[token.index(after: sep)...])
        guard !value.isEmpty else { return nil }

        guard let match = prefixMap.first(where: { $0.prefix == prefix }) else { return nil }
        return Label(match.label, value: value)
    }

    /// Tries the camelCase form: `PrefixValue` where Prefix is a recognised
    /// keyword and Value is everything that follows.
    ///
    /// Matched greedily — `AllureID1234` resolves to `AllureID` (the longer
    /// prefix wins because `prefixMap` is ordered by length).
    private static func parseCamelCase(_ token: String) -> Label? {
        let lower = token.lowercased()
        for entry in prefixMap {
            guard lower.hasPrefix(entry.prefix) else { continue }
            let value = String(token.dropFirst(entry.prefix.count))
            guard !value.isEmpty else { continue }
            return Label(entry.label, value: value)
        }
        return nil
    }

    /// Returns `labels` with duplicates collapsed in insertion order.
    private static func deduplicate(_ labels: [Label]) -> [Label] {
        var seen = Set<Label>()
        var out: [Label] = []
        for l in labels where !seen.contains(l) {
            seen.insert(l)
            out.append(l)
        }
        return out
    }
}
