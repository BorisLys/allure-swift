import Foundation
import AllureSwiftCore
import XCResultParser

/// Extracts Allure metadata from test naming conventions.
///
/// Supported patterns (case-insensitive) embedded in the test method name
/// or in Swift Testing `@Tag` values:
///
/// - `AllureID-1234`            → label `AS_ID = 1234`
/// - `Epic-Cart`                → label `epic = Cart`
/// - `Feature-Checkout`         → label `feature = Checkout`
/// - `Story-EmptyState`         → label `story = EmptyState`
/// - `Severity-critical`        → label `severity = critical`
/// - `Owner-bLysikov`           → label `owner = bLysikov`
/// - `Tag-smoke`                → label `tag = smoke`
/// - `Layer-unit`               → label `layer = unit`
///
/// Anything not matching a known prefix is ignored.
public enum LabelExtractor {
    /// Recognised label prefix → Allure `LabelName`.
    private static let prefixMap: [(prefix: String, label: LabelName)] = [
        ("allureid",    .allureId),
        ("allure-id",   .allureId),
        ("epic",        .epic),
        ("feature",     .feature),
        ("story",       .story),
        ("severity",    .severity),
        ("owner",       .owner),
        ("tag",         .tag),
        ("layer",       .layer),
        ("lead",        .lead),
        ("framework",   .framework),
        ("language",    .language),
        ("package",     .package),
        ("suite",       .suite),
        ("parentsuite", .parentSuite),
        ("subsuite",    .subSuite),
        ("host",        .host),
        ("thread",      .thread),
    ]

    /// Extracts labels from the test name and the (optional) tag list.
    public static func extract(testName: String, tags: [String]? = nil) -> [Label] {
        var labels: [Label] = []
        labels.append(contentsOf: parseTokens(in: testName))
        for tag in tags ?? [] {
            labels.append(contentsOf: parseTokens(in: tag))
        }
        return labels
    }

    /// Splits a string on `_`, ` `, `,`, `;`, `/` and tries to match each
    /// chunk against the known prefixes. Each chunk has the form
    /// `<prefix>-<value>` (or `<prefix>=<value>`).
    private static func parseTokens(in source: String) -> [Label] {
        let separators = CharacterSet(charactersIn: "_ ,;/")
        let tokens = source.components(separatedBy: separators)
        var out: [Label] = []
        for token in tokens {
            guard let label = parseToken(token) else { continue }
            out.append(label)
        }
        return out
    }

    private static func parseToken(_ token: String) -> Label? {
        // Split on either '-' or '='.
        let dash = token.firstIndex(of: "-")
        let eq = token.firstIndex(of: "=")
        let separator: String.Index?
        if let dash, let eq { separator = dash < eq ? dash : eq }
        else { separator = dash ?? eq }

        guard let sep = separator else { return nil }
        let prefix = token[..<sep].lowercased()
        let value = String(token[token.index(after: sep)...])
        guard !value.isEmpty else { return nil }

        guard let match = prefixMap.first(where: { $0.prefix == prefix }) else { return nil }
        return Label(match.label, value: value)
    }
}
