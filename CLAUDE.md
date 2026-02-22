# Geko - AI Agent Reference

Quick reference guide for AI assistants working on the Geko codebase.

## Project Overview

**Geko** is an iOS/watchOS habit tracking app with multi-device sync capabilities.

- **Stack:** Swift, SwiftUI, SwiftData, CloudKit, Watch Connectivity, WidgetKit
- **Targets:** iOS app (`Geko`), Watch app (`GekoWatch`), Widgets (`GekoWidgets`), Shared module (`GekoShared`)
- **Platforms:** iOS 17+, watchOS 10+
- **No external dependencies** - Uses only Apple frameworks

## Quick Navigation

For detailed information, refer to:

- **Architecture & Sync Details** → [`Documentation/ARCHITECTURE.md`](Documentation/ARCHITECTURE.md)
- **API Reference** → [`Documentation/API.md`](Documentation/API.md)
- **Testing Setup** → [`Documentation/TESTING.md`](Documentation/TESTING.md)
- **Core Data Model** → [`GekoShared/Habit.swift`](GekoShared/Habit.swift)
- **Sync Orchestration** → [`GekoShared/SyncManager.swift`](GekoShared/SyncManager.swift)
- **Watch Sync Implementation** → [`GekoShared/WatchConnectivityManager.swift`](GekoShared/WatchConnectivityManager.swift)

## Key Patterns (Quick Reference)

### Data Persistence
- **SwiftData** with App Groups for data sharing: `group.com.irenews.geko`
- **Shared SQLite store:** `Geko.sqlite` in App Group container
- **CloudKit integration:** Automatic via `ModelConfiguration` (with local fallback)

### Date Handling
- **ISO-8601 format:** `"YYYY-MM-DD"` (e.g., `"2025-02-14"`)
- **Storage:** `completedDaysStorage` (for dailyTarget = 1) and `dailyCompletionCounts` dictionary (for dailyTarget > 1)
- **Date normalization:** Uses `Calendar.current.startOfDay(for:)` implicitly via `isoDay()`

### Sync Strategy
- **Hybrid approach:** CloudKit (cross-device) + Watch Connectivity (real-time) + App Groups (local sharing)
- **Five sync modes:** `hybridSync`, `cloudKitOnly`, `watchOnly`, `localOnly`, `offline`
- **Graceful degradation:** Falls back automatically based on available services

