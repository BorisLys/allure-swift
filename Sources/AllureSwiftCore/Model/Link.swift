import Foundation

public struct Link: Codable, Sendable, Hashable {
    public var name: String?
    public var url: String
    public var type: String?

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

    private enum CodingKeys: String, CodingKey {
        case name, url, type
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encode(url, forKey: .url)
        try c.encodeIfPresent(type, forKey: .type)
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        url = try c.decode(String.self, forKey: .url)
        type = try c.decodeIfPresent(String.self, forKey: .type)
    }
}

public enum LinkType: String, Sendable, Hashable, CaseIterable {
    case issue
    case tms
    case custom
}
