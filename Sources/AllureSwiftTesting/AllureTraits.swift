import Testing

// MARK: - Severity

/// Test severity level used in Allure reports.
public enum Severity: String, Sendable {
    case blocker
    case critical
    case normal
    case minor
    case trivial
}

// MARK: - Internal base

/// Base for all Allure directive traits.
///
/// Each conforming type exposes its `allure.*` directive as a `Comment`.
/// Swift Testing serialises comments into `ActionTestSummary.documentation`
/// inside the `.xcresult` bundle, where xcresult-to-Allure converters read them.
private protocol AllureDirectiveTrait: TestTrait, SuiteTrait {
    var directive: String { get }
}

extension AllureDirectiveTrait {
    public var comments: [Comment] {
        [Comment(rawValue: directive)]
    }
}

// MARK: - Identity traits

public struct AllureIdTrait: AllureDirectiveTrait {
    var directive: String { "allure.id:\(id)" }
    let id: String
    public init(_ id: Int) { self.id = "\(id)" }
    public init(_ id: String) { self.id = id }
}

public struct AllureNameTrait: AllureDirectiveTrait {
    var directive: String { "allure.name:\(name)" }
    let name: String
    public init(_ name: String) { self.name = name }
}

public struct AllureDescriptionTrait: AllureDirectiveTrait {
    var directive: String { "allure.description:\(text)" }
    let text: String
    public init(_ text: String) { self.text = text }
}

// MARK: - Label traits

public struct AllureEpicTrait: AllureDirectiveTrait {
    var directive: String { "allure.label.epic:\(value)" }
    let value: String
    public init(_ value: String) { self.value = value }
}

public struct AllureFeatureTrait: AllureDirectiveTrait {
    var directive: String { "allure.label.feature:\(value)" }
    let value: String
    public init(_ value: String) { self.value = value }
}

public struct AllureStoryTrait: AllureDirectiveTrait {
    var directive: String { "allure.label.story:\(value)" }
    let value: String
    public init(_ value: String) { self.value = value }
}

public struct AllureSeverityTrait: AllureDirectiveTrait {
    var directive: String { "allure.label.severity:\(level.rawValue)" }
    let level: Severity
    public init(_ level: Severity) { self.level = level }
}

public struct AllureOwnerTrait: AllureDirectiveTrait {
    var directive: String { "allure.label.owner:\(value)" }
    let value: String
    public init(_ value: String) { self.value = value }
}

public struct AllureTagTrait: AllureDirectiveTrait {
    var directive: String { "allure.label.tag:\(value)" }
    let value: String
    public init(_ value: String) { self.value = value }
}

public struct AllureLayerTrait: AllureDirectiveTrait {
    var directive: String { "allure.label.layer:\(value)" }
    let value: String
    public init(_ value: String) { self.value = value }
}

public struct AllureSuiteTrait: AllureDirectiveTrait {
    var directive: String { "allure.label.suite:\(value)" }
    let value: String
    public init(_ value: String) { self.value = value }
}

/// Attaches an arbitrary Allure label by name.
public struct AllureLabelTrait: AllureDirectiveTrait {
    var directive: String { "allure.label.\(name):\(value)" }
    let name: String
    let value: String
    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

// MARK: - Link traits

public struct AllureLinkTrait: AllureDirectiveTrait {
    var directive: String {
        if let type {
            return "allure.link.\(linkName)[\(type)]:\(url)"
        }
        return "allure.link.\(linkName):\(url)"
    }
    let linkName: String
    let url: String
    let type: String?

    public init(name: String? = nil, url: String, type: String? = nil) {
        self.linkName = name ?? url
        self.url = url
        self.type = type
    }
}

// MARK: - Trait factory extensions
//
// Enable dot-syntax in @Test and @Suite declarations:
//
//   @Suite()
//   struct CheckoutTests {
//
//       @Test(.allureId(42), .epic("Cart"), .feature("Checkout"), .severity(.critical))
//       func happyPath() async throws { … }
//   }

extension Trait where Self == AllureIdTrait {
    public static func allureId(_ id: Int) -> Self { .init(id) }
    public static func allureId(_ id: String) -> Self { .init(id) }
}

extension Trait where Self == AllureNameTrait {
    public static func name(_ name: String) -> Self { .init(name) }
}

extension Trait where Self == AllureDescriptionTrait {
    public static func description(_ text: String) -> Self { .init(text) }
}

extension Trait where Self == AllureEpicTrait {
    public static func epic(_ value: String) -> Self { .init(value) }
}

extension Trait where Self == AllureFeatureTrait {
    public static func feature(_ value: String) -> Self { .init(value) }
}

extension Trait where Self == AllureStoryTrait {
    public static func story(_ value: String) -> Self { .init(value) }
}

extension Trait where Self == AllureSeverityTrait {
    public static func severity(_ level: Severity) -> Self { .init(level) }
}

extension Trait where Self == AllureOwnerTrait {
    public static func owner(_ value: String) -> Self { .init(value) }
}

extension Trait where Self == AllureTagTrait {
    public static func tag(_ value: String) -> Self { .init(value) }
}

extension Trait where Self == AllureLayerTrait {
    public static func layer(_ value: String) -> Self { .init(value) }
}

extension Trait where Self == AllureSuiteTrait {
    public static func suite(_ value: String) -> Self { .init(value) }
}

extension Trait where Self == AllureLabelTrait {
    public static func label(_ name: String, value: String) -> Self {
        .init(name: name, value: value)
    }
}

extension Trait where Self == AllureLinkTrait {
    public static func link(name: String? = nil, url: String, type: String? = nil) -> Self {
        .init(name: name, url: url, type: type)
    }
    public static func issue(name: String? = nil, url: String) -> Self {
        .init(name: name ?? url, url: url, type: "issue")
    }
    public static func tms(name: String? = nil, url: String) -> Self {
        .init(name: name ?? url, url: url, type: "tms")
    }
}
