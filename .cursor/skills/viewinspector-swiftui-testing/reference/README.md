# ViewInspector API Reference

Local copies of ViewInspector documentation (from v0.10.4).

## Documentation (local)

- [guide.md](../guide.md) — Inspection basics, find, attributes, @State/@Binding/@Environment, ViewModifier, async inspection
- [readiness.md](../readiness.md) — SwiftUI API coverage per view type
- [guide_styles.md](../guide_styles.md) — Style inspection
- [guide_gestures.md](../guide_gestures.md) — Gesture inspection
- [guide_popups.md](../guide_popups.md) — Alert, Sheet, ActionSheet, FullScreenCover, Popover
- [guide_watchOS.md](../guide_watchOS.md) — watchOS-specific setup
- [unsupported_swiftui_apis.md](../unsupported_swiftui_apis.md) — Known limitations

## ViewInspector Test Suite

Source examples from [Tests/ViewInspectorTests/](https://github.com/nalexn/ViewInspector/tree/main/Tests/ViewInspectorTests):

- **ViewSearchTests** — find, findAll, pathToRoot, accessibility
- **InspectorTests** — Inspector.print, parent(), pathToRoot, implicitAnyView
- **InspectionEmissaryTests** — @State, @Environment inspection with InspectionEmissary
- **ViewHostingTests** — async hosting, UIKit/SwiftUI mix
