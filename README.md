# allure-swift

Runtime annotation library for [Allure](https://allurereport.org) test reports.  
Supports **XCTest** (UI and unit tests) and **Swift Testing** (unit tests).

Each annotation writes an `allure.*` activity entry into the `.xcresult` bundle.  
A post-process converter reads those entries and produces Allure JSON.

---

## Requirements

- Xcode 16+
- iOS 16+ / macOS 13+
- Swift 6

---

## Installation

Add the package in Xcode: **File → Add Package Dependencies**

```
https://github.com/BorisLys/allure-swift
```

| Test framework | Product to add |
|---|---|
| XCTest (UI tests, unit tests) | `AllureXCTest` |
| Swift Testing (unit tests) | `AllureSwiftTesting` |

---

## XCTest usage

```swift
import XCTest
import AllureXCTest

final class CheckoutTests: XCTestCase {

    func testHappyPath() throws {
        allureId(1234)
        name("Successful checkout flow")
        epic("Cart")
        feature("Checkout")
        severity(.critical)
        owner("qa@example.com")
        tag("smoke")
        label("microservice", value: "payment-service")

        step("Open cart") {
            // …
        }
        step("Tap checkout") {
            // …
        }
    }
}
```

### Available methods

| Method | Description |
|---|---|
| `allureId(_ id: Int/String)` | Link to test management entry |
| `name(_ name: String)` | Override test name in report |
| `description(_ text: String)` | Test description |
| `severity(_ level: Severity)` | `.blocker` `.critical` `.normal` `.minor` `.trivial` |
| `epic(_ value: String)` | Epic label |
| `feature(_ value: String)` | Feature label |
| `story(_ value: String)` | Story label |
| `owner(_ value: String)` | Owner label |
| `tag(_ value: String)` | Tag label |
| `layer(_ value: String)` | Layer label |
| `suite(_ value: String)` | Suite label |
| `parentSuite(_ value: String)` | Parent suite label |
| `subSuite(_ value: String)` | Sub-suite label |
| `label(_ name:value:)` | Arbitrary label |
| `link(name:url:type:)` | Generic link |
| `issue(name:url:)` | Issue tracker link |
| `tms(name:url:)` | TMS link |
| `step(_ name:) { }` | Wrap code in a named step |
| `attachment(name:data:type:)` | Attach binary data |
| `attachment(name:string:type:)` | Attach text |

---

## Swift Testing usage

```swift
import Testing
import AllureSwiftTesting

@Suite("Suite name",
       .epic("Epic"),
       .feature("Feature"),
       .story("Story"),
       .owner("Boris")
)
struct CheckoutTests {

    @Test("Happy path test",
        .allureId(1234),
        .severity(.critical),
        .allureTag("smoke"),
        .allureLabel("microservice", value: "payment-service")
    )
    func happyPath() async throws {
        // Steps are not supported in Swift Testing — use plain code.
    }
}
```

### Available traits

| Trait | Description |
|---|---|
| `.allureId(_ id:)` | Link to test management entry |
| `.description(_ text:)` | Test description |
| `.severity(_ level:)` | `.blocker` `.critical` `.normal` `.minor` `.trivial` |
| `.epic(_ value:)` | Epic label |
| `.feature(_ value:)` | Feature label |
| `.story(_ value:)` | Story label |
| `.owner(_ value:)` | Owner label |
| `.tag(_ value:)` | Tag label |
| `.layer(_ value:)` | Layer label |
| `.suite(_ value:)` | Suite label |
| `.label(_ name:value:)` | Arbitrary label |
| `.link(name:url:type:)` | Generic link |
| `.issue(name:url:)` | Issue tracker link |
| `.tms(name:url:)` | TMS link |

---

## CI/CD examples (GitHub Actions)

### Allure Report (self-hosted) via Allure 3

```yaml
- name: Run tests
  run: |
    xcodebuild test \
      -project MyApp.xcodeproj \
      -scheme MyAppUITests \
      -destination "platform=iOS Simulator,name=iPhone 16,OS=latest" \
      -resultBundlePath test.xcresult

- name: Convert xcresult to Allure
  run: xcresults export test.xcresult -o /allure-results

- name: Generate Allure 3 report
  run: npx allure generate allure-results --output allure-report --clean

- name: Upload report artifact
  uses: actions/upload-artifact@v4
  with:
    name: allure-report
    path: allure-report/
```

### Allure TestOps via allurectl

Add `ALLURE_ENDPOINT`, `ALLURE_TOKEN`, and `ALLURE_PROJECT_ID` to your repository secrets.

```yaml
- name: Run tests
  run: |
    xcodebuild test \
      -project MyApp.xcodeproj \
      -scheme MyAppUITests \
      -destination "platform=iOS Simulator,name=iPhone 16,OS=latest" \
      -resultBundlePath test.xcresult

- name: Convert xcresult to Allure
  run: xcresults export test.xcresult -o /allure-results

- name: Install allurectl
  run: |
    curl -fsSL https://github.com/allure-framework/allurectl/releases/latest/download/allurectl_darwin_amd64 \
      -o allurectl
    chmod +x allurectl

- name: Upload to Allure TestOps
  env:
    ALLURE_ENDPOINT: ${{ secrets.ALLURE_ENDPOINT }}
    ALLURE_TOKEN: ${{ secrets.ALLURE_TOKEN }}
    ALLURE_PROJECT_ID: ${{ secrets.ALLURE_PROJECT_ID }}
  run: |
    ./allurectl upload allure-results 
```

---

## License

MIT
