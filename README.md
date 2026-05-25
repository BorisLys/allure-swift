# allure-swift

A **post-process converter** that turns Apple's `.xcresult` bundles into [Allure 2](https://allurereport.org/) JSON results, with an optional **runtime annotation library** for XCTest (`AllureSwiftXCTest`).

The converter runs **after** `xcodebuild test` finishes — no `XCTestObservation` quirks, no iOS Simulator scheme/env-var fights. The `.xcresult` bundle is Apple's canonical test output, so reading it after the fact is the cleanest path to Allure reporting on Swift/Apple projects.

When you use the `AllureSwiftXCTest` helpers (optional), each call like `allureId(1234)` or `allureStep("Open cart") { … }` writes a hidden `XCTActivity` into the `.xcresult` bundle during the test run. The converter reads those activities and turns them into Allure labels, links, name overrides, and step trees — bridging runtime intent with post-process output.

```
xcodebuild test … -resultBundlePath Build/test.xcresult
       │
       ▼
allure-xcresult convert Build/test.xcresult --output allure-results
       │
       ▼
allure generate allure-results --output allure-report
```

## Status

v2.0 — full rewrite of the v1 runtime SDK (lifecycle, traits, observer) as a CLI/library that parses `xcresult` bundles via `xcrun xcresulttool` and writes Allure JSON.

## Requirements

- **macOS** (any version that runs Xcode 16+)
- **Swift 6** (Xcode 16+) — only needed to build the converter; your tested code can target any platform Xcode supports
- **Xcode Command Line Tools** for `xcrun xcresulttool`
- **Allure CLI** for rendering reports (`brew install allure`) — optional, only required if you want to generate HTML

## Install

### Option 1 — SPM Command Plugin (recommended)

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/BorisLys/allure-swift.git", from: "2.0.0"),
],
```

Run the converter from anywhere inside the package:

```sh
swift package --allow-writing-to-directory allure-results \
    plugin allure-xcresult \
    convert Build/test.xcresult \
    --output allure-results
```

#### Adding runtime annotations to a test target (optional)

If you want to call `allureId`, `allureStep`, etc. from your XCTest test files, add `AllureSwiftXCTest` as a dependency of your **test target**:

```swift
.testTarget(
    name: "MyAppTests",
    dependencies: [
        "MyApp",
        .product(name: "AllureSwiftXCTest", package: "allure-swift"),
    ]
),
```

### Option 2 — Build the CLI from source

```sh
git clone https://github.com/BorisLys/allure-swift.git
cd allure-swift
swift build -c release
cp .build/release/allure-xcresult /usr/local/bin/   # or anywhere on PATH
```

Useful for plain `.xcodeproj` setups that don't have their own `Package.swift`.

## Usage

```sh
# 1. Run tests and capture an xcresult bundle.
xcodebuild test \
    -project SwiftRadio.xcodeproj \
    -scheme SwiftRadioTests \
    -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
    -resultBundlePath Build/test.xcresult

# 2. Convert to Allure JSON.
allure-xcresult convert Build/test.xcresult --output allure-results

# 3. Render the report.
allure generate allure-results --output allure-report --clean
allure open allure-report
```

### CLI flags

```
allure-xcresult convert <bundle> [options]

ARGUMENTS:
  <bundle>                Path to the .xcresult bundle.

OPTIONS:
  -o, --output <dir>      Output directory for allure-results (default: ./allure-results).
  --clean                 Wipe the output directory before writing.
  --no-attachments        Skip attachment export and copy.
  -v, --verbose           Print per-test progress to stderr.
  -h, --help              Show help.
```

## CI/CD recipes

### GitHub Actions

```yaml
name: tests
on: [push, pull_request]
jobs:
  ios-tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: |
          xcodebuild test \
            -project MyApp.xcodeproj \
            -scheme MyAppTests \
            -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
            -resultBundlePath build/test.xcresult
      - name: Convert to Allure
        run: |
          swift package --allow-writing-to-directory allure-results \
            plugin allure-xcresult convert build/test.xcresult \
            --output allure-results --clean
      - uses: actions/upload-artifact@v4
        with:
          name: allure-results
          path: allure-results/

      # Optional: render HTML and publish to Pages.
      - name: Generate Allure report
        run: |
          brew install allure
          allure generate allure-results -o allure-report --clean
      - uses: actions/upload-pages-artifact@v3
        with:
          path: allure-report
