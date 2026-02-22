# Debug Menu

Debug-only toolbar button that opens an action sheet with development utilities. Visible only in debug builds; compiled out of Release via `#if DEBUG`.

## Visibility

- **When:** Debug builds only (Xcode Debug configuration)
- **Release:** Button and action sheet are not compiled into the app

## Location

Ladybug icon in the top-right toolbar, to the left of the Add Habit (plus) button on the main Habits screen.

## Behavior

Tapping the ladybug opens a confirmation dialog (action sheet) titled "Debug" with:

- **Build number** — Displays the app's `CFBundleVersion` (from `CURRENT_PROJECT_VERSION`)
- **Show Feedback** — Presents the feedback sheet (enjoy prompt, review CTA, feedback form) for testing
- **Cancel** — Dismisses the dialog

## Future Options

The action sheet can be extended with additional debug actions, for example:

- Reset feedback state (clear "already asked" flag for testing)
- Export data / database dump
- Toggle feature flags

## Implementation Files

| File | Purpose |
|------|---------|
| `Geko/ContentView.swift` | Ladybug button in toolbar, `showingDebugSheet` state, `.confirmationDialog` |
