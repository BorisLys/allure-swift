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
| XCTest (UI tests, unit tests) | `AllureSwiftXCTest` |
| Swift Testing (unit tests) | `AllureSwiftTesting` |

---

## XCTest usage

```swift
import XCTest
import AllureSwiftXCTest

final class CheckoutTests: XCTestCase {

    func testHappyPath() throws {
        allureId(1234)
        allureName("Successful checkout flow")
        allureEpic("Cart")
        allureFeature("Checkout")
        allureSeverity(.critical)
        allureOwner("qa@example.com")
        allureTag("smoke")
        allureLabel("microservice", value: "payment-service")

        allureStep("Open cart") {
            // …
        }
        allureStep("Tap checkout") {
            // …
        }
    }
}
```

### Available methods

| Method | Description |
|---|---|
| `allureId(_ id: Int/String)` | Link to test management entry |
| `allureName(_ name: String)` | Override test name in report |
| `allureDescription(_ text: String)` | Test description |
| `allureSeverity(_ level: Severity)` | `.blocker` `.critical` `.normal` `.minor` `.trivial` |
| `allureEpic(_ value: String)` | Epic label |
| `allureFeature(_ value: String)` | Feature label |
| `allureStory(_ value: String)` | Story label |
| `allureOwner(_ value: String)` | Owner label |
| `allureTag(_ value: String)` | Tag label |
| `allureLayer(_ value: String)` | Layer label |
| `allureSuite(_ value: String)` | Suite label |
| `allureParentSuite(_ value: String)` | Parent suite label |
| `allureSubSuite(_ value: String)` | Sub-suite label |
| `allureLabel(_ name:value:)` | Arbitrary label |
| `allureLink(name:url:type:)` | Generic link |
| `allureIssue(name:url:)` | Issue tracker link |
| `allureTms(name:url:)` | TMS link |
| `allureStep(_ name:) { }` | Wrap code in a named step |
| `allureAttachment(name:data:type:)` | Attach binary data |
| `allureAttachment(name:string:type:)` | Attach text |

---

## Swift Testing usage

```swift
import Testing
import AllureSwiftTesting

@Suite(.parentSuite("Billing"))
struct CheckoutTests {

    @Test(
        .allureId(1234),
        .allureName("Successful checkout flow"),
        .epic("Cart"),
        .feature("Checkout"),
        .severity(.critical),
        .owner("qa@example.com"),
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
| `.allureName(_ name:)` | Override test name in report |
| `.allureDescription(_ text:)` | Test description |
| `.severity(_ level:)` | `.blocker` `.critical` `.normal` `.minor` `.trivial` |
| `.epic(_ value:)` | Epic label |
| `.feature(_ value:)` | Feature label |
| `.story(_ value:)` | Story label |
| `.owner(_ value:)` | Owner label |
| `.allureTag(_ value:)` | Tag label |
| `.layer(_ value:)` | Layer label |
| `.suite(_ value:)` | Suite label |
| `.parentSuite(_ value:)` | Parent suite label |
| `.subSuite(_ value:)` | Sub-suite label |
| `.allureLabel(_ name:value:)` | Arbitrary label |
| `.link(name:url:type:)` | Generic link |
| `.issue(name:url:)` | Issue tracker link |
| `.tms(name:url:)` | TMS link |

---

## Full pipeline

### 1. Run tests and save xcresult

```bash
xcodebuild test \
  -project MyApp.xcodeproj \
  -scheme MyAppUITests \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -resultBundlePath test.xcresult
```

### 2. Convert xcresult → Allure JSON

Use [xcresults](https://github.com/eroshenkoam/xcresults) by Artem Eroshenko:

```bash
# Install
brew install eroshenkoam/tap/xcresults

# Convert
xcresults convert test.xcresult --output allure-results
```

### 3. Generate Allure report

```bash
allure generate allure-results --output allure-report --clean
allure open allure-report
```

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
