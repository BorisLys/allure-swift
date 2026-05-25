import AllureSwiftCore

/// Maps `xcresulttool`'s string status values to Allure `Status`.
public enum StatusMapper {
    public static func map(_ raw: String?) -> Status {
        switch (raw ?? "").lowercased() {
        case "passed":
            return .passed
        case "failed":
            return .failed
        case "skipped":
            return .skipped
        case "expected failure":
            return .skipped
        default:
            return .broken
        }
    }

    /// True when the status comes from an "Expected Failure" outcome —
    /// xcresult marks intentional failures separately; in Allure this is
    /// represented as a skipped result with `statusDetails.known = true`.
    public static func isExpectedFailure(_ raw: String?) -> Bool {
        (raw ?? "").lowercased() == "expected failure"
    }
}
