# allure-swift

A **post-process converter** that turns Apple's `.xcresult` bundles into [Allure 2](https://allurereport.org/) JSON results.

It runs **after** `xcodebuild test` finishes — no runtime hooks, no `XCTestObservation` quirks, no Swift Testing trait wiring, no iOS Simulator scheme/env-var fights. The `.xcresult` bundle is Apple's canonical test output, so reading it after the fact is the cleanest path to Allure reporting on Swift/Apple projects.

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

Run from anywhere inside the package:

```sh
swift package --allow-writing-to-directory allure-results \
    plugin allure-xcresult \
    convert Build/test.xcresult \
    --output allure-results
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

## Metadata conventions

Because the converter is post-process, you opt into Allure metadata by **naming** your tests. The label extractor scans each test method name (and, where available, Swift Testing `@Tag` values) for these patterns:

| Token in test name      | Allure label   |
|-------------------------|----------------|
| `AllureID-1234`         | `AS_ID = 1234` |
| `Epic-Cart`             | `epic`         |
| `Feature-Checkout`      | `feature`      |
| `Story-EmptyState`      | `story`        |
| `Severity-critical`     | `severity`     |
| `Owner-blysikov`        | `owner`        |
| `Tag-smoke`             | `tag`          |
| `Layer-unit`            | `layer`        |

Tokens are matched case-insensitively and separated by `_`, ` `, `,`, `;`, `/`. Either `-` or `=` works as the prefix/value delimiter.

**Example test method:**

```swift
func test_AllureID-1234_Epic-Cart_Feature-Checkout_Severity-critical_happyPath() { … }
```

After conversion, the result file carries four labels (`AS_ID`, `epic`, `feature`, `severity`) plus the always-emitted `testClass`, `testMethod`, `framework`, `language`, `package`, `host`.

Tests without any tokens still produce valid Allure results — they just won't have the optional labels.

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

v1 was a runtime SDK with `Allure.step`, `@Test(.allure)` traits, `AllureXCTest.bootstrap()`, etc. None of that survives v2.

To migrate:

1. **Remove** `AllureSwift`, `AllureSwiftCore`, `AllureSwiftXCTest`, `AllureSwiftTesting` from your `Package.swift` test target dependencies. Drop the umbrella import lines from your test files.
2. **Remove** runtime calls: `Allure.step(...)`, `Allure.parameter(...)`, the `.allure` trait on `@Test`, the `AllureTestCase` base class, `AllureXCTest.bootstrap()` calls.
3. **Add** the v2 package dependency (see Install).
4. **Add** `-resultBundlePath Build/test.xcresult` to your `xcodebuild test` invocation.
5. **Add** an `allure-xcresult convert …` step after the test run.

Steps you previously wrote with `Allure.step("Open cart")` are no longer needed — the converter pulls activities directly from `xcresult`, so XCUI test activities become Allure steps automatically.

## License

MIT — see `LICENSE`.
