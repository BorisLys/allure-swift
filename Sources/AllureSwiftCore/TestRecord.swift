import Foundation

struct StepFrame: Hashable {
    let uuid: String
    let index: Int
}

struct TestRecord {
    var result: TestResult
    var stepStack: [StepFrame]

    init(result: TestResult) {
        self.result = result
        self.stepStack = []
    }
}

struct FixtureEntry {
    var isBefore: Bool
    var fixture: FixtureResult
    var stepStack: [StepFrame]
}

struct ContainerRecord {
    var container: TestResultContainer
    var activeFixtureUUID: String?
    var fixturesByUUID: [String: FixtureEntry]

    init(container: TestResultContainer) {
        self.container = container
        self.activeFixtureUUID = nil
        self.fixturesByUUID = [:]
    }
}
