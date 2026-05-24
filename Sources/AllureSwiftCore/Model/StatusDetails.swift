import Foundation

public struct StatusDetails: Codable, Sendable, Hashable {
    public var known: Bool?
    public var muted: Bool?
    public var flaky: Bool?
    public var message: String?
    public var trace: String?

    public init(
        known: Bool? = nil,
        muted: Bool? = nil,
        flaky: Bool? = nil,
        message: String? = nil,
        trace: String? = nil
    ) {
        self.known = known
        self.muted = muted
        self.flaky = flaky
        self.message = message
        self.trace = trace
    }

    private enum CodingKeys: String, CodingKey {
        case known, muted, flaky, message, trace
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(known, forKey: .known)
        try c.encodeIfPresent(muted, forKey: .muted)
        try c.encodeIfPresent(flaky, forKey: .flaky)
        try c.encodeIfPresent(message, forKey: .message)
        try c.encodeIfPresent(trace, forKey: .trace)
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        known = try c.decodeIfPresent(Bool.self, forKey: .known)
        muted = try c.decodeIfPresent(Bool.self, forKey: .muted)
        flaky = try c.decodeIfPresent(Bool.self, forKey: .flaky)
        message = try c.decodeIfPresent(String.self, forKey: .message)
        trace = try c.decodeIfPresent(String.self, forKey: .trace)
    }
}
