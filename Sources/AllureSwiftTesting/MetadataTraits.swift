import Foundation
import Testing
import AllureSwiftCore

public protocol AllureMetadataTrait: TestTrait, Sendable {
    func apply(testUUID: String)
}

public struct AllureIDTrait: AllureMetadataTrait {
    public let value: String
    public init(_ value: Int) { self.value = String(value) }
    public init(_ value: String) { self.value = value }
    public func apply(testUUID: String) {
        AllureLifecycle.shared.addLabel(testUUID: testUUID, Label(.allureId, value: value))
    }
}

public struct EpicTrait: AllureMetadataTrait {
    public let value: String
    public init(_ value: String) { self.value = value }
    public func apply(testUUID: String) {
        AllureLifecycle.shared.addLabel(testUUID: testUUID, Label(.epic, value: value))
    }
}

public struct FeatureTrait: AllureMetadataTrait {
    public let value: String
    public init(_ value: String) { self.value = value }
    public func apply(testUUID: String) {
        AllureLifecycle.shared.addLabel(testUUID: testUUID, Label(.feature, value: value))
    }
}

public struct StoryTrait: AllureMetadataTrait {
    public let value: String
    public init(_ value: String) { self.value = value }
    public func apply(testUUID: String) {
        AllureLifecycle.shared.addLabel(testUUID: testUUID, Label(.story, value: value))
    }
}

public struct SeverityTrait: AllureMetadataTrait {
    public let value: Severity
    public init(_ value: Severity) { self.value = value }
    public func apply(testUUID: String) {
        AllureLifecycle.shared.addLabel(testUUID: testUUID, Label(.severity, value: value.rawValue))
    }
}

public struct OwnerTrait: AllureMetadataTrait {
    public let value: String
    public init(_ value: String) { self.value = value }
    public func apply(testUUID: String) {
        AllureLifecycle.shared.addLabel(testUUID: testUUID, Label(.owner, value: value))
    }
}

public struct AllureTagTrait: AllureMetadataTrait {
    public let value: String
    public init(_ value: String) { self.value = value }
    public func apply(testUUID: String) {
        AllureLifecycle.shared.addLabel(testUUID: testUUID, Label(.tag, value: value))
    }
}

public struct LabelTrait: AllureMetadataTrait {
    public let name: String
    public let value: String
    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
    public init(_ name: LabelName, value: String) {
        self.name = name.rawValue
        self.value = value
    }
    public func apply(testUUID: String) {
        AllureLifecycle.shared.addLabel(testUUID: testUUID, Label(name: name, value: value))
    }
}

public struct LinkTrait: AllureMetadataTrait {
    public let name: String?
    public let url: String
    public let type: String?
    public init(name: String? = nil, url: String, type: String? = nil) {
        self.name = name
        self.url = url
        self.type = type
    }
    public init(name: String? = nil, url: String, type: LinkType) {
        self.name = name
        self.url = url
        self.type = type.rawValue
    }
    public func apply(testUUID: String) {
        AllureLifecycle.shared.addLink(testUUID: testUUID, Link(name: name, url: url, type: type))
    }
}

public struct DescriptionTrait: AllureMetadataTrait {
    public let value: String
    public let html: Bool
    public init(_ value: String, html: Bool = false) {
        self.value = value
        self.html = html
    }
    public func apply(testUUID: String) {
        AllureLifecycle.shared.updateTest(uuid: testUUID) { result in
            if html {
                result.descriptionHtml = value
            } else {
                result.description = value
            }
        }
    }
}
