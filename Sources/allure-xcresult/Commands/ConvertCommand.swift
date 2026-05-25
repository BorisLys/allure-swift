import Foundation
import ArgumentParser
import AllureXCResult

struct ConvertCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "convert",
        abstract: "Convert one .xcresult bundle to Allure 2 JSON results."
    )

    @Argument(help: "Path to the .xcresult bundle produced by xcodebuild test.")
    var bundle: String

    @Option(name: [.short, .long], help: "Output directory for allure-results. Created if missing.")
    var output: String = "./allure-results"

    @Flag(help: "Wipe the output directory before writing.")
    var clean: Bool = false

    @Flag(name: .customLong("no-attachments"), help: "Skip attachment export and copy.")
    var noAttachments: Bool = false

    @Flag(name: [.short, .long], help: "Print per-test progress.")
    var verbose: Bool = false

    func run() throws {
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let bundleURL = Self.resolve(path: bundle, relativeTo: cwd)
        let outputURL = Self.resolve(path: output, relativeTo: cwd)

        let options = ConverterOptions(
            includeAttachments: !noAttachments,
            cleanOutputDirectory: clean,
            verbose: verbose
        )

        let converter = try Converter(bundleURL: bundleURL, outputDir: outputURL, options: options)
        let log: ((String) -> Void)? = verbose ? { FileHandle.standardError.write(Data(($0 + "\n").utf8)) } : nil
        let result = try converter.run(log: log)

        print("Wrote \(result.testsConverted) test results to \(result.outputDirectory.path)")
        if result.attachmentsCopied > 0 {
            print("Copied \(result.attachmentsCopied) attachments")
        }
    }

    private static func resolve(path: String, relativeTo base: URL) -> URL {
        if path.hasPrefix("/") { return URL(fileURLWithPath: path) }
        let expanded = (path as NSString).expandingTildeInPath
        if expanded.hasPrefix("/") { return URL(fileURLWithPath: expanded) }
        return base.appendingPathComponent(expanded)
    }
}