```

### Fastlane

```ruby
lane :tests do
  scan(
    project: "MyApp.xcodeproj",
    scheme: "MyAppTests",
    result_bundle: true,
    output_directory: "build"
  )
  sh "swift package --allow-writing-to-directory allure-results " \
     "plugin allure-xcresult convert ../build/MyApp.test_result " \
     "--output ../allure-results --clean"
end
```

### Plain shell (any CI)

```sh
xcodebuild test … -resultBundlePath build/test.xcresult
allure-xcresult convert build/test.xcresult -o allure-results --clean
allure generate allure-results -o allure-report --clean
```

## Runtime annotations — `AllureSwiftXCTest`

Import the library in your test file, then call the helpers at the top of each test method. Each call writes an invisible `XCTActivity` into the `.xcresult` bundle; the converter reads them and produces the matching Allure metadata.

```swift
import XCTest
import AllureSwiftXCTest

final class CheckoutTests: XCTestCase {

    func testHappyPath() throws {
        // Identity & labels
        allureId(1234)
        allureName("Checkout — happy path")
        allureEpic("Cart")
        allureFeature("Checkout")
        allureStory("Place order")
        allureSeverity(.critical)
        allureOwner("b.lysikov")
        allureTag("smoke")
        allureLayer("api")

        // Links
        allureTms(name: "PROJ-42", url: "https://jira.example.com/PROJ-42")
        allureIssue(name: "BUG-7", url: "https://jira.example.com/BUG-7")

        // Steps
        let cart = try allureStep("Open cart") {
            try openCart()
        }
        try allureStep("Add item") {
            try cart.addItem("Widget")
        }
        try allureStep("Place order") {
            let order = try cart.checkout()
            XCTAssertEqual(order.status, .confirmed)
        }
    }
}
```

### Available helpers

| Method | Allure effect |
|--------|---------------|
| `allureId(_ id: Int/String)` | `AS_ID` label |
| `allureName(_ name: String)` | Overrides test name in report |
| `allureDescription(_ text: String)` | Test description |
| `allureSeverity(_ level: AllureSeverity)` | `severity` label (`blocker/critical/normal/minor/trivial`) |
| `allureEpic(_ value: String)` | `epic` label |
| `allureFeature(_ value: String)` | `feature` label |
| `allureStory(_ value: String)` | `story` label |
| `allureOwner(_ value: String)` | `owner` label |
| `allureTag(_ value: String)` | `tag` label |
| `allureLayer(_ value: String)` | `layer` label |
| `allureSuite/ParentSuite/SubSuite(_ value: String)` | suite hierarchy labels |
| `allureLabel(_ name: String, value: String)` | Arbitrary label |
| `allureLink(name:url:type:)` | Generic link |
| `allureIssue(name:url:)` | Issue tracker link |
| `allureTms(name:url:)` | TMS link |
| `allureStep(_ name:) { … }` | Named step with pass/fail status |
| `allureAttachment(name:data:type:)` | Binary attachment |
| `allureAttachment(name:string:type:)` | Text attachment |

Steps nest naturally — calling `allureStep` inside another `allureStep` produces a sub-step tree in the report.

## Metadata conventions

You can also attach Allure metadata **without a library dependency** by encoding it directly in the test name. The label extractor recognises two notations and uses whichever fits the framework you're writing tests in.

### Recognised prefixes

| Prefix         | Allure label  |
|----------------|---------------|
| `AllureID`     | `AS_ID`       |
| `Epic`         | `epic`        |
| `Feature`      | `feature`     |
| `Story`        | `story`       |
| `Severity`     | `severity`    |
| `Owner`        | `owner`       |
| `Tag`          | `tag`         |
| `Layer`        | `layer`       |
| `Lead`         | `lead`        |
| `Suite`, `ParentSuite`, `SubSuite` | `suite`, `parentSuite`, `subSuite` |

Prefixes are matched case-insensitively. Anything that doesn't start with a recognised prefix is ignored, so existing test names keep working.

### XCTest (`func test…()`)

XCTest test methods are Swift identifiers — only letters, digits, and `_` are legal. Use the **camelCase** form: append the value directly to the prefix, separate tokens with `_`.

```swift
import XCTest

