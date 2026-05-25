import ArgumentParser

@main
struct AllureXCResultCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "allure-xcresult",
        abstract: "Convert .xcresult bundles produced by xcodebuild into Allure 2 JSON results.",
        version: "2.0.0",
        subcommands: [ConvertCommand.self],
        defaultSubcommand: ConvertCommand.self
    )
}
