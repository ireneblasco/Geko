# Geko

A native iOS and watchOS habit tracking app with seamless multi-device sync and Apple ecosystem integration.

## Features

- **Habit Tracking with Daily Targets** - Track simple daily habits or set custom completion targets (e.g., 8 glasses of water per day)
- **Multi-Device Sync** - Hybrid sync strategy combining CloudKit (cross-device persistence) and Watch Connectivity (real-time iPhone ↔ Watch updates)
- **Apple Watch Companion** - Full-featured Watch app for quick habit completions on the go
- **iOS Widgets** - Home screen widgets showing habit progress at a glance
- **Flexible View Modes** - View your progress in Weekly, Monthly, or Yearly formats
- **Smart Reminders** - Schedule daily notifications with custom messages to stay on track
- **Offline-First** - Works seamlessly offline with graceful sync fallbacks

## Tech Stack

- **Language:** Swift
- **UI Framework:** SwiftUI
- **Data Persistence:** SwiftData with CloudKit integration
- **Sync:** CloudKit + Watch Connectivity + App Groups
- **Platforms:** iOS 17+, watchOS 10+
- **Dependencies:** None - uses only Apple frameworks

## Project Structure

```
Geko/
├── Geko/              # iOS app target
├── GekoWatch/         # Apple Watch app target
├── GekoWidgets/       # Home screen widgets extension
├── GekoShared/        # Shared business logic and UI components
├── GekoTests/         # Unit tests
└── GekoUITests/       # UI tests
```

### Key Modules

- **Geko** - Main iOS application with habit management, multi-view modes, and reminders
- **GekoWatch** - Apple Watch companion app for quick habit tracking
- **GekoWidgets** - iOS widget extension with small, medium, and accessory widget support
- **GekoShared** - Shared module containing:
  - Core data model (`Habit`)
  - Sync orchestration (`SyncManager`, `WatchConnectivityManager`)
  - Shared UI components (emoji picker, color picker, progress rings, view mode selectors)
  - Data container with App Group support

## Quick Start

### Prerequisites

- Xcode 15.0 or later
- macOS 14.0 or later (for SwiftData support)
- iOS 17.0+ deployment target
- Apple Developer account (for CloudKit, Watch Connectivity, and device testing)
- Paired Apple Watch (optional, for Watch app testing)

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Geko
   ```

2. **Open the project**
   ```bash
   open Geko.xcodeproj
   ```

3. **Configure signing & capabilities**
   
   For all 4 targets (`Geko`, `GekoWatch`, `GekoWidgets`, `GekoShared`):
   - Set your development team in Signing & Capabilities
   - Ensure App Groups capability is enabled with: `group.com.irenews.geko`
   - Ensure CloudKit capability is enabled (container: `iCloud.com.irenews.geko` or your custom container)
   
   For the `Geko` target:
   - Enable Background Modes for notifications

4. **Build and run**
   - Select the `Geko` scheme and your target device/simulator
   - Press `Cmd+R` to build and run
   - For Watch app: Select `GekoWatch` scheme and run on paired Watch

### Running Different Targets

- **iOS App:** Select `Geko` scheme → Run on iPhone simulator or device
- **Watch App:** Select `GekoWatch` scheme → Run on paired Apple Watch
- **Widgets:** Build `GekoWidgets` target, then add widget from iOS home screen widget gallery

## Documentation

- **[CLAUDE.md](CLAUDE.md)** - Quick reference guide for AI agents working on the codebase
- **[Architecture Documentation](Documentation/ARCHITECTURE.md)** - System design, data flows, and architectural decisions
- **[API Reference](Documentation/API.md)** - Detailed API documentation for key classes and methods

## Testing

The project includes two test targets:

- **GekoTests** - Unit tests (run with `Cmd+U`)
- **GekoUITests** - UI tests for automated testing

Note: Testing CloudKit sync requires an Apple Developer account. Widget and Watch testing is best done on physical devices.

## Sync Architecture

Geko uses a sophisticated hybrid sync strategy:

- **CloudKit** - Automatic cross-device persistence via SwiftData
- **Watch Connectivity** - Real-time iPhone ↔ Watch sync when both devices are active
- **App Groups** - Shared data container enabling widget and Watch access
- **Graceful Fallbacks** - Works in cloudKitOnly, watchOnly, localOnly, and offline modes

See [Documentation/ARCHITECTURE.md](Documentation/ARCHITECTURE.md) for detailed sync flow diagrams and implementation details.

## License

[To be determined]

## Author

Created by Irenews
