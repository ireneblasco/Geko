# Geko Releases

This document tracks release versions, in-scope features, and associated GitHub issues.

**Issues:** https://github.com/irenews/Geko/issues

---

## Release v1.0 (Alias: Newt)

**Platform:** iOS 17+
**Devices:** iPhone 15 Pro Max, iPhone 16
**Milestone:** [Newt (v1.0)](https://github.com/irenews/Geko/milestone/1) – First release to the App Store. Basic functionality matching competitor apps (iOS app with Widgets).

### In Scope
- Habits (#1) ✓
- Habit Editor (#4) ✓
- Weekly View (#2) ✓
- Grid View (#3) ✓
- iCloud syncing (#12) ✓
- Widgets for iOS (#9) ✓
- User subscriptions (#10)
- Onboarding (#8)

### Out of Scope
- Settings Pane (#7) → Axolotl
- Charts & Metrics (#5) → Basil
- Year Rewind (#6) → Basil
- Apple Watch Companion App (#14) → Axolotl
- Habit Card (#11) → Backlog


### Notes
- iOS-only for v1; Watch deferred.
- Free: 3 habits, 1 widget. Premium: unlimited.

---

## Release v2.0 (Alias: Axolotl)

**Platform:** iOS 17+, watchOS 10+
**Devices:** iPhone, Apple Watch
**Milestone:** [Axolotl](https://github.com/irenews/Geko/milestone/2) – The ability to use Geko from the Watch.

### In Scope
- Apple Watch Companion App (#14)
- Watch Complications (Companion App) (#15)
- Settings Pane (#7)
- App Reviews (#13)

### Out of Scope
- iPad / Mac → Basil
- Charts & Metrics (#5) → Basil
- Year Rewind (#6) → Basil

### Notes
- Single App Store listing; Watch app bundled with iOS app.
- Companion architecture: Watch Connectivity + App Groups + CloudKit.

---

## Release v3.0 (Alias: Basil)

**Platform:** iOS 17+, watchOS 10+, iPadOS 17+, macOS 14+ (Mac Catalyst)
**Devices:** iPhone, Apple Watch, iPad, Mac
**Milestone:** [Basil](https://github.com/irenews/Geko/milestone/3) – The ability to use Geko from macOS & iPad.

### In Scope
- Adapt Geko for iPad (#16)
- Mac App (Mac Catalyst) (#17)
- Charts & Metrics (#5)
- Year Rewind (#6)

### Notes
- iPad: NavigationSplitView, keyboard shortcuts, CloudKit-only sync (no Watch).
- Mac: Isolate WatchConnectivity; CloudKit + App Groups; same App Store listing.

---

## Notes
- **Devices** stand for the most tested devices for a given release. Everything else is moved to polish / bugfix.
- ✓ = implemented (issue closed).
