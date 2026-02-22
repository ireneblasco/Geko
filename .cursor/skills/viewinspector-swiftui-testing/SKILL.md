---
name: viewinspector-swiftui-testing
description: Write and fix ViewInspector unit tests for SwiftUI views. Use when testing SwiftUI views, adding ViewInspector tests, debugging failing ViewInspector assertions, or when the user mentions ViewInspector, SwiftUI testing, or view inspection.
---

# ViewInspector SwiftUI Testing

## Quick Start

- **Setup:** Add ViewInspector to the **test target only** via SPM: `https://github.com/nalexn/ViewInspector`
- **Import:** `import ViewInspector`
- **Basic pattern:** `view.inspect()` → traverse → read/trigger

## Critical Rules

**@MainActor:** Always annotate ViewInspector tests with `@MainActor` — otherwise crashes with `EXC_BREAKPOINT` when `MainActor.assumeIsolated` runs on a background thread.

**Swift 6 / Xcode 16:** Use `.implicitAnyView()` before `.text()` (or other view accessors) when the direct path fails — Swift 6 inserts implicit `AnyView` wrappers in the hierarchy.

## Common Patterns

| Pattern | Example |
|---------|---------|
| Find by text | `try view.inspect().find(text: "xyz")` |
| Find button by label | `try view.inspect().find(button: "Label")` |
| Find by type | `try view.inspect().find(ViewType.Text.self)` |
| Find by condition | `try view.inspect().find(ViewType.Text.self, where: { try $0.string() == "abc" })` |
| Read text | `try view.inspect().implicitAnyView().text().string()` |
| Tap button | `try view.inspect().find(button: "Label").tap()` |
| Custom view state | `try view.inspect().find(CustomView.self).actualView()` |

## Find Functions

```swift
.find(text: "xyz")                    // returns Text
.find(button: "xyz")                  // returns Button (label contains Text("xyz"))
.find(viewWithId: 7)                  // view with .id(7)
.find(viewWithTag: "Home")            // view with .tag("Home")
.find(ViewType.HStack.self)           // first HStack
.find(CustomView.self)                // custom view type
.find(viewWithAccessibilityLabel: "Play button")
.find(viewWithAccessibilityIdentifier: "play_button")
.find(ViewType.Text.self, where: { try $0.string() == "abc" })
.find(textWhere: { _, attr in try attr.font() == .footnote })
```

## findAll and pathToRoot

```swift
let texts = try view.inspect().findAll(ViewType.Text.self).map { try $0.string() }
// findAll returns all matches; empty array if none (does not throw)

// Debug when inspection fails:
print(try view.inspect().find(text: "123").pathToRoot)
```

## Examples from ViewInspector Source

**Basic inspection (guide.md):**

```swift
let sut = ContentView()
let value = try sut.inspect().implicitAnyView().text().string()
XCTAssertEqual(value, "Hello, world!")
```

**Traversing HStack with AnyView (guide.md):**

```swift
let view = MyView()
let okText = try view.inspect().implicitAnyView().hStack().anyView(1).view(OtherView.self).text()
```

**VStack of texts (nalexn/swiftui-unit-testing):**

```swift
let view = VStack { Text("1"); Text("2"); Text("3") }
let values = try view.inspect().map { try $0.text().string() }
XCTAssertEqual(values, ["1", "2", "3"])
```

**@Binding test — no @State needed (guide.md):**

```swift
let flag = Binding<Bool>(wrappedValue: false)
let sut = ContentView(binding: flag)
try sut.inspect().button().tap()
XCTAssertTrue(flag.wrappedValue)
```

**Custom view state via actualView() (guide.md):**

```swift
let sut = try view.inspect().find(CustomView.self).actualView()
XCTAssertTrue(sut.viewModel.isUserLoggedIn)
```

**List and callOnAppear (guide.md):**

```swift
let list = try view.inspect().list()
try list[5].view(RowItemView.self).callOnAppear()
```

**parent() for navigating up (guide.md):**

```swift
let text = try sut.inspect().find(text: "abc")
let hStack = try text.parent().hStack()
let anyView = try text.find(ViewType.AnyView.self, relation: .parent)
```

**Debugging with Inspector.print (InspectorTests):**

```swift
print(Inspector.print(view))
// Or: po Inspector.print(view) in LLDB
```

## Troubleshooting

- **View not found:** Try `.implicitAnyView()` before the accessor; check that the view is actually rendered (e.g. not inside `if false`)
- **Tap fails / type mismatch:** For Swift 6, `find(button:)` returns an inspectable that supports `.tap()`; avoid chaining `.button().tap()` if it causes type errors
- **watchOS:** Limited support. See ViewInspector's [guide_watchOS.md](guide_watchOS.md) for watchOS-specific setup
- **Debug path:** Use `pathToRoot` or `Inspector.print(view)` to inspect the hierarchy when tests fail

## Additional Resources

- For full API coverage, see [reference.md](reference.md)
