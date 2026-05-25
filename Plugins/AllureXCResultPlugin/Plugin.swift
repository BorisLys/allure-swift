import Foundation
import PackagePlugin

@main
struct AllureXCResultPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let tool = try context.tool(named: "allure-xcresult")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tool.path.string)
        process.arguments = arguments
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            throw PluginError.executableFailed(code: process.terminationStatus)
        }
    }
}

enum PluginError: Error, CustomStringConvertible {
    case executableFailed(code: Int32)

    var description: String {
        switch self {
        case .executableFailed(let code):
            return "allure-xcresult exited with code \(code)"
        }
    }
}
