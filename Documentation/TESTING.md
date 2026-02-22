# Geko Testing Guide

Overview of the testing setup for the Geko project.

## Test Targets

| Target | Purpose | Tests |
|--------|---------|-------|
| **GekoTests** | iOS app unit tests | Main app views, SwiftUI inspection with ViewInspector |
| **GekoUITests** | UI integration tests | End-to-end app flows |

## Test File Organization

| File | Focus |
|------|-------|
| `GekoTests.swift` | General tests, ViewInspector basics |
| `HabitTests.swift` | Habit model, creation, persistence |
| `WeekSummaryTests.swift` | WeekSummary view, day button taps |

## Running Tests

- **Xcode:** ⌘U to run all tests, or click the diamond next to a test to run it individually
- **Command line:** `xcodebuild -scheme Geko -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:GekoTests`

## App Host Model

Unit tests (GekoTests) use **Geko.app** as the test host. The app launches first, then the test bundle is injected and runs in the same process.

This is required for:

- `@testable import Geko` — app code must be loaded to test it
- Access to app context (SwiftData, environment, etc.)

The app launch is expected behavior when running unit tests.

## Swift Testing

Tests use the Swift Testing framework (`import Testing`):

- `@Test` — marks a test function
- `#expect(...)` — assertions
- `throws` — test fails automatically on thrown errors

```swift
@Test func example() async throws {
    #expect(1 + 1 == 2)
}
```

## ViewInspector

[ViewInspector](https://github.com/nalexn/ViewInspector) enables unit testing of SwiftUI views by inspecting the view hierarchy at runtime.

### Setup

- **Package:** Added via Swift Package Manager (`https://github.com/nalexn/ViewInspector`, 0.10.2+)
- **Targets:** Linked to GekoTests only (not the main app)

### Usage

**Import:** `import ViewInspector`

**Basic inspection:**

```swift
@Test @MainActor func viewInspectorInspectsText() throws {
    let view = Text("Hello, Geko!")
    let string = try view.inspect().implicitAnyView().text().string()
    #expect(string == "Hello, Geko!")
}
```

### Important: `@MainActor`

ViewInspector's internal view hosting requires main-actor isolation. **Always annotate ViewInspector tests with `@MainActor`** — otherwise they may crash with `EXC_BREAKPOINT` when `MainActor.assumeIsolated` is called from a background thread.

Model/data tests (e.g. `HabitTests`) do not need `@MainActor` unless they use `ModelContainer.mainContext` or other main-actor APIs.

```swift
@Test @MainActor func myViewInspectorTest() throws {
    // ViewInspector code here
}
```

### Swift 6 / Xcode 16: `implicitAnyView()`

Swift 6 inserts implicit `AnyView` wrappers in the view hierarchy. Use `.implicitAnyView()` before `.text()` (or other view accessors) when the direct path doesn't work:

```swift
try view.inspect().implicitAnyView().text().string()
```

### Common patterns

- **Find views:** `.find(text: "xyz")`, `.find(button: "Label")`, `.find(ViewType.Text.self)`
- **Find by condition:** `.find(ViewType.Text.self, where: { try $0.string() == "abc" })`
- **Trigger actions:** `.tap()` on buttons — `find(button:)` returns a Button directly, so `.tap()` works
- **Read state:** `.string()`, `.attributes().font()`, etc.

### Testing views with dependencies

Views that need `@Environment(\.modelContext)`, `@Bindable`, etc. require setup:

```swift
let container = try ModelContainer(for: schema, configurations: [config])
let view = MyView(habit: habit)
    .modelContainer(container)
    .environment(\.calendar, calendar)
    .environment(\.locale, Locale(identifier: "en_US"))
```

For full API coverage, see the [ViewInspector guide](https://github.com/nalexn/ViewInspector/blob/main/guide.md) and [readiness](https://github.com/nalexn/ViewInspector/blob/main/readiness.md).

## watchOS Testing

ViewInspector has limited support for watchOS. Testing watchOS views requires additional setup per the [guide_watchOS.md](https://github.com/nalexn/ViewInspector/blob/master/guide_watchOS.md). GekoTests targets the iOS app; watchOS-specific testing is not currently configured.

## SwiftData Testing

Use an in-memory container so tests don't affect real data:

```swift
let schema = Schema([Habit.self])
let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
let container = try ModelContainer(for: schema, configurations: [config])
let context = container.mainContext
```

`mainContext` is main-actor isolated — tests that use it need `@MainActor`.

## UI Tests

GekoUITests launch the app and drive it programmatically via XCTest. Use these for end-to-end flows (e.g., adding a habit, completing a day). UI tests run in a separate process from the app.

## Troubleshooting

- **"No matching device" / SimError 404:** The scheme is targeting a simulator that no longer exists. In Xcode, change the run destination (e.g. to iPhone 16) via the scheme selector next to the Run button.
