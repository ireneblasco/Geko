# Fastlane — Detailed Reference

Use this file when you need more detail than the main skill. Sections: [Xcode Cloud](#xcode-cloud) | [Match (detailed)](#match-detailed) | [Snapshot (detailed)](#snapshot-detailed) | [Beta & Release (detailed)](#beta--release-detailed)

---

## Xcode Cloud

Connect GitHub to Xcode Cloud and run Fastlane lanes after builds.

### Overview

| Script | When It Runs | Purpose |
|--------|--------------|---------|
| `ci_post_clone.sh` | After repo clone | Installs Homebrew + Fastlane |
| `ci_post_xcodebuild.sh` | After successful archive | Runs Fastlane lane based on workflow name |

### Setup Steps

1. **Connect GitHub:** Xcode → Product → Xcode Cloud → Create Workflow; sign in to App Store Connect; grant GitHub access.

2. **Repository layout** (ci_scripts at repo root):
   ```
   your-repo/
   ├── YourApp.xcodeproj
   ├── ci_scripts/
   │   ├── ci_post_clone.sh
   │   └── ci_post_xcodebuild.sh
   └── fastlane/
   ```
   Run `chmod +x ci_scripts/*.sh` before committing.

3. **Workflow names** (case-sensitive): `Beta`, `Release`, `Metadata`. `ci_post_xcodebuild.sh` matches the name to run the corresponding lane.

4. **App Store Connect API key:** Add env vars `APP_STORE_CONNECT_API_KEY_KEY_ID`, `APP_STORE_CONNECT_API_KEY_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_KEY` (base64-encoded key). In Fastfile, use `app_store_connect_api_key(..., is_key_content_base64: true)`.

5. **Branch triggers:** e.g. Beta on `develop`, Release on `main`, Metadata manual only.

### Troubleshooting

- Fastlane not running: workflow name exactly `Beta`/`Release`/`Metadata`; scripts executable.
- API key fails: base64-encode key: `base64 -i AuthKey_XXX.p8 | tr -d '\n'`; set `is_key_content_base64: true` in Fastfile.

---

## Match (detailed)

### What is Match?

Match stores iOS certificates and provisioning profiles in a **private Git repository**, encrypted with a passphrase. Benefits: team sharing, CI/CD ready, revoke protection, audit trail.

### Repository naming

- `certificates`, `ios-certificates`, `fastlane-certs`, `{company}-signing`
- Keep the repo private; limit access to people who need to build.

### Matchfile (after `fastlane match init`)

```ruby
git_url("git@github.com:yourorg/certificates.git")
storage_mode("git")
type("development")  # Override per-lane

# app_identifier(["com.yourcompany.app"])  # Optional
# username("user@example.com")              # Optional
# team_id("ABCD1234")                       # If multiple teams
```

### Full Fastfile integration (sync + beta + release)

```ruby
platform :ios do
  lane :sync_signing do
    match(type: "development")
    match(type: "appstore")
  end

  lane :beta do |options|
    match(type: "appstore", readonly: true)
    increment_build_number unless options[:skip_build_increment]
    gym(scheme: "YourApp", export_method: "app-store")
    pilot(skip_waiting_for_build_processing: true)
  end

  lane :release do
    match(type: "appstore", readonly: true)
    increment_build_number
    gym(scheme: "YourApp", export_method: "app-store")
    deliver(submit_for_review: false, force: true)
  end
end
```

### CI/CD environment variables

```bash
MATCH_PASSWORD="your-match-passphrase"
MATCH_GIT_URL="git@github.com:yourorg/certificates.git"

# App Store Connect (pick one)
FASTLANE_USER="your@appleid.com"
FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"

# Or API key (recommended for CI)
APP_STORE_CONNECT_API_KEY_ID="ABC123"
APP_STORE_CONNECT_API_KEY_ISSUER_ID="xyz-xyz-xyz"
APP_STORE_CONNECT_API_KEY_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
```

### GitHub Actions example

```yaml
- name: Install certificates
  run: fastlane match appstore --readonly
  env:
    MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
    MATCH_GIT_URL: ${{ secrets.MATCH_GIT_URL }}
```

### Xcode Cloud (Match in ci_post_clone.sh)

```bash
brew install fastlane
fastlane match appstore --readonly
```

Set `MATCH_PASSWORD` (and optionally `MATCH_GIT_URL`) in Xcode Cloud environment variables.

### Match commands reference

```bash
# Setup
fastlane match init
fastlane match development
fastlane match appstore
fastlane match adhoc

# Team (readonly)
fastlane match development --readonly
fastlane match appstore --readonly

# Maintenance
fastlane match nuke development
fastlane match nuke distribution
fastlane match change_password

# Debug
fastlane match development --verbose
```

### Extra troubleshooting

- **"Multiple teams found"** — Add `team_id("ABCD1234")` to Matchfile.
- **"Unable to find app with bundle identifier"** — Register app: `fastlane produce create -a com.yourcompany.app -n "Your App Name"`.

### Security best practices

1. Private repo only.
2. Strong passphrase (20+ chars), store in password manager.
3. Limit repo access to builders.
4. Rotate passphrase periodically: `match change_password`.
5. Prefer App Store Connect API keys for CI.

### Files created

```
fastlane/Matchfile

# In certificates repo:
certs/development/   and   certs/distribution/
profiles/development/   profiles/appstore/   profiles/adhoc/
```

---

## Snapshot (detailed)

### Why automate screenshots?

App Store needs multiple device sizes and languages. Manual: 5+ sizes × 5+ screens × N languages = hours; Snapshot runs once and generates all.

### Full Snapfile options

```ruby
devices([
  "iPhone 15 Pro Max",
  "iPhone 15 Pro",
  "iPhone SE (3rd generation)",
  "iPad Pro 13-inch (M4)",
])
languages(["en-US"])  # Add "ja", "de-DE", "fr-FR", "es-ES" as needed
scheme("YourAppUITests")
output_directory("./fastlane/screenshots")
clear_previous_screenshots(true)
stop_after_first_error(true)
# dark_mode(true)
# workspace("YourApp.xcworkspace")   # or project("YourApp.xcodeproj")
```

### Full UI test example

```swift
import XCTest

class ScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    func testTakeScreenshots() throws {
        let app = XCUIApplication()
        snapshot("01_HomeScreen")
        app.buttons["Feature"].tap()
        snapshot("02_FeatureScreen")
        app.textFields["Search"].tap()
        app.textFields["Search"].typeText("Example")
        snapshot("03_SearchResults")
        app.buttons["Settings"].tap()
        snapshot("04_Settings")
        snapshot("05_DetailView")
    }
}
```

### Snapshot CLI options

```bash
fastlane snapshot
fastlane snapshot --devices "iPhone 15 Pro Max"
fastlane snapshot --languages "en-US"
fastlane snapshot --skip_open_summary
```

Output: `fastlane/screenshots/{language}/{device}/`.

### App Store screenshot requirements (2024)

| Display Size | Example Devices | Dimensions |
|-------------|-----------------|------------|
| 6.7" | iPhone 15 Pro Max, 14 Pro Max | 1290 × 2796 |
| 6.5" | iPhone 15 Plus, 14 Plus | 1284 × 2778 |
| 5.5" | iPhone 8 Plus (legacy) | 1242 × 2208 |
| 12.9" iPad | iPad Pro 12.9" | 2048 × 2732 |

Minimum: 6.7" or 6.5" iPhone. Count: 1–10 per device size; 5–6 recommended.

### Frame screenshots (frameit)

```bash
brew install imagemagick
fastlane frameit
fastlane frameit silver
```

`fastlane/screenshots/Framefile.json` for custom titles/fonts/background/padding.

### Fastfile lanes for screenshots

```ruby
lane :screenshots do
  snapshot(
    scheme: "YourAppUITests",
    devices: ["iPhone 15 Pro Max", "iPad Pro 13-inch (M4)"],
    languages: ["en-US"]
  )
  # frameit(white: true)
end

lane :upload_screenshots do
  deliver(skip_binary_upload: true, skip_metadata: true, overwrite_screenshots: true)
end
```

### Extra troubleshooting

- **"SnapshotHelper.swift not found"** — Re-run `fastlane snapshot init`, add helper to UI test target.
- **"Unable to boot simulator"** — `xcrun simctl shutdown all` then `xcrun simctl erase all`.
- **Element not found** — In app: `button.accessibilityIdentifier = "settingsButton"`. In test: `app.buttons["settingsButton"].tap()`.

### Best practices

1. Use sample/demo data for screens.
2. Reset app state before each run.
3. Prefer accessibility identifiers over text.
4. Add waits for async/network content.
5. Capture dark mode if relevant.
6. Use real localizations, not placeholders.
7. Add landscape for iPad if needed.

### Files created

```
fastlane/Snapfile
fastlane/SnapshotHelper.swift
fastlane/screenshots/
  en-US/iPhone 15 Pro Max/01_HomeScreen.png ...
  ja/...
```

### Complete snapshot workflow

```bash
fastlane snapshot init
# Add SnapshotHelper to UITests, write test with snapshot() calls
fastlane snapshot
# Optional: fastlane frameit
fastlane deliver --skip_binary_upload --skip_metadata
```

---

## Beta & Release (detailed)

### What Beta does

1. Syncs certificates via Match (appstore).
2. Increments build number (unless skipped).
3. Builds release archive (gym).
4. Uploads to TestFlight (pilot).
5. Optional: distribute to external testers (e.g. `beta_external` lane).

### After beta upload

- Build appears in TestFlight in 1–5 minutes.
- Internal testers get access automatically.
- External testers need `beta_external` lane or manual setup in App Store Connect.

### What Release does

- **`fastlane release`:** Picks latest TestFlight build and submits it for review (no new build).
- **`fastlane release_full`:** Match → version bump (if given) → build number → build → upload → submit; optionally auto-release after approval.

### After submission

- Review usually 24–48 hours (or longer).
- Status: App Store Connect → My Apps → Your App → App Store.
- Rejected: fix issues, `fastlane beta`, then `fastlane release` again.
- Approved with `auto_release:true`: app goes live automatically; otherwise release manually in App Store Connect.
