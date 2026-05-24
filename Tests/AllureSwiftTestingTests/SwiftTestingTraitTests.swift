import Foundation
import Testing
@testable import AllureSwiftCore
@testable import AllureSwiftTesting

@Suite("Allure Swift Testing integration", .allure)
struct SwiftTestingTraitTests {

    @Test(
        .epic("Sample"),
        .feature("Traits"),
        .story("Apply"),
        .severity(.critical),
        .owner("bob"),
        .allureID(7),
        .label(.tag, value: "trait-test"),
        .link(name: "tracker", url: "https://example/issue/7", type: .issue)
    )
    func tracksLabelsAndSteps() async throws {
        let uuid = try #require(AllureContext.currentUUID)
        try Allure.step("outer") {
            Allure.parameter(name: "p", value: "v")
            try Allure.step("inner") {
                Allure.addAttachment(name: "note", type: .textPlain, content: "scoped")
            }
        }
        AllureLifecycle.shared.updateTest(uuid: uuid) { result in
            result.description = "trait-test-description"
        }
    }
}
