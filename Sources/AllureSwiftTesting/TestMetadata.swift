import Foundation
import Testing
import AllureSwiftCore

public struct TestMetadata: Sendable {
    public var displayName: String
    public var fullName: String
    public var module: String?
    public var typeName: String?
    public var functionName: String?
    public var sourceFile: String?
    public var sourceLine: Int?
}

public extension TestMetadata {
    static func build(for test: Test) -> TestMetadata {
        let display = test.displayName ?? test.name
        let id = test.id

        let module = id.moduleName
        let typeName = id.nameComponents.dropLast().last
        let functionName = id.nameComponents.last ?? test.name

        var pieces: [String] = []
        pieces.append(module)
        if let typeName { pieces.append(typeName) }
        pieces.append(functionName)
        let fullName = pieces.joined(separator: ".")

        let loc = test.sourceLocation
        return TestMetadata(
            displayName: display,
            fullName: fullName,
            module: module,
            typeName: typeName,
            functionName: functionName,
            sourceFile: loc.fileID,
            sourceLine: loc.line
        )
    }

    static func defaultLabels(for test: Test, meta: TestMetadata) -> [Label] {
        var labels: [Label] = [
            Label(.framework, value: "swift-testing"),
            Label(.language, value: "swift"),
        ]
        if let module = meta.module, !module.isEmpty {
            labels.append(Label(.package, value: module))
        }
        if let typeName = meta.typeName, !typeName.isEmpty {
            labels.append(Label(.testClass, value: typeName))
            labels.append(Label(.suite, value: typeName))
        }
        if let fn = meta.functionName, !fn.isEmpty {
            labels.append(Label(.testMethod, value: fn))
        }
        for tag in test.tags {
            labels.append(Label(.tag, value: String(describing: tag)))
        }
        return labels
    }
}
