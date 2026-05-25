import Foundation
import AllureSwiftCore
import XCResultParser

/// Options controlling a conversion run.
public struct ConverterOptions: Sendable {
    public var includeAttachments: Bool
    public var cleanOutputDirectory: Bool
    public var verbose: Bool

    public init(
        includeAttachments: Bool = true,
        cleanOutputDirectory: Bool = false,
        verbose: Bool = false
    ) {
        self.includeAttachments = includeAttachments
        self.cleanOutputDirectory = cleanOutputDirectory
        self.verbose = verbose
    }
}

/// Outcome of a conversion.
public struct ConversionResult: Sendable {
    public let testsConverted: Int
    public let attachmentsCopied: Int
    public let outputDirectory: URL
}

/// Orchestrates a full `.xcresult` → Allure JSON conversion.
public struct Converter {
    public let bundle: XCResultBundle
    public let outputDir: URL
    public let options: ConverterOptions

    public init(
        bundleURL: URL,
        outputDir: URL,
        options: ConverterOptions = ConverterOptions(),
        tool: XCResultTool = XCResultTool()
    ) throws {
        self.bundle = try XCResultBundle(url: bundleURL, tool: tool)
        self.outputDir = outputDir
        self.options = options
    }

    @discardableResult
    public func run(log: ((String) -> Void)? = nil) throws -> ConversionResult {
        let writer = ResultsWriter(outputDir: outputDir)
        if options.cleanOutputDirectory {
            try writer.cleanDirectory()
        } else {
            try writer.ensureDirectory()
        }

        let summary = try bundle.summary()
        let tree = try bundle.tests()

        let attachmentsIndex: AttachmentIndex?
        let attachmentMapper: AttachmentMapper?
        var attachmentsCopied = 0

        if options.includeAttachments {
            let exportDir = outputDir.appendingPathComponent("__xcresult-attachments", isDirectory: true)
            try? FileManager.default.removeItem(at: exportDir)
            attachmentsIndex = try bundle.exportAttachments(to: exportDir)
            attachmentMapper = AttachmentMapper(outputDir: outputDir)
            log?("Exported \(attachmentsIndex?.entries.count ?? 0) attachment groups to \(exportDir.path)")
        } else {
            attachmentsIndex = nil
            attachmentMapper = nil
        }

        let bundleName = inferBundleName(tree: tree)
        let context = TestMapper.Context(summary: summary, bundleName: bundleName)

        var testCount = 0
        for testNode in tree.allTestCases() {
            guard let testURL = testNode.nodeIdentifierURL else { continue }

            // Pull richer information per test.
            let details = try? bundle.details(forTestURL: testURL)
            let activities = try? bundle.activities(forTestURL: testURL)

            var result = TestMapper.map(node: testNode, details: details, context: context)
            if let activities {
                result.steps = ActivityMapper.map(activities: activities)
            }
            if let index = attachmentsIndex, let mapper = attachmentMapper,
               let entry = index.entry(forTestURL: testURL, testId: testNode.nodeIdentifier) {
                let mapped = mapper.map(entry.attachments, index: index)
                result.attachments.append(contentsOf: mapped)
                attachmentsCopied += mapped.count
            }

            try writer.write(testResult: result)
            testCount += 1
            log?("Wrote \(result.uuid)-result.json for \(result.name) [\(result.status?.rawValue ?? "?")]")
        }

        try writeEnvironmentProperties(summary: summary, writer: writer)

        if let index = attachmentsIndex {
            try? FileManager.default.removeItem(at: index.exportDir)
        }

        return ConversionResult(
            testsConverted: testCount,
            attachmentsCopied: attachmentsCopied,
            outputDirectory: outputDir
        )
    }

    // MARK: - Helpers

    private func writeEnvironmentProperties(summary: TestSummary, writer: ResultsWriter) throws {
        var entries: [(String, String)] = []
        if let desc = summary.environmentDescription, !desc.isEmpty {
            entries.append(("environment", desc))
        }
        if let first = summary.devicesAndConfigurations?.first {
            let dev = first.device
            if let name = dev.deviceName, !name.isEmpty { entries.append(("device.name", name)) }
            if let model = dev.modelName, !model.isEmpty { entries.append(("device.model", model)) }
            if let platform = dev.platform, !platform.isEmpty { entries.append(("device.platform", platform)) }
            if let os = dev.osVersion, !os.isEmpty { entries.append(("os.version", os)) }
            if let build = dev.osBuildNumber, !build.isEmpty { entries.append(("os.build", build)) }
            if let arch = dev.architecture, !arch.isEmpty { entries.append(("device.architecture", arch)) }
        }
        try writer.writeEnvironmentProperties(entries)
    }

    private func inferBundleName(tree: TestsTree) -> String? {
        // The `Unit test bundle` node is the second level in the tree.
        for plan in tree.testNodes {
            for bundleNode in plan.children ?? [] where bundleNode.nodeType == "Unit test bundle" || bundleNode.nodeType == "UI test bundle" {
                return bundleNode.name
            }
        }
        return tree.testNodes.first?.name
    }
}
