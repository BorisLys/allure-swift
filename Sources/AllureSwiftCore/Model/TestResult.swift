import Foundation

public struct TestResult: Codable, Sendable, Hashable {
    public var uuid: String
    public var historyId: String?
    public var testCaseId: String?
    public var fullName: String?
    public var name: String
    public var description: String?
    public var descriptionHtml: String?
    public var status: Status?
    public var statusDetails: StatusDetails?
    public var stage: Stage?
    public var start: Int64?
    public var stop: Int64?
    public var labels: [Label]
    public var links: [Link]
    public var parameters: [Parameter]
    public var steps: [StepResult]
    public var attachments: [Attachment]

    public init(
        uuid: String,
        historyId: String? = nil,
        testCaseId: String? = nil,
        fullName: String? = nil,
        name: String,
        description: String? = nil,
        descriptionHtml: String? = nil,
        status: Status? = nil,
        statusDetails: StatusDetails? = nil,
        stage: Stage? = nil,
        start: Int64? = nil,
        stop: Int64? = nil,
        labels: [Label] = [],
        links: [Link] = [],
        parameters: [Parameter] = [],
        steps: [StepResult] = [],
        attachments: [Attachment] = []
    ) {
        self.uuid = uuid
        self.historyId = historyId
        self.testCaseId = testCaseId
        self.fullName = fullName
        self.name = name
        self.description = description
        self.descriptionHtml = descriptionHtml
        self.status = status
        self.statusDetails = statusDetails
        self.stage = stage
        self.start = start
        self.stop = stop
        self.labels = labels
        self.links = links
        self.parameters = parameters
        self.steps = steps
        self.attachments = attachments
    }

    private enum CodingKeys: String, CodingKey {
        case uuid, historyId, testCaseId, fullName, name
        case description, descriptionHtml
        case status, statusDetails, stage, start, stop
        case labels, links, parameters, steps, attachments
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(uuid, forKey: .uuid)
        try c.encodeIfPresent(historyId, forKey: .historyId)
        try c.encodeIfPresent(testCaseId, forKey: .testCaseId)
        try c.encodeIfPresent(fullName, forKey: .fullName)
        try c.encode(name, forKey: .name)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(descriptionHtml, forKey: .descriptionHtml)
        try c.encodeIfPresent(status, forKey: .status)
        try c.encodeIfPresent(statusDetails, forKey: .statusDetails)
        try c.encodeIfPresent(stage, forKey: .stage)
        try c.encodeIfPresent(start, forKey: .start)
        try c.encodeIfPresent(stop, forKey: .stop)
        try c.encode(labels, forKey: .labels)
        try c.encode(links, forKey: .links)
        try c.encode(parameters, forKey: .parameters)
        try c.encode(steps, forKey: .steps)
        try c.encode(attachments, forKey: .attachments)
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try c.decode(String.self, forKey: .uuid)
        historyId = try c.decodeIfPresent(String.self, forKey: .historyId)
        testCaseId = try c.decodeIfPresent(String.self, forKey: .testCaseId)
        fullName = try c.decodeIfPresent(String.self, forKey: .fullName)
        name = try c.decode(String.self, forKey: .name)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        descriptionHtml = try c.decodeIfPresent(String.self, forKey: .descriptionHtml)
        status = try c.decodeIfPresent(Status.self, forKey: .status)
        statusDetails = try c.decodeIfPresent(StatusDetails.self, forKey: .statusDetails)
        stage = try c.decodeIfPresent(Stage.self, forKey: .stage)
        start = try c.decodeIfPresent(Int64.self, forKey: .start)
        stop = try c.decodeIfPresent(Int64.self, forKey: .stop)
        labels = try c.decodeIfPresent([Label].self, forKey: .labels) ?? []
        links = try c.decodeIfPresent([Link].self, forKey: .links) ?? []
        parameters = try c.decodeIfPresent([Parameter].self, forKey: .parameters) ?? []
        steps = try c.decodeIfPresent([StepResult].self, forKey: .steps) ?? []
        attachments = try c.decodeIfPresent([Attachment].self, forKey: .attachments) ?? []
    }
}