### Code Organization
- Uses `// MARK:` comments to organize sections
- Naming: camelCase for properties/methods, PascalCase for types
- Public APIs have docstrings (/// syntax)

## Critical Files Map

| File | Purpose | Key Responsibilities |
|------|---------|---------------------|
| `GekoShared/Habit.swift` | Core data model | SwiftData `@Model`, completion tracking, reminders |
| `GekoShared/SyncManager.swift` | Sync orchestration | Status detection, delegates to CloudKit/Watch sync |
| `GekoShared/WatchConnectivityManager.swift` | Watch sync | WCSession messaging for real-time iPhone ↔ Watch sync |
| `GekoShared/GekoShared.swift` | Data container | ModelContainer setup with App Group + CloudKit |
| `Geko/ContentView.swift` | iOS main view | Habit list with search, add/edit/delete |
| `Geko/HabitRow.swift` | iOS habit row | Displays habit with progress ring and view mode summary |
| `GekoWatch/ContentView.swift` | Watch main view | Watch habit list |
| `GekoWatch/HabitDetailView.swift` | Watch detail | Single habit view with completion tracking |
| `GekoWidgets/Provider.swift` | Widget timeline | AppIntentTimelineProvider, loads habits from shared container |
| `GekoWidgets/HabitWidgetView.swift` | Widget views | Small, medium, accessory widget layouts |

## Common Gotchas

⚠️ **All 4 targets need App Group entitlement:** `group.com.irenews.geko`
- iOS app, Watch app, Widgets, and Shared module all access the same data store

⚠️ **Date handling uses `isoDay()` helper:**
- Always use `Habit.isoDay(for:in:)` for consistent date string formatting
- Dates are normalized to start of day in the calendar's timezone

⚠️ **Widget updates require manual reload:**
- Call `WidgetCenter.shared.reloadAllTimelines()` after data changes
- Done automatically in Watch app's sync handlers

⚠️ **Sync changes require updating multiple files:**
- `SyncManager` - Orchestration logic
- `WatchConnectivityManager` - Actual WCSession message passing
- Both must be updated when adding new sync operations

⚠️ **SwiftData + CloudKit fallback:**
- `SharedDataContainer` tries CloudKit first, falls back to local-only on failure
- Check console for "CloudKit initialization failed" vs "Successfully initialized"

## When Making Changes

### Adding/Modifying Habit Properties
1. Update `Habit` model in [`GekoShared/Habit.swift`](GekoShared/Habit.swift)
2. Add sync support in [`GekoShared/SyncManager.swift`](GekoShared/SyncManager.swift)
3. Update Watch Connectivity messages in [`GekoShared/WatchConnectivityManager.swift`](GekoShared/WatchConnectivityManager.swift)
4. Update UI forms: `HabitEditorForm.swift`, `AddHabitView.swift`, `EditHabitView.swift`
5. Update widget views if property affects display

### Modifying Sync Logic
- See sync architecture in [`Documentation/ARCHITECTURE.md`](Documentation/ARCHITECTURE.md)
- Understand the five sync modes: hybrid, cloudKitOnly, watchOnly, localOnly, offline
- CloudKit sync is automatic via SwiftData; only Watch Connectivity needs manual implementation

### Adding New View Modes
1. Add case to `ViewMode` enum in [`GekoShared/ViewMode.swift`](GekoShared/ViewMode.swift)
2. Create summary component (see `WeekSummary.swift`, `MonthSummary.swift`, `YearSummary.swift`)
3. Update `HabitRow.swift` to display new summary
4. Update `ViewModeToggleBar.swift` if needed

### Modifying Widgets
1. Update timeline logic in [`GekoWidgets/Provider.swift`](GekoWidgets/Provider.swift)
2. Modify widget views: `HabitWidgetView.swift`, `SmallHabitWidgetView.swift`, `MediumHabitWidgetView.swift`
3. Test on device/simulator (widgets don't always update reliably in Xcode previews)
4. Ensure `WidgetCenter.shared.reloadAllTimelines()` is called after data changes

## Testing Considerations

- **CloudKit:** Requires Apple Developer account and proper entitlements
- **Watch Connectivity:** Best tested on paired physical devices (simulator pairing can be flaky)
- **Widgets:** Manual testing required; add widget to home screen to verify
- **Multi-device sync:** Test with multiple devices/simulators signed into same iCloud account
- **Offline mode:** Test airplane mode to verify graceful degradation

## Architecture at a Glance

```
┌─────────────────────────────────────────────────────────┐
│  iOS App (Geko)                                         │
│  - ContentView (habit list)                             │
│  - HabitRow (individual habit)                          │
│  - Add/Edit views                                       │
└────────────────┬────────────────────────────────────────┘
                 │
┌────────────────┼─────────────────┐   ┌─────────────────┐
│  Watch App     │                 │   │  Widgets        │
│  (GekoWatch)   │                 │   │  (GekoWidgets)  │
│  - ContentView │                 │   │  - Provider     │
│  - HabitDetail │                 │   │  - Widget Views │
└────────────────┼─────────────────┘   └────────┬────────┘
                 │                                │
                 ▼                                ▼
┌──────────────────────────────────────────────────────────┐
│  GekoShared Module                                       │
│  - Habit (data model)                                    │
│  - SyncManager (orchestration)                           │
│  - WatchConnectivityManager (Watch sync)                 │
│  - SharedDataContainer (data setup)                      │
│  - Shared UI components                                  │
└────────────────┬─────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────┐
│  Data Layer                                              │
│  ├─ SwiftData (local persistence)                        │
│  ├─ CloudKit (cross-device sync)                         │
│  └─ App Groups (widget/watch data sharing)               │
└──────────────────────────────────────────────────────────┘
```

For detailed architecture diagrams and sync flow, see [`Documentation/ARCHITECTURE.md`](Documentation/ARCHITECTURE.md).
