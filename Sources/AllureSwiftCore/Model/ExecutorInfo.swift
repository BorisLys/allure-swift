import Foundation

public struct ExecutorInfo: Codable, Sendable, Hashable {
    public var name: String?
    public var type: String?
    public var url: String?
    public var buildOrder: Int64?
    public var buildName: String?
    public var buildUrl: String?
    public var reportName: String?
    public var reportUrl: String?

    public init(
        name: String? = nil,
        type: String? = nil,
        url: String? = nil,
        buildOrder: Int64? = nil,
        buildName: String? = nil,
        buildUrl: String? = nil,
        reportName: String? = nil,
        reportUrl: String? = nil
    ) {
        self.name = name
        self.type = type
        self.url = url
        self.buildOrder = buildOrder
        self.buildName = buildName
        self.buildUrl = buildUrl
        self.reportName = reportName
        self.reportUrl = reportUrl
    }

    private enum CodingKeys: String, CodingKey {
        case name, type, url, buildOrder, buildName, buildUrl, reportName, reportUrl
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(type, forKey: .type)
        try c.encodeIfPresent(url, forKey: .url)
        try c.encodeIfPresent(buildOrder, forKey: .buildOrder)
        try c.encodeIfPresent(buildName, forKey: .buildName)
        try c.encodeIfPresent(buildUrl, forKey: .buildUrl)
        try c.encodeIfPresent(reportName, forKey: .reportName)
        try c.encodeIfPresent(reportUrl, forKey: .reportUrl)
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        type = try c.decodeIfPresent(String.self, forKey: .type)
        url = try c.decodeIfPresent(String.self, forKey: .url)
        buildOrder = try c.decodeIfPresent(Int64.self, forKey: .buildOrder)
        buildName = try c.decodeIfPresent(String.self, forKey: .buildName)
        buildUrl = try c.decodeIfPresent(String.self, forKey: .buildUrl)
        reportName = try c.decodeIfPresent(String.self, forKey: .reportName)
        reportUrl = try c.decodeIfPresent(String.self, forKey: .reportUrl)
    }
}

public struct EnvironmentInfo: Sendable, Hashable {
    public var entries: [(key: String, value: String)]

    public init(entries: [(key: String, value: String)] = []) {
        self.entries = entries
    }

    public init(_ dictionary: [String: String]) {
        self.entries = dictionary.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }

    public static func == (lhs: EnvironmentInfo, rhs: EnvironmentInfo) -> Bool {
        guard lhs.entries.count == rhs.entries.count else { return false }
        for (l, r) in zip(lhs.entries, rhs.entries) where l != r { return false }
        return true
    }

    public func hash(into hasher: inout Hasher) {
        for entry in entries {
            hasher.combine(entry.key)
            hasher.combine(entry.value)
        }
    }

    public func render() -> String {
        entries.map { "\(escape($0.key))=\(escape($0.value))" }.joined(separator: "\n") + "\n"
    }

    private func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\n", with: "\\n")
    }
}

public struct Category: Codable, Sendable, Hashable {
    public var name: String
    public var description: String?
    public var descriptionHtml: String?
    public var messageRegex: String?
    public var traceRegex: String?
    public var matchedStatuses: [Status]?
    public var flaky: Bool?

    public init(
        name: String,
        description: String? = nil,
        descriptionHtml: String? = nil,
        messageRegex: String? = nil,
        traceRegex: String? = nil,
        matchedStatuses: [Status]? = nil,
        flaky: Bool? = nil
    ) {
        self.name = name
        self.description = description
        self.descriptionHtml = descriptionHtml
        self.messageRegex = messageRegex
        self.traceRegex = traceRegex
        self.matchedStatuses = matchedStatuses
        self.flaky = flaky
    }

    private enum CodingKeys: String, CodingKey {
        case name, description, descriptionHtml, messageRegex, traceRegex, matchedStatuses, flaky
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(descriptionHtml, forKey: .descriptionHtml)
        try c.encodeIfPresent(messageRegex, forKey: .messageRegex)
        try c.encodeIfPresent(traceRegex, forKey: .traceRegex)
        try c.encodeIfPresent(matchedStatuses, forKey: .matchedStatuses)
        try c.encodeIfPresent(flaky, forKey: .flaky)
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        descriptionHtml = try c.decodeIfPresent(String.self, forKey: .descriptionHtml)
        messageRegex = try c.decodeIfPresent(String.self, forKey: .messageRegex)
        traceRegex = try c.decodeIfPresent(String.self, forKey: .traceRegex)
        matchedStatuses = try c.decodeIfPresent([Status].self, forKey: .matchedStatuses)
        flaky = try c.decodeIfPresent(Bool.self, forKey: .flaky)
    }
}
