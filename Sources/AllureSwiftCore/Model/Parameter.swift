import Foundation

public struct Parameter: Codable, Sendable, Hashable {
    public enum Mode: String, Codable, Sendable, Hashable, CaseIterable {
        case `default`
        case masked
        case hidden
    }

    public var name: String
    public var value: String
    public var excluded: Bool?
    public var mode: Mode?

    public init(name: String, value: String, excluded: Bool? = nil, mode: Mode? = nil) {
        self.name = name
        self.value = value
        self.excluded = excluded
        self.mode = mode
    }

    private enum CodingKeys: String, CodingKey {
        case name, value, excluded, mode
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(value, forKey: .value)
        try c.encodeIfPresent(excluded, forKey: .excluded)
        try c.encodeIfPresent(mode, forKey: .mode)
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        value = try c.decode(String.self, forKey: .value)
        excluded = try c.decodeIfPresent(Bool.self, forKey: .excluded)
        mode = try c.decodeIfPresent(Mode.self, forKey: .mode)
    }
}
