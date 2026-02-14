# Geko API Reference

Comprehensive API documentation for Geko's key classes, methods, and protocols.

## Table of Contents

- [Core Data Model](#core-data-model)
  - [Habit](#habit)
- [Sync Management](#sync-management)
  - [SyncManager](#syncmanager)
  - [WatchConnectivityManager](#watchconnectivitymanager)
- [Data Container](#data-container)
  - [SharedDataContainer](#shareddatacontainer)
- [UI Components](#ui-components)
- [Enums & Types](#enums--types)

---

## Core Data Model

### Habit

**Location:** `GekoShared/Habit.swift`

The core data model representing a single habit. Marked as SwiftData `@Model` for automatic persistence and CloudKit sync.

#### Properties

```swift
@Model
public final class Habit {
    public var name: String                          // Habit name
    public var emoji: String                         // Display emoji
    public var color: HabitColor                     // Display color
    public var dailyTarget: Int                      // Completions needed per day (1-20)
    
    // Completion tracking (internal storage)
    private var completedDaysStorage: [String]       // ISO-8601 date strings for simple habits
    public var dailyCompletionCounts: [String: Int]  // Date → count for multi-target habits
    
    // Reminders
    public var remindersEnabled: Bool                // Whether reminders are active
    public var reminderTimes: [Date]                 // Times of day for notifications
    public var reminderMessage: String?              // Custom notification message
}
```

#### Initializers

```swift
// Default initializer (required for CloudKit)
public init()

// Full initializer
public init(
    name: String,
    emoji: String,
    color: HabitColor,
    dailyTarget: Int = 1,
    remindersEnabled: Bool = false,
    reminderTimes: [Date] = [],
    reminderMessage: String? = nil
)
```

#### Computed Properties

##### `completedDays`

```swift
public var completedDays: Set<String> { get set }
```

Provides a Set-like interface to `completedDaysStorage`. Used for simple habits with `dailyTarget = 1`.

**Returns:** Set of ISO-8601 date strings (e.g., `"2025-02-14"`)

#### Static Methods

##### `isoDay(for:in:)`

```swift
public static func isoDay(
    for date: Date = .now,
    in calendar: Calendar = .current
) -> String
```

Converts a `Date` to ISO-8601 date string format.

**Parameters:**
- `date` - The date to convert (defaults to current date)
- `calendar` - Calendar for date components (defaults to `.current`)

**Returns:** ISO-8601 formatted date string `"YYYY-MM-DD"`

**Example:**
```swift
let key = Habit.isoDay(for: Date())  // "2025-02-14"
```

#### Instance Methods - Completion Queries

##### `completionCount(on:calendar:)`

```swift
public func completionCount(
    on date: Date = .now,
    calendar: Calendar = .current
) -> Int
```

Returns the current completion count for a specific date.

**Parameters:**
- `date` - Date to check (defaults to today)
- `calendar` - Calendar for date normalization

**Returns:** Count from 0 to `dailyTarget`

**Example:**
```swift
let count = habit.completionCount(on: Date())  // 3
```

---

##### `completionProgress(on:calendar:)`

```swift
public func completionProgress(
    on date: Date = .now,
    calendar: Calendar = .current
) -> Double
```

Returns completion progress as a percentage.

**Returns:** Value between 0.0 (no completions) and 1.0 (fully completed)

**Example:**
```swift
// For habit with dailyTarget = 8 and 6 completions
let progress = habit.completionProgress()  // 0.75
```

---

##### `isCompleted(on:calendar:)`

```swift
public func isCompleted(
    on date: Date = .now,
    calendar: Calendar = .current
) -> Bool
```

Checks if habit is fully completed for the date.

**Returns:** `true` if `completionCount >= dailyTarget`

---

##### `isPartiallyCompleted(on:calendar:)`

```swift
public func isPartiallyCompleted(
    on date: Date = .now,
    calendar: Calendar = .current
) -> Bool
```

Checks if habit has partial progress (not zero, but not fully completed).

**Returns:** `true` if `0 < completionCount < dailyTarget`

#### Instance Methods - Completion Modifications

##### `incrementCompletion(on:calendar:)`

```swift
public func incrementCompletion(
    on date: Date = .now,
    calendar: Calendar = .current
)
```

Increments completion count by 1 (up to `dailyTarget`).

**Behavior:**
- For `dailyTarget = 1`: Adds date to `completedDays` set
- For `dailyTarget > 1`: Increments `dailyCompletionCounts[date]`
- Stops at `dailyTarget` (won't increment beyond)

**Example:**
```swift
habit.incrementCompletion()  // Count: 0 → 1
habit.incrementCompletion()  // Count: 1 → 2
```

---

##### `toggleCompleted(on:calendar:)`

```swift
public func toggleCompleted(
    on date: Date = .now,
    calendar: Calendar = .current
)
```

Toggles between no completions (0) and full completion (`dailyTarget`).

**Legacy method** - Maintained for backward compatibility.

**Behavior:**
- If `completionCount >= dailyTarget`: Reset to 0
- Otherwise: Set to `dailyTarget`

---

##### `resetCompletion(on:calendar:)`

```swift
public func resetCompletion(
    on date: Date = .now,
    calendar: Calendar = .current
)
```

Resets completion count to 0 for the specified date.

#### Instance Methods - Reminder Management

##### `scheduleReminders()`

```swift
public func scheduleReminders() async
```

Requests notification permission and schedules all reminder notifications.

**Behavior:**
1. Requests `UNUserNotificationCenter` authorization
2. Cancels existing reminders for this habit
3. Creates daily repeating notifications at each `reminderTime`
4. Uses `UNCalendarNotificationTrigger` for daily recurrence

**Async** - Must be called with `await` or `Task`

**Example:**
```swift
habit.remindersEnabled = true
habit.reminderTimes = [date1, date2]
await habit.scheduleReminders()
```

---

##### `cancelReminders()`

```swift
public func cancelReminders() async
```

Cancels all pending notifications for this habit.

---

##### `updateReminders()`

```swift
public func updateReminders() async
```

Updates reminders based on current `remindersEnabled` state.

**Behavior:**
- If `remindersEnabled = true`: Schedules reminders
- If `remindersEnabled = false`: Cancels reminders

**Use when:** Habit properties change (name, emoji, reminder times, etc.)

---

## Sync Management

### SyncManager

**Location:** `GekoShared/SyncManager.swift`

Singleton class orchestrating multi-strategy sync. Detects available sync methods and delegates to appropriate handlers.

#### Singleton Instance

```swift
public static let shared = SyncManager()
```

#### Published Properties

```swift
@Published public var syncStatus: SyncStatus       // Current sync mode
@Published public var lastSyncDate: Date?          // Last successful sync
@Published public var isSyncing: Bool              // Active sync indicator
```

#### Methods

##### `setModelContext(_:)`

```swift
public func setModelContext(_ context: ModelContext)
```

Configures the SwiftData context for sync operations.

**Parameters:**
- `context` - The main `ModelContext` from the app

**Usage:** Call once during app initialization

```swift
SyncManager.shared.setModelContext(modelContext)
```

---

##### `updateSyncStatus()`

```swift
public func updateSyncStatus()
```

Checks CloudKit and Watch Connectivity availability and updates `syncStatus`.

**Sync Status Logic:**
- `hybridSync` - Both CloudKit and Watch Connectivity available
- `cloudKitOnly` - Only CloudKit available (Watch not reachable)
- `watchOnly` - Only Watch Connectivity available (iCloud signed out)
- `localOnly` - Neither available (App Groups only)
- `offline` - No sync capability

**Called automatically on:**
- Manager initialization
- Watch Connectivity status changes

---

##### `syncHabitUpdate(_:)`

```swift
public func syncHabitUpdate(_ habit: Habit)
```

Syncs habit creation or modification.

**Parameters:**
- `habit` - The habit to sync

**Behavior by sync status:**
- `hybridSync` - Watch Connectivity (immediate) + CloudKit (automatic)
- `cloudKitOnly` - CloudKit only (automatic via SwiftData)
- `watchOnly` - Watch Connectivity only
- `localOnly` / `offline` - Local App Group only

**Usage:**
```swift
// After creating or modifying a habit
habit.name = "New Name"
try context.save()
SyncManager.shared.syncHabitUpdate(habit)
```

---

##### `syncHabitCompletion(habitName:date:isCompleted:completionCount:)`

```swift
public func syncHabitCompletion(
    habitName: String,
    date: Date,
    isCompleted: Bool,
    completionCount: Int
)
```

Syncs completion status change.

**Parameters:**
- `habitName` - Name of the habit
- `date` - Date of completion
- `isCompleted` - Whether fully completed
- `completionCount` - Current completion count

**Usage:**
```swift
habit.incrementCompletion()
try context.save()
SyncManager.shared.syncHabitCompletion(
    habitName: habit.name,
    date: Date(),
    isCompleted: habit.isCompleted(),
    completionCount: habit.completionCount()
)
```

---

##### `syncHabitDeletion(habitName:habitId:)`

```swift
public func syncHabitDeletion(
    habitName: String,
    habitId: Int
)
```

Syncs habit deletion.

**Parameters:**
- `habitName` - Name of deleted habit
- `habitId` - Hash of habit's persistent model ID

**Usage:**
```swift
let habitId = habit.persistentModelID.hashValue
context.delete(habit)
try context.save()
SyncManager.shared.syncHabitDeletion(
    habitName: habitName,
    habitId: habitId
)
```

---

##### `requestFullSync()`

```swift
public func requestFullSync()
```

Requests a full sync of all habits.

**Behavior:**
- Sets `isSyncing = true`
- Delegates to appropriate sync method based on status
- Resets `isSyncing = false` after 2 seconds
- Updates `lastSyncDate`

**Usage:** Manual sync button or app launch

---

#### Computed Properties

##### Sync Availability Checks

```swift
public var isCloudKitAvailable: Bool              // CloudKit enabled
public var isWatchConnectivityAvailable: Bool     // Watch reachable
public var hasOptimalSync: Bool                   // Hybrid sync active
public var hasAnySyncCapability: Bool             // Any sync available
```

##### User-Facing Descriptions

```swift
public var syncStatusDescription: String          // Human-readable status
public var syncCapabilities: [String]             // List of capabilities
public var syncPriority: String                   // Brief priority description
```

**Example:**
```swift
Text(SyncManager.shared.syncStatusDescription)
// "⚡ Optimal sync: Instant Watch updates + iCloud persistence"
```

---

### WatchConnectivityManager

**Location:** `GekoShared/WatchConnectivityManager.swift`

Singleton class managing Watch Connectivity (WCSession) for real-time iPhone ↔ Watch sync.

#### Singleton Instance

```swift
public static let shared = WatchConnectivityManager()
```

#### Published Properties

```swift
@Published public var isConnected: Bool            // WCSession activated
@Published public var isReachable: Bool            // Counterpart reachable
```

#### Methods

##### `setModelContext(_:)`

```swift
public func setModelContext(_ context: ModelContext)
```

Sets the SwiftData context for handling incoming sync messages.

---

##### `syncHabitUpdate(_:)`

```swift
public func syncHabitUpdate(_ habit: Habit)
```

Sends habit creation/modification via Watch Connectivity.

**Message Format:**
```swift
[
    "action": "habitUpdate",
    "habitId": Int,
    "name": String,
    "emoji": String,
    "colorRawValue": String,
    "dailyTarget": Int,
    "completedDays": [String],
    "dailyCompletionCounts": [String: Int],
    "remindersEnabled": Bool,
    "reminderMessage": String
]
```

**Behavior:**
- Checks `WCSession.default.isReachable` before sending
- Sends via `sendMessage(_:replyHandler:errorHandler:)`
- Logs errors if send fails

---

##### `syncHabitCompletion(habitName:date:isCompleted:completionCount:)`

```swift
public func syncHabitCompletion(
    habitName: String,
    date: Date,
    isCompleted: Bool,
    completionCount: Int
)
```

Sends completion status change via Watch Connectivity.

**Message Format:**
```swift
[
    "action": "habitCompletion",
    "habitName": String,
    "date": String,  // ISO8601 format
    "isCompleted": Bool,
    "completionCount": Int
]
```

---

##### `syncHabitDeletion(habitName:habitId:)`

```swift
public func syncHabitDeletion(
    habitName: String,
    habitId: Int
)
```

Sends habit deletion via Watch Connectivity.

**Message Format:**
```swift
[
    "action": "habitDeletion",
    "habitName": String,
    "habitId": Int
]
```

---

##### `requestFullSync()`

```swift
public func requestFullSync()
```

Requests counterpart to send all habits.

**Message Format:**
```swift
["action": "requestFullSync"]
```

**Behavior:** Counterpart responds by sending all habits via `syncHabitUpdate(_:)`

---

#### WCSessionDelegate Implementation

Automatically handles incoming messages:

- `"habitUpdate"` - Creates/updates habit in local ModelContext
- `"habitCompletion"` - Updates completion status in local ModelContext
- `"habitDeletion"` - Deletes habit from local ModelContext
- `"requestFullSync"` - Sends all habits to counterpart

**Notifications:**
- Posts `"WatchConnectivityStatusChanged"` when reachability changes
- `SyncManager` observes this to update sync status

---

## Data Container

### SharedDataContainer

**Location:** `GekoShared/GekoShared.swift`

Singleton managing the shared SwiftData `ModelContainer` with App Group and CloudKit support.

#### Singleton Instance

```swift
public static let shared = SharedDataContainer()
```

#### Properties

##### `appGroupIdentifier`

```swift
public static let appGroupIdentifier = "group.com.irenews.geko"
```

App Group identifier for data sharing between targets.

##### `modelContainer`

```swift
public lazy var modelContainer: ModelContainer
```

Shared ModelContainer with CloudKit support (or local-only fallback).

**Initialization Logic:**
1. Attempts to create ModelContainer with CloudKit enabled
2. On failure, creates local-only ModelContainer
3. Uses App Group shared store URL for all targets

**Usage:**
```swift
let container = SharedDataContainer.shared.modelContainer
let context = ModelContext(container)
```

---

## UI Components

Key reusable UI components in `GekoShared`:

### Form Components

- **`HabitEditorForm`** - Shared form for creating/editing habits
- **`EmojiCatalogPicker`** - Emoji selection grid
- **`ColorPickerGrid`** - Color selection grid

### Display Components

- **`HabitRing`** - Circular progress ring showing completion percentage
- **`ViewModeToggleBar`** - Segmented control for Weekly/Monthly/Yearly modes
- **`SyncStatusView`** - Displays current sync status with icon

### Summary Views

- **`WeekSummary`** - 7-day rolling completion view
- **`MonthSummary`** - Monthly calendar grid
- **`YearSummary`** - 53-week year grid
- **`YearHabitGrid`** / **`ScrollableYearHabitGrid`** - Year view layouts
- **`YearDot`** - Individual day dot in year view

---

## Enums & Types

### SyncStatus

```swift
public enum SyncStatus {
    case hybridSync      // CloudKit + Watch Connectivity
    case cloudKitOnly    // CloudKit only
    case watchOnly       // Watch Connectivity only
    case localOnly       // App Groups only
    case offline         // No sync
}
```

### HabitColor

**Location:** `GekoShared/HabitColor.swift`

```swift
public enum HabitColor: String, Codable, CaseIterable {
    case blue
    case green
    case red
    case orange
    case purple
    case pink
    case yellow
    case teal
    // ... more colors
}
```

Provides SwiftUI `Color` via computed property:
```swift
public var color: Color {
    switch self {
    case .blue: return .blue
    // ...
    }
}
```

### ViewMode

**Location:** `GekoShared/ViewMode.swift`

```swift
public enum ViewMode: String, CaseIterable, Identifiable {
    case weekly
    case monthly
    case yearly
}
```

User-selectable view mode for habit summaries.

---

## Usage Examples

### Creating and Tracking a Habit

```swift
// Create habit
let habit = Habit(
    name: "Drink Water",
    emoji: "💧",
    color: .blue,
    dailyTarget: 8
)
context.insert(habit)
try context.save()

// Sync to other devices
SyncManager.shared.syncHabitUpdate(habit)

// Track completion
habit.incrementCompletion()
try context.save()

// Sync completion
SyncManager.shared.syncHabitCompletion(
    habitName: habit.name,
    date: Date(),
    isCompleted: habit.isCompleted(),
    completionCount: habit.completionCount()
)

// Check progress
let progress = habit.completionProgress()  // 0.125 (1/8)
let isComplete = habit.isCompleted()       // false
```

### Setting Up Reminders

```swift
// Configure reminders
habit.remindersEnabled = true
habit.reminderMessage = "Time to hydrate!"

// Add reminder times (e.g., 9 AM and 3 PM)
let calendar = Calendar.current
let morning = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
let afternoon = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: Date())!
habit.reminderTimes = [morning, afternoon]

// Schedule notifications
Task {
    await habit.scheduleReminders()
}
```

### Initializing Sync in App

```swift
// In your App struct
@main
struct GekoApp: App {
    let modelContainer = SharedDataContainer.shared.modelContainer
    
    init() {
        let context = ModelContext(modelContainer)
        SyncManager.shared.setModelContext(context)
        SyncManager.shared.requestFullSync()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
```

---

For architectural details and design decisions, see [ARCHITECTURE.md](ARCHITECTURE.md).
