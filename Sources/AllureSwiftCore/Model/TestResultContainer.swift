import Foundation

public struct TestResultContainer: Codable, Sendable, Hashable {
    public var uuid: String
    public var name: String?
    public var children: [String]
    public var description: String?
    public var descriptionHtml: String?
    public var befores: [FixtureResult]
    public var afters: [FixtureResult]
    public var links: [Link]
    public var start: Int64?
    public var stop: Int64?

    public init(
        uuid: String,
        name: String? = nil,
        children: [String] = [],
        description: String? = nil,
        descriptionHtml: String? = nil,
        befores: [FixtureResult] = [],
        afters: [FixtureResult] = [],
        links: [Link] = [],
        start: Int64? = nil,
        stop: Int64? = nil
    ) {
        self.uuid = uuid
        self.name = name
        self.children = children
        self.description = description
        self.descriptionHtml = descriptionHtml
        self.befores = befores
        self.afters = afters
        self.links = links
        self.start = start
        self.stop = stop
    }

    private enum CodingKeys: String, CodingKey {
        case uuid, name, children, description, descriptionHtml
        case befores, afters, links, start, stop
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(uuid, forKey: .uuid)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encode(children, forKey: .children)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(descriptionHtml, forKey: .descriptionHtml)
        try c.encode(befores, forKey: .befores)
        try c.encode(afters, forKey: .afters)
        try c.encode(links, forKey: .links)
        try c.encodeIfPresent(start, forKey: .start)
        try c.encodeIfPresent(stop, forKey: .stop)
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try c.decode(String.self, forKey: .uuid)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        children = try c.decodeIfPresent([String].self, forKey: .children) ?? []
        description = try c.decodeIfPresent(String.self, forKey: .description)
        descriptionHtml = try c.decodeIfPresent(String.self, forKey: .descriptionHtml)
        befores = try c.decodeIfPresent([FixtureResult].self, forKey: .befores) ?? []
        afters = try c.decodeIfPresent([FixtureResult].self, forKey: .afters) ?? []
        links = try c.decodeIfPresent([Link].self, forKey: .links) ?? []
        start = try c.decodeIfPresent(Int64.self, forKey: .start)
        stop = try c.decodeIfPresent(Int64.self, forKey: .stop)
    }
}
