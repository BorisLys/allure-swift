import Foundation

public struct Label: Codable, Sendable, Hashable {
    public var name: String
    public var value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }

    public init(_ name: LabelName, value: String) {
        self.name = name.rawValue
        self.value = value
    }
}

public enum LabelName: String, Sendable, Hashable, CaseIterable {
    case epic
    case feature
    case story
    case severity
    case tag
    case owner
    case suite
    case parentSuite
    case subSuite
    case host
    case thread
    case framework
    case language
    case package
    case testClass
    case testMethod
    case allureId = "AS_ID"
    case layer
    case lead
}
