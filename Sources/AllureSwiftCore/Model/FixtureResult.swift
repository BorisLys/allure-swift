import Foundation

public struct FixtureResult: Codable, Sendable, Hashable {
    public var name: String
    public var status: Status?
    public var statusDetails: StatusDetails?
    public var stage: Stage?
    public var description: String?
    public var descriptionHtml: String?
    public var start: Int64?
    public var stop: Int64?
    public var steps: [StepResult]
    public var attachments: [Attachment]
    public var parameters: [Parameter]

    public init(
        name: String,
        status: Status? = nil,
        statusDetails: StatusDetails? = nil,
        stage: Stage? = nil,
        description: String? = nil,
        descriptionHtml: String? = nil,
        start: Int64? = nil,
        stop: Int64? = nil,
        steps: [StepResult] = [],
        attachments: [Attachment] = [],
        parameters: [Parameter] = []
    ) {
        self.name = name
        self.status = status
        self.statusDetails = statusDetails
        self.stage = stage
        self.description = description
        self.descriptionHtml = descriptionHtml
        self.start = start
        self.stop = stop
        self.steps = steps
        self.attachments = attachments
        self.parameters = parameters
    }

    private enum CodingKeys: String, CodingKey {
        case name, status, statusDetails, stage, description, descriptionHtml
        case start, stop, steps, attachments, parameters
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encodeIfPresent(status, forKey: .status)
        try c.encodeIfPresent(statusDetails, forKey: .statusDetails)
        try c.encodeIfPresent(stage, forKey: .stage)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(descriptionHtml, forKey: .descriptionHtml)
        try c.encodeIfPresent(start, forKey: .start)
        try c.encodeIfPresent(stop, forKey: .stop)
        try c.encode(steps, forKey: .steps)
        try c.encode(attachments, forKey: .attachments)
        try c.encode(parameters, forKey: .parameters)
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        status = try c.decodeIfPresent(Status.self, forKey: .status)
        statusDetails = try c.decodeIfPresent(StatusDetails.self, forKey: .statusDetails)
        stage = try c.decodeIfPresent(Stage.self, forKey: .stage)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        descriptionHtml = try c.decodeIfPresent(String.self, forKey: .descriptionHtml)
        start = try c.decodeIfPresent(Int64.self, forKey: .start)
        stop = try c.decodeIfPresent(Int64.self, forKey: .stop)
        steps = try c.decodeIfPresent([StepResult].self, forKey: .steps) ?? []
        attachments = try c.decodeIfPresent([Attachment].self, forKey: .attachments) ?? []
        parameters = try c.decodeIfPresent([Parameter].self, forKey: .parameters) ?? []
    }
}
