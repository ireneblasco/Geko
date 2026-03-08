---
name: fastlane
description: Set up and run Fastlane for iOS/macOS app automation. Use when working with TestFlight, App Store submission, code signing (Match), App Store screenshots (Snapshot), or Fastlane setup.
---

# Fastlane for iOS/macOS

Automate TestFlight uploads, App Store releases, code signing, and screenshots with Fastlane.

## Pre-flight Checks

Run these to verify prerequisites before any Fastlane workflow:

- `xcode-select -p` — Xcode CLI installed (if missing: `xcode-select --install`)
- `brew --version` — Homebrew installed (if missing: install from https://brew.sh)
- `fastlane --version` — Fastlane installed (if missing: `brew install fastlane`)
- `find . -maxdepth 2 -name "*.xcodeproj"` — Locate Xcode project
- `grep -r "PRODUCT_BUNDLE_IDENTIFIER" --include="*.pbxproj" . | head -1` — Extract bundle ID
- `grep -r "DEVELOPMENT_TEAM" --include="*.pbxproj" . | head -1` — Extract team ID

---

## Setup (One-Time)

### Step 1: Install Fastlane

```bash
brew install fastlane
```

> **Install options:** **Bundler** (recommended for projects) — add `gem "fastlane"` to Gemfile, run `bundle exec fastlane [lane]`. **Homebrew** — `brew install fastlane` for a global install without managing Ruby.

### Step 2: Create Configuration Files

**`fastlane/Appfile`**
```ruby
app_identifier("{{BUNDLE_ID}}")  # From .pbxproj
apple_id("{{APPLE_ID}}")         # Your Apple ID email
team_id("{{TEAM_ID}}")           # From .pbxproj
```

**`fastlane/Fastfile`**
```ruby
default_platform(:ios)

platform :ios do
  desc "Run tests"
  lane :test do
    scan(scheme: "{{SCHEME}}")
  end

  desc "Upload to TestFlight"
  lane :beta do
    increment_build_number
    gym(scheme: "{{SCHEME}}", export_method: "app-store")
    pilot(skip_waiting_for_build_processing: true)
  end

  desc "Submit to App Store"
  lane :release do
    increment_build_number
    gym(scheme: "{{SCHEME}}", export_method: "app-store")
    deliver(submit_for_review: false, force: true)
  end
end
```

Replace `{{SCHEME}}` with the app's scheme name (usually the app name). Substitute `{{BUNDLE_ID}}`, `{{TEAM_ID}}` from project `.pbxproj`.

### Step 3: Metadata (Optional)

```bash
fastlane deliver download_metadata
fastlane deliver download_screenshots
```

Creates `fastlane/metadata/` with editable App Store listing files.

### Quick Reference

| Command | Purpose |
|---------|---------|
| `fastlane lanes` | List available lanes |
| `fastlane ios test` | Run tests |
| `fastlane ios beta` | Build + TestFlight |
| `fastlane ios release` | Build + App Store |

---

## Match (Code Signing)

Match stores certificates and provisioning profiles in a **private Git repository**, encrypted with a passphrase.

### Verify Before Match

- `ls fastlane/Fastfile` — Fastfile exists
- `ls fastlane/Matchfile` — Check if Match already configured
- `git --version` — Git available

### Step 1: Create Private Git Repo

```bash
gh repo create certificates --private --clone
# Or create manually at github.com/new (Private)
```

### Step 2: Initialize Match

```bash
fastlane match init
```

Select `git` storage, enter private repo URL (e.g. `git@github.com:yourorg/certificates.git`).

### Step 3: Generate Certificates

```bash
fastlane match development   # For debugging
fastlane match appstore      # For TestFlight/App Store
fastlane match adhoc         # For direct device distribution
```

First run: enter Apple ID and create a strong passphrase (save in password manager).

### Step 4: Integrate with Fastfile

Use `readonly: true` in build lanes to prevent accidental cert regeneration:

```ruby
lane :beta do |options|
  match(type: "appstore", readonly: true)
  increment_build_number unless options[:skip_build_increment]
  gym(scheme: "YourApp", export_method: "app-store")
  pilot(skip_waiting_for_build_processing: true)
end
```

### Team Onboarding

```bash
fastlane match development --readonly
fastlane match appstore --readonly
```

### CI/CD Environment Variables

```bash
MATCH_PASSWORD="your-match-passphrase"
MATCH_GIT_URL="git@github.com:yourorg/certificates.git"
# Plus FASTLANE_USER and FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD or App Store Connect API key
```

### Troubleshooting

- **"Couldn't decrypt the repo"** — Wrong `MATCH_PASSWORD`
- **"No provisioning profiles"** — Run `fastlane match appstore` without `--readonly`
- **"Certificate revoked"** — `fastlane match nuke development` then `fastlane match development`

For more: full Matchfile, CI/CD examples (GitHub Actions, Xcode Cloud), commands reference, security practices, and extra troubleshooting, see [reference.md](reference.md#match-detailed).

---

## Beta (TestFlight)

### Pre-flight

- `fastlane --version` — Fastlane installed
- `ls fastlane/Fastfile` — Fastfile exists
- `[ -n "$FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD" ]` — App-specific password set (or use API key)

### Commands

```bash
fastlane beta                          # Standard (internal testers)
fastlane beta skip_build_increment:true
fastlane beta_external changelog:"Bug fixes"  # External testers
```

### Troubleshooting

- **"No value found for 'username'"** — Set `apple_id("your@email.com")` in `fastlane/Appfile`
- **"Please sign in with app-specific password"** — Create at account.apple.com → App-Specific Passwords, then `export FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD='xxxx-xxxx-xxxx-xxxx'`
- **rsync `--extended-attributes` error** — `brew uninstall rsync` (use system rsync)

---

## Release (App Store)

### Pre-flight

Same as Beta: Fastlane, Fastfile, app-specific password or API key.

### Commands

```bash
fastlane release                       # Submit existing TestFlight build
fastlane release_full version:"1.1.0"  # Full pipeline: build + submit
fastlane release_full version:"1.2.0" auto_release:true  # Auto-release after approval
```

### Workflow

1. Test first: `fastlane beta`
2. Verify in TestFlight
3. Submit: `fastlane release` (or `release_full` for fresh build)

### Troubleshooting

- **"Value has already been used"** — Increment version: `fastlane release_full version:"1.0.1"`
- **Build rejected** — Fix issues, `fastlane beta`, then `fastlane release`

---

## Snapshot (Screenshots)

### Pre-flight

- `fastlane --version`, `ls fastlane/Fastfile`
- `ls fastlane/Snapfile` — Check if configured
- `find . -maxdepth 3 -name "*UITests*" -type d` — UI test target
- `xcrun simctl list devices available` — Simulators

### Step 1: Initialize

```bash
fastlane snapshot init
```

Creates `fastlane/Snapfile` and `fastlane/SnapshotHelper.swift`.

### Step 2: Configure Snapfile

```ruby
devices(["iPhone 15 Pro Max", "iPhone 15 Pro", "iPhone SE (3rd generation)"])
languages(["en-US"])
scheme("YourAppUITests")
output_directory("./fastlane/screenshots")
```

### Step 3: Add SnapshotHelper to UI Tests

Add `fastlane/SnapshotHelper.swift` to the **UITests** target. In test file:

```swift
override func setUpWithError() throws {
  continueAfterFailure = false
  let app = XCUIApplication()
  setupSnapshot(app)  // Before app.launch()
  app.launch()
}
func testTakeScreenshots() throws {
  snapshot("01_HomeScreen")
  // Navigate, then snapshot("02_FeatureScreen"), etc.
}
```

### Step 4: Run and Upload

```bash
fastlane snapshot
fastlane deliver --skip_binary_upload --skip_metadata
```

### Troubleshooting

- **Black/blank screenshots** — Call `setupSnapshot(app)` before `app.launch()`; add `sleep(1)` for async content
- **"No matching device"** — Match device names from `xcrun simctl list devices available`
- **Element not found** — Use `accessibilityIdentifier` in app and `app.buttons["id"]` in test

For more: full Snapfile options, App Store requirements table, frameit, Fastfile lanes, best practices, and complete workflow, see [reference.md](reference.md#snapshot-detailed).

---

## Geko-Specific Notes

Geko uses:

- **Bundle exec**: `bundle exec fastlane beta` (Gemfile present)
- **API key**: `fastlane/AuthKey_KT4CGFWKWJ.p8` (or similar) — key_id and issuer_id in Fastfile
- **Multi-target**: Geko, GekoWatch, GekoWidgets — ensure all targets have correct signing and bundle IDs
- **App Groups**: `group.com.irenews.geko` must be in App ID and provisioning profiles

---

## Additional Resources

Detailed reference (read when you need more than the summary above):

- **[reference.md](reference.md)** — Progressive detail:
  - **Xcode Cloud** — CI/CD with `ci_scripts/`, workflow names, API key in env, troubleshooting
  - **Match (detailed)** — Full Matchfile, repo naming, CI/CD examples (GitHub Actions, Xcode Cloud), commands reference, security practices, extra troubleshooting, files created
  - **Snapshot (detailed)** — Full Snapfile options, full UI test example, CLI options, App Store requirements table, frameit/Framefile.json, Fastfile lanes, best practices, complete workflow
  - **Beta & Release (detailed)** — Step-by-step “what this does”, after upload/submission, review timeline
