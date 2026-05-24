import Foundation

public struct Attachment: Codable, Sendable, Hashable {
    public var name: String?
    public var source: String
    public var type: String?

    public init(name: String? = nil, source: String, type: String? = nil) {
        self.name = name
        self.source = source
        self.type = type
    }

    private enum CodingKeys: String, CodingKey {
        case name, source, type
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encode(source, forKey: .source)
        try c.encodeIfPresent(type, forKey: .type)
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        source = try c.decode(String.self, forKey: .source)
        type = try c.decodeIfPresent(String.self, forKey: .type)
    }
}

public enum AttachmentType: String, Sendable, Hashable, CaseIterable {
    case textPlain = "text/plain"
    case textHtml = "text/html"
    case textCsv = "text/csv"
    case textXml = "text/xml"
    case applicationJson = "application/json"
    case applicationXml = "application/xml"
    case applicationPdf = "application/pdf"
    case applicationZip = "application/zip"
    case imagePng = "image/png"
    case imageJpeg = "image/jpeg"
    case imageGif = "image/gif"
    case imageSvg = "image/svg+xml"
    case imageBmp = "image/bmp"
    case videoMp4 = "video/mp4"
    case videoMov = "video/quicktime"

    public var preferredExtension: String {
        switch self {
        case .textPlain: return "txt"
        case .textHtml: return "html"
        case .textCsv: return "csv"
        case .textXml: return "xml"
        case .applicationJson: return "json"
        case .applicationXml: return "xml"
        case .applicationPdf: return "pdf"
        case .applicationZip: return "zip"
        case .imagePng: return "png"
        case .imageJpeg: return "jpg"
        case .imageGif: return "gif"
        case .imageSvg: return "svg"
        case .imageBmp: return "bmp"
        case .videoMp4: return "mp4"
        case .videoMov: return "mov"
        }
    }
}
