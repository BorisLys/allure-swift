import Foundation
import AllureSwiftCore
import XCResultParser

/// Maps a single xcresult `TestNode` (with optional details) into an Allure
/// `TestResult`. Steps and attachments are wired in by the orchestrator.
public enum TestMapper {
    public struct Context {
        public let summary: TestSummary
        public let bundleName: String?

        public init(summary: TestSummary, bundleName: String? = nil) {
            self.summary = summary
            self.bundleName = bundleName
        }
    }

    public static func map(
        node: TestNode,
        details: TestDetails?,
        context: Context,
        directives: AllureDirectiveParser.Directives = .init()
    ) -> TestResult {
        let testName = node.name
        let bundleName = context.bundleName ?? ""
        let identifier = node.nodeIdentifier ?? details?.testIdentifier ?? testName
        let className = Self.parentClass(from: identifier)
        let methodName = Self.methodName(from: identifier) ?? testName
        let fullName = bundleName.isEmpty
            ? "\(className).\(methodName)"
            : "\(bundleName).\(className).\(methodName)"

        let status = StatusMapper.map(node.result)
        let statusDetails = Self.statusDetails(from: node, status: status)

        let durationSec = node.durationInSeconds ?? details?.durationInSeconds ?? 0
        let start = (context.summary.startTime ?? 0)
        let stop = start + durationSec
        let startMillis = Int64((start * 1000).rounded())
        let stopMillis = Int64((stop * 1000).rounded())

        // Name-convention labels come first so directive labels can override them.
        var labels = LabelExtractor.extract(testName: methodName, tags: node.tags)
        labels.append(Label(.testClass, value: className))
        labels.append(Label(.testMethod, value: methodName))
        labels.append(Label(.framework, value: "XCTest"))
        labels.append(Label(.language, value: "swift"))
        if !bundleName.isEmpty {
            labels.append(Label(.package, value: bundleName))
        }
        if let host = ProcessInfo.processInfo.hostName as String? {
            labels.append(Label(.host, value: host))
        }
        // Directive labels (from allure.* activities) appended last — dedup happens at report level.
        labels.append(contentsOf: directives.labels)

        let displayName = directives.nameOverride ?? methodName

        let uuid = UUID().uuidString.lowercased()
        return TestResult(
            uuid: uuid,
            historyId: HistoryIdBuilder.build(fullName: fullName),
            fullName: fullName,
            name: displayName,
            description: directives.description,
            status: status,
            statusDetails: statusDetails,
            stage: .finished,
            start: startMillis,
            stop: stopMillis,
            labels: labels,
            links: directives.links
        )
    }

    /// Walks the tree looking for `Failure Message` nodes and concatenates
    /// their `name` fields (xcresult stores the assertion text in `name`).
    public static func statusDetails(from node: TestNode, status: Status) -> StatusDetails? {
        let messages = collectFailureMessages(node)
        let expected = StatusMapper.isExpectedFailure(node.result)
        guard !messages.isEmpty || expected else { return nil }
        return StatusDetails(
            known: expected ? true : nil,
            message: messages.isEmpty ? nil : messages.joined(separator: "\n"),
            trace: nil
        )
    }

    private static func collectFailureMessages(_ node: TestNode) -> [String] {
        var out: [String] = []
        if node.nodeType == "Failure Message" {
            out.append(node.name)
        }
        for c in node.children ?? [] {
            out.append(contentsOf: collectFailureMessages(c))
        }
        return out
    }

    private static func parentClass(from identifier: String) -> String {
        // `SwiftRadioTests/example()` → `SwiftRadioTests`
        let parts = identifier.split(separator: "/")
        guard parts.count >= 2 else { return "" }
        return String(parts.dropLast().joined(separator: "/"))
    }

    private static func methodName(from identifier: String) -> String? {
        identifier.split(separator: "/").last.map(String.init)
    }
}
