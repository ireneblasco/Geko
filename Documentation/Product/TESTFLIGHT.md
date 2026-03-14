# TestFlight Distribution

How to upload Geko to TestFlight and enable external testers.

## Prerequisites

- **Apple Developer Program** membership ($99/year)
- **App Store Connect** app record at [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
- Valid provisioning profiles and certificates

---

## Uploading to TestFlight

### 1. Configure Signing in Xcode

1. Open `Geko.xcodeproj` in Xcode
2. Select the **Geko** project in the navigator
3. For each target (Geko, GekoWatch, GekoWidgets):
   - Select the target → **Signing & Capabilities**
   - Enable **Automatically manage signing**
   - Choose your **Team**
   - Set the correct **Bundle Identifier** (e.g. `com.irenews.geko`)

### 2. Create an Archive

1. Set the run destination to **Any iOS Device (arm64)** (not a simulator)
2. Menu: **Product → Archive**
3. Wait for the archive to complete; the Organizer window opens automatically

### 3. Upload to App Store Connect

1. In **Organizer** (Window → Organizer), select the archive
2. Click **Distribute App**
3. Choose **App Store Connect** → **Next**
4. Choose **Upload** → **Next**
5. Accept defaults (upload symbols, manage version/build) → **Next**
6. Select your distribution certificate and provisioning profile (or let Xcode manage) → **Next**
7. Review and click **Upload**

### 4. Wait for Processing

Builds typically take 5–30 minutes to process. You'll receive an email when ready.

---

## Enabling External Testers

External testers require **Beta App Review** — Apple reviews the build before it can be distributed.

### 1. Add External Testers

1. Go to [App Store Connect](https://appstoreconnect.apple.com) → your app → **TestFlight**
2. In the left sidebar, select **External Testing**
3. Click **Create Group** (e.g. "Beta Testers")
4. Add testers:
   - **Add testers manually** — enter email addresses
   - **Enable public link** — generate a shareable link (up to 10,000 testers)
5. Select the build for this group
6. Fill in **Test Information** (required for Beta App Review):
   - **What to Test** — what you want testers to focus on
   - **Contact Information** — email for Apple to reach you
   - **Feedback Email** — where testers can send feedback (optional)
7. Click **Submit for Review**

### 2. Beta App Review

- Apple reviews the build (typically 24–48 hours)
- You'll receive an email when approved or if changes are needed
- Once approved, testers can install via the TestFlight app

### 3. Public Link (Optional)

- In the external group, enable **Enable Public Link**
- Share the link; anyone with it can join as a tester
- You can disable or regenerate the link at any time

---

## Internal vs External Testers

| | Internal Testers | External Testers |
|---|---|---|
| **Limit** | Up to 100 | Up to 10,000 (or unlimited with public link) |
| **Review** | No review | Beta App Review required |
| **Who** | App Store Connect users in your team | Anyone with invite or link |
| **Speed** | Available immediately after processing | After Beta App Review approval |

---

## Geko-Specific Notes

- **Multi-target app** — Archiving **Geko** includes the Watch app and widgets. Ensure GekoWatch and GekoWidgets have correct signing and bundle IDs.
- **App Groups** — All targets use `group.com.irenews.geko`; this must be enabled in the App ID and provisioning profiles.
- **CloudKit** — If using CloudKit, ensure the container is configured in the Developer Portal and App Store Connect.

---

## Command-Line Upload (Fastlane)

A single command builds and uploads to TestFlight:

```bash
bundle exec fastlane beta
```

### Setup

1. **Install dependencies** (one-time):
   ```bash
   bundle install
   ```

2. **Authentication** — On first run, Fastlane will prompt for your Apple ID. For non-interactive use (e.g. CI), set:
   - `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` — Create at [appleid.apple.com](https://appleid.apple.com)
   - `FASTLANE_USER` — Your Apple ID email

### What it does

1. Builds the Geko scheme (iOS app with widgets)
2. Exports a signed IPA for App Store Connect
3. Uploads to TestFlight

Build output goes to `build/` (gitignored). Processing in App Store Connect still takes 5–30 minutes after upload.

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "No signing certificate" | Create a distribution certificate in Xcode → Settings → Accounts → Manage Certificates |
| "Provisioning profile doesn't include..." | Add App Groups (and other capabilities) to the App ID and regenerate profiles |
| Build stuck "Processing" | Wait up to ~30 minutes; check email for processing errors |
| Watch app missing | Ensure GekoWatch is embedded in the Geko target (Embed App Extensions) |
