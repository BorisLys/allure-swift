import Foundation
import AllureSwiftCore
import XCResultParser

/// Converts an xcresult `Activity` tree into Allure `StepResult` tree.
public enum ActivityMapper {
    /// Top-level entry: combines all runs of a test into a flat step list.
    /// Returns at most one wrapper step per device run when there are
    /// multiple runs (re-runs / retries), otherwise inlines steps directly.
    public static func map(activities: TestActivities) -> [StepResult] {
        let runs = activities.testRuns ?? []
        if runs.count == 1, let run = runs.first {
            return mapActivities(run.activities ?? [])
        }
        return runs.compactMap { run -> StepResult? in
            let name: String = run.device?.deviceName ?? "Test Run"
            let steps = mapActivities(run.activities ?? [])
            if steps.isEmpty { return nil }
            return StepResult(name: name, status: .passed, steps: steps)
        }
    }

    /// Recursively maps a list of activities to step results.
    public static func mapActivities(_ activities: [Activity]) -> [StepResult] {
        activities.map { map(activity: $0) }
    }

    /// Single activity → single step (steps nest recursively).
    public static func map(activity: Activity) -> StepResult {
        let status: Status = (activity.isAssociatedWithFailure ?? false) ? .failed : .passed
        let start = activity.startTime.map { Int64(($0 * 1000.0).rounded()) }
        let childSteps = mapActivities(activity.childActivities ?? [])
        let attachments = (activity.attachments ?? []).map { att in
            Attachment(
                name: att.name,
                source: att.uuid ?? att.payloadId ?? "",
                type: nil
            )
        }
        return StepResult(
            name: activity.title,
            status: status,
            stage: .finished,
            start: start,
            stop: nil,
            steps: childSteps,
            attachments: attachments,
            parameters: []
        )
    }
}
