# allure-swift

A Swift Package Manager library that generates [Allure Report](https://allurereport.org/) result files from Swift tests. Works with both **XCTest** and **Swift Testing**, producing JSON in the format the Allure CLI consumes.

## Features

- Native Swift 6, fully `Sendable`, strict-concurrency clean.
- XCTest integration: automatic lifecycle via `XCTestObservation`.
- XCTest UI failure diagnostics: assertion details, UI hierarchy, and a screenshot are attached on failed tests when available.
- Swift Testing integration: traits (`.allure`, `.epic`, `.feature`, …) plus `TestScoping`.
- Steps (sync + async, arbitrarily nested), attachments, labels, links, parameters.
- Fixtures via `TestResultContainer` (befores/afters).
- `environment.properties`, `executor.json`, `categories.json` writers.
- Output directory configurable via `ALLURE_RESULTS_DIR` env or `Allure.configure(directory:)`.

## Requirements

- Swift 6.0 / Xcode 16+
- macOS 13+, iOS 16+

## Installation

In `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/allure-swift.git", branch: "main"),
],
```

Then add the products you need to your test target:

```swift
.testTarget(
    name: "MyAppTests",
    dependencies: [
        .product(name: "AllureSwiftXCTest", package: "allure-swift"),
        // and/or
        .product(name: "AllureSwiftTesting", package: "allure-swift"),
    ]
),
```

Or pull the umbrella `AllureSwift` product to get both.

## Quick start — XCTest

```swift
import XCTest
import AllureSwiftCore
import AllureSwiftXCTest

final class CheckoutTests: AllureTestCase {
    func testHappyPath() throws {
        Allure.epic("Checkout")
        Allure.feature("Cart")
        Allure.severity(.critical)
        Allure.id(1234)

        try Allure.step("Add item to cart") {
            // ...
        }
        try Allure.step("Pay") {
            Allure.parameter(name: "method", value: "card")
            try Allure.step("Submit form") {
                // ...
            }
        }

        Allure.addAttachment(name: "summary", type: .textPlain, content: "order ok")
    }
}
```

If you cannot subclass `AllureTestCase`, call `Allure.bind(self)` in your `setUp()` and `Allure.unbind()` in `tearDown()`. Either way the observer is auto-registered on first use; you can also call `AllureXCTest.bootstrap()` explicitly from your test bundle's principal class.

## Quick start — Swift Testing

```swift
import Testing
import AllureSwiftCore
import AllureSwiftTesting

@Suite("Checkout", .allure)
struct CheckoutTests {
    @Test(
        .epic("Checkout"),
        .feature("Cart"),
        .severity(.critical),
        .allureID(1234),
        .link(name: "ticket", url: "https://tracker/ABC-1", type: .issue)
    )
    func happyPath() async throws {
        try await Allure.step("Add item to cart") { /* ... */ }
        try await Allure.step("Pay") {
            Allure.parameter(name: "method", value: "card")
            try await Allure.step("Submit form") { /* ... */ }
        }
        Allure.addAttachment(name: "summary", type: .textPlain, content: "order ok")
    }
}
```

The `.allure` trait must be present (on the test or its enclosing suite) for an Allure result file to be produced.

## Output

By default, files are written to `./allure-results` (relative to the test process's working directory). Override with:

- `Allure.configure(directory: URL(fileURLWithPath: "/path/to/dir"))`, or
- the `ALLURE_RESULTS_DIR` environment variable.

The results directory is cleared once before the first file is written for a test run.

### Xcode: write results into the project directory

When running on iOS/tvOS Simulator, the test process does not inherit `SOURCE_ROOT` from the xcodebuild environment. The reliable way to route results to your project folder is to set the env var in the scheme:

1. In Xcode, open **Product → Scheme → Edit Scheme…** (or ⌘<)
2. Select the **Test** action → **Arguments** tab → **Environment Variables**
3. Add:

   | Name | Value |
   |---|---|
   | `ALLURE_RESULTS_DIR` | `$(SOURCE_ROOT)/allure-results` |

The `$(SOURCE_ROOT)` macro is resolved by Xcode before the variable is injected into the test runner, so results land at `<YourProject>/allure-results/` regardless of simulator.

To automate this via the `.xcscheme` file instead, add the following inside the `<TestAction>` element:

```xml
<EnvironmentVariables>
    <EnvironmentVariable
        key   = "ALLURE_RESULTS_DIR"
        value = "$(SOURCE_ROOT)/allure-results"
        isEnabled = "YES">
    </EnvironmentVariable>
</EnvironmentVariables>
```

Files produced:

| File | Contents |
|---|---|
| `<uuid>-result.json` | one per test |
| `<uuid>-container.json` | one per fixture container |
| `<uuid>-attachment.<ext>` | one per attachment |
| `environment.properties` | optional, key=value lines |
| `executor.json` | optional |
| `categories.json` | optional |

Run the Allure CLI on the directory to render the report:

```sh
allure generate allure-results -o allure-report --clean
allure open allure-report
```

## Labels reference

The library exposes well-known Allure labels through `LabelName`:

| `LabelName` | JSON `name` |
|---|---|
| `.epic` | `epic` |
| `.feature` | `feature` |
| `.story` | `story` |
| `.severity` | `severity` |
| `.tag` | `tag` |
| `.owner` | `owner` |
| `.suite` / `.parentSuite` / `.subSuite` | `suite` / `parentSuite` / `subSuite` |
| `.host` / `.thread` | `host` / `thread` |
| `.framework` / `.language` / `.package` | `framework` / `language` / `package` |
| `.testClass` / `.testMethod` | `testClass` / `testMethod` |
| `.allureId` | `AS_ID` |
| `.layer` / `.lead` | `layer` / `lead` |

Helpers `Allure.epic(_:)`, `Allure.feature(_:)`, etc. write these directly. For arbitrary labels use `Allure.label(name:value:)`.

## Architecture

The package is split into four targets so consumers pull only what they need:

| Target | What it gives you |
|---|---|
| `AllureSwiftCore` | Models, lifecycle, writer, `Allure` facade, context propagation. No framework deps. |
| `AllureSwiftXCTest` | `AllureXCTestObserver`, `AllureTestCase` base class, `AllureXCTest.bootstrap()`. |
| `AllureSwiftTesting` | `AllureTrait` (`TestScoping`), metadata traits, `Trait.allure` / `.epic` / … helpers. |
| `AllureSwift` | Umbrella that re-exports all three. |

Lifecycle state is kept in `AllureLifecycle` (a `final class` guarded by `OSAllocatedUnfairLock`) so calls from sync XCTest code don't need `await`. The current-test identifier is propagated via a `@TaskLocal` for Swift Testing and `Thread.current.threadDictionary` for XCTest; `AllureContext.current` checks both.

## License

MIT — see `LICENSE`.