final class CheckoutTests: XCTestCase {
    /// AllureID 1234, epic = Cart, feature = Checkout, severity = critical
    func testHappyPath_EpicCart_FeatureCheckout_SeverityCritical_AllureID1234() {
        // …
    }

    /// Tag-only example
    func testEmptyState_TagSmoke_OwnerBLysikov() {
        // …
    }
}
```

Greedy match picks the longest known prefix, so `AllureID1234` resolves to `AllureID = 1234` (not `Allure` + `ID1234`).

### Swift Testing (`@Test`)

Swift Testing accepts a free-form display name, so the cleaner **dashed** form works there. Either put the metadata inside the `@Test(…)` string or attach it via `.tags(...)`.

```swift
import Testing

@Suite("Checkout")
struct CheckoutTests {

    @Test("Happy path Epic-Cart Feature-Checkout Severity-critical AllureID-1234")
    func happyPath() async throws {
        // …
    }

    // Tags work too — each tag value is parsed independently.
    @Test("Empty state", .tags(.epicCart, .severityMinor))
    func emptyState() async throws {
        // …
    }
}

extension Tag {
    @Tag static var epicCart: Self          // value reported as "epicCart"
    @Tag static var severityMinor: Self     // value reported as "severityMinor"
}
```

If you prefer dashed values in tags (`"Epic-Cart"`), you can write a literal-string tag — both notations are accepted in tag values.

### Result

After conversion, each test result carries the labels you embedded plus the always-emitted `testClass`, `testMethod`, `framework` (`XCTest`), `language` (`swift`), `package`, and `host`. Tests without any tokens still produce valid Allure results — they just lack the optional labels.

## Output layout

Per Allure 2 spec, the output directory contains:

| File                          | Contents                          |
|-------------------------------|-----------------------------------|
| `<uuid>-result.json`          | One per test case                 |
| `<uuid>-container.json`       | One per fixture container (future)|
| `<uuid>-attachment.<ext>`     | One per copied attachment         |
| `environment.properties`      | Device / OS / build identifiers   |

The UUID is generated fresh per run. `historyId` is a SHA-256 of the full test name, so trend data is stable across runs.

## Library usage (advanced)

If you want to embed conversion inside a larger Swift tool:

```swift
import AllureXCResult

let converter = try Converter(
    bundleURL: URL(fileURLWithPath: "Build/test.xcresult"),
    outputDir: URL(fileURLWithPath: "allure-results"),
    options: ConverterOptions(includeAttachments: true, cleanOutputDirectory: true)
)
let result = try converter.run()
print("Wrote \(result.testsConverted) tests")
```

`XCResultParser` exposes the lower-level Codable schema (`TestsTree`, `TestSummary`, `TestDetails`, `TestActivities`, `AttachmentManifest`) and a Process wrapper (`XCResultTool`) if you need direct access to `xcresulttool` output.

## Migration from v1

v1 was a runtime SDK with `Allure.step`, `@Test(.allure)` traits, `AllureXCTest.bootstrap()`, `AllureTestCase`, etc. v2 is a clean break.

**Migration steps:**

1. **Remove** `AllureSwift`, `AllureSwiftCore` (v1), `AllureSwiftXCTest` (v1), `AllureSwiftTesting` from your `Package.swift` test target dependencies. Drop the umbrella import lines from your test files.
2. **Remove** old runtime calls: `Allure.step(...)`, `Allure.parameter(...)`, the `.allure` trait on `@Test`, the `AllureTestCase` base class, `AllureXCTest.bootstrap()` calls.
3. **Add** the v2 package dependency (see Install).
4. **Add** `-resultBundlePath Build/test.xcresult` to your `xcodebuild test` invocation.
5. **Add** an `allure-xcresult convert …` step after the test run.
6. **Optional:** add `AllureSwiftXCTest` (v2) as a test target dependency and replace old `Allure.step(...)` calls with the new `allureStep(...)` helpers.

XCUI test activities (button taps, swipes, assertions) become Allure steps automatically — no step annotations needed for UI tests.

## License

MIT — see `LICENSE`.
