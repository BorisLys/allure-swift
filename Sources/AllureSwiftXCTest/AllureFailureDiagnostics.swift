import Foundation
import XCTest
import AllureSwiftCore

enum AllureFailureDiagnostics {
    static func attachFailureDiagnostics(
        testUUID: String,
        issues: [XCTIssue],
        uiHierarchy: () -> String? = uiHierarchyText,
        screenshotPNG: () -> Data? = screenshotPNGData
    ) {
        guard !issues.isEmpty else { return }

        AllureLifecycle.shared.addAttachmentData(
            parentUUID: testUUID,
            name: "failure-assertions",
            type: AttachmentType.textPlain.rawValue,
            data: Data(assertionsText(from: issues).utf8),
            fileExtension: AttachmentType.textPlain.preferredExtension
        )

        if let hierarchy = uiHierarchy(),
           !hierarchy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            AllureLifecycle.shared.addAttachmentData(
                parentUUID: testUUID,
                name: "ui-hierarchy",
                type: AttachmentType.textPlain.rawValue,
                data: Data(hierarchy.utf8),
                fileExtension: AttachmentType.textPlain.preferredExtension
            )
        }

        if let screenshot = screenshotPNG(), !screenshot.isEmpty {
            AllureLifecycle.shared.addAttachmentData(
                parentUUID: testUUID,
                name: "screenshot",
                type: AttachmentType.imagePng.rawValue,
                data: screenshot,
                fileExtension: AttachmentType.imagePng.preferredExtension
            )
        }
    }

    static func assertionsText(from issues: [XCTIssue]) -> String {
        issues.enumerated().map { index, issue in
            var lines = [
                "Failure #\(index + 1)",
                "Type: \(issueTypeName(issue.type))",
                "Message: \(issue.compactDescription)",
            ]
            if let details = issue.detailedDescription, !details.isEmpty {
                lines.append("Details: \(details)")
            }
            if let location = issue.sourceCodeContext.location {
                lines.append("Location: \(location.fileURL.path):\(location.lineNumber)")
            }
            if let error = issue.associatedError {
                lines.append("Error: \(error)")
            }
            return lines.joined(separator: "\n")
        }
        .joined(separator: "\n\n")
    }

    private static func uiHierarchyText() -> String? {
        let text: String = {
            if Thread.isMainThread {
                return MainActor.assumeIsolated {
                    XCUIApplication().debugDescription
                }
            }
            return DispatchQueue.main.sync {
                MainActor.assumeIsolated {
                    XCUIApplication().debugDescription
                }
            }
        }()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : text
    }

    private static func screenshotPNGData() -> Data? {
        let data: Data = {
            if Thread.isMainThread {
                return MainActor.assumeIsolated {
                    XCUIScreen.main.screenshot().pngRepresentation
                }
            }
            return DispatchQueue.main.sync {
                MainActor.assumeIsolated {
                    XCUIScreen.main.screenshot().pngRepresentation
                }
            }
        }()
        return data.isEmpty ? nil : data
    }

    private static func issueTypeName(_ type: XCTIssue.IssueType) -> String {
        switch type {
        case .assertionFailure: return "assertionFailure"
        case .performanceRegression: return "performanceRegression"
        case .system: return "system"
        case .thrownError: return "thrownError"
        case .uncaughtException: return "uncaughtException"
        case .unmatchedExpectedFailure: return "unmatchedExpectedFailure"
        @unknown default: return String(describing: type)
        }
    }
}
