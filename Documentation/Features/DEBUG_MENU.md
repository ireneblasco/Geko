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
- **Show Paywall** — Presents the paywall sheet for testing
- **Toggle Geko Plus** — Toggles the Plus entitlement for testing (shows current state: Free or Plus). Reloads widget timelines so widgets reflect the change immediately.
- **Bootstrap Sample Habits** — Creates 3 sample habits for debugging and screenshots (see below)
- **Hide debug button** — Hides the ladybug button until the app is restarted (for clean screenshots)
- **Cancel** — Dismisses the dialog

### Bootstrap Sample Habits

Creates 3 sample habits with varied completion profiles in the last 7 days. Useful for debugging, taking screenshots, and testing views with realistic data.

| Habit | Profile | Last 7 days |
|-------|---------|-------------|
| Drink Water (💧) | Multi-target (8 glasses/day), high consistency | 6 of 7 days with varying counts (4–8) |
| Journal (📓) | Simple daily, medium | 4 of 7 days completed |
| Exercise (💪) | Simple daily, different pattern | 4 of 7 days completed |

All three habits have at least some days checked in the last 7 days. Completion data uses deterministic patterns so screenshots are reproducible.

### Hide Debug Button

Hides the ladybug button from the toolbar. Use before taking screenshots so the debug UI is not visible. The button reappears when the app is restarted (state is in-memory only).

## Future Options

The action sheet can be extended with additional debug actions, for example:

- Reset feedback state (clear "already asked" flag for testing)
- Clear sample habits / remove bootstrap data
- Export data / database dump
- Toggle feature flags

## Implementation Files

| File | Purpose |
|------|---------|
| `Geko/ContentView.swift` | Ladybug button in toolbar, `showingDebugSheet` state, `.confirmationDialog` |
