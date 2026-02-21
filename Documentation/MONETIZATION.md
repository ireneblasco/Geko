# Geko Monetization Strategy

This document describes the paid subscription model for Geko, implementation details, and manual App Store Connect setup.

---

## GitHub Issue #10 – User Subscriptions

**URL:** https://github.com/irenews/Geko/issues/10  
**Labels:** Feature, New App Functionality  
**Milestone:** Newt (v1.0)

### Description

> A way to unblock app functionality
>
> - Having more than 3 habits
> - Having more than 1 iOS widget
> - Using watch app or widgets

### Implementation Mapping

| Issue requirement | Implementation |
|-------------------|----------------|
| More than 3 habits | Free: 3 habits max. Plus: unlimited. Gate in `AddHabitView` / `ContentView`. |
| More than 1 iOS widget | We cannot count widget instances. All widgets require Plus (free = 0 widgets). Gate in `WidgetProvider`. |
| Using watch app or widgets | Widgets: Plus only. Watch app: gated in v2.0 when re-enabled. |

---

## Tier Definitions

| Feature | Free | Geko Plus |
|---------|------|-----------|
| Habits | 3 max | Unlimited |
| iOS Widgets | None | All widget sizes |
| Watch app | No access | Full access (v2.0+) |

**Rationale:** We cannot count widget instances on iOS, so all widgets require Plus. Free users see an upgrade CTA when they add a widget.

**Release scope:**
- **v1.0:** Habit limit + widget gating (Watch app disabled)
- **v2.0:** Watch app gating when re-enabled

---

## Product IDs and Subscription Structure

| Product ID | Type | Duration | Price (example) |
|------------|------|----------|-----------------|
| `com.irenews.geko.plus.monthly` | Auto-renewable | 1 month | $2.99 |
| `com.irenews.geko.plus.annual` | Auto-renewable | 1 year | $14.99 |
| `com.irenews.geko.plus.lifetime` | Non-consumable | — | $39.99 |

- **Subscription group:** "Geko Plus" (one group for monthly and annual)
- **Lifetime:** Separate non-consumable IAP, not part of subscription group

---

## Entitlement Logic

**`isPlus`** is true when the user has:
- An active auto-renewable subscription (monthly or annual), or
- A completed lifetime (non-consumable) purchase

**Flow:**
1. `StoreManager` observes `Transaction.currentEntitlements` on launch
2. On purchase/restore: `StoreManager` notifies `EntitlementManager`
3. `EntitlementManager` updates `isPlus` and writes to App Group `UserDefaults`
4. Widgets read `isPlus` from App Group on each timeline refresh

**Storage:** `UserDefaults(suiteName: "group.com.irenews.geko")` with key `isPlus` (Bool)

---

## Gating Points

| Location | Check | Action when not Plus |
|----------|-------|----------------------|
| `AddHabitView` | `habits.count >= 3` | Present paywall instead of adding |
| `ContentView` | Add Habit button | Disable or show paywall when at limit |
| `WidgetProvider` | All families | Return locked entry with upgrade CTA |
| `GekoWatch` (v2.0) | App launch | Show paywall |

---

## App Store Connect Manual Steps

These steps must be performed in [App Store Connect](https://appstoreconnect.apple.com) and cannot be automated.

### 1. Agreements and Banking

1. Go to **Agreements, Tax, and Banking**
2. Accept **Paid Applications Agreement** if not already done
3. Complete **Banking** and **Tax** information

### 2. Create Subscription Group

1. Open your app in App Store Connect
2. Go to **Monetization** → **Subscriptions**
3. Click **Create** (or **+**) to add a subscription group
4. Name it **Geko Plus**
5. Add localizations for the group name

### 3. Create Subscription Products

1. Inside the **Geko Plus** subscription group, create:

**Monthly subscription**
- Reference Name: `Geko Plus Monthly`
- Product ID: `com.irenews.geko.plus.monthly` (must match code exactly)
- Subscription Duration: 1 month
- Price: Select tier (e.g. $2.99)
- Add localizations (display name, description)

**Annual subscription**
- Reference Name: `Geko Plus Annual`
- Product ID: `com.irenews.geko.plus.annual`
- Subscription Duration: 1 year
- Price: Select tier (e.g. $14.99)
- Add localizations
- (Optional) Add introductory offer: free trial or discounted first period

### 4. Create Lifetime Product (Non-Consumable)

1. Go to **Monetization** → **In-App Purchases**
2. Click **Create** (or **+**)
3. Select **Non-Consumable**
4. Reference Name: `Geko Plus Lifetime`
5. Product ID: `com.irenews.geko.plus.lifetime`
6. Price: Select tier (e.g. $39.99)
7. Add localizations

### 5. Subscription Group Configuration

1. In the subscription group, set **Subscription Levels** for upgrade/downgrade (e.g. monthly = 1, annual = 2)
2. Configure **Introductory Offers** if desired
3. Configure **Promotional Offers** (optional)

### 6. App Metadata

1. **App Information** → Ensure **In-App Purchase** capability is enabled
2. **App Store listing** → Add subscription disclosure text if required by region

### 7. Testing

1. **Sandbox Testers:** Users and Access → Sandbox → Testers
2. Create a sandbox Apple ID for testing
3. Sign out of App Store on device, run app, attempt purchase → sign in with sandbox account when prompted

**Note:** Product metadata changes can take up to 1 hour to appear in sandbox.

---

## Local Testing (StoreKit Configuration)

For development without App Store Connect:

1. In Xcode: **File** → **New** → **File** → **StoreKit Configuration File**
2. Add products matching the Product IDs above
3. In scheme: **Edit Scheme** → **Run** → **Options** → **StoreKit Configuration** → Select the file
4. Purchases will be simulated locally

---

## Architecture Overview

```
StoreManager (StoreKit 2)
    → observes Transaction.currentEntitlements
    → notifies EntitlementManager on purchase/restore

EntitlementManager
    → isPlus (derived from StoreManager)
    → writes to App Group UserDefaults (for widgets)

Geko App (ContentView, AddHabitView)
    → reads EntitlementManager.isPlus for gating

GekoWidgets (Provider)
    → reads isPlus from App Group UserDefaults
    → returns locked entry when not Plus
```

---

## Key Files

| File | Purpose |
|------|---------|
| `GekoShared/EntitlementManager.swift` | `isPlus` state, App Group sync |
| `Geko/StoreManager.swift` | StoreKit 2: products, purchase, restore |
| `Geko/Products.swift` | Product ID constants |
| `Geko/PaywallView.swift` | Paywall UI |
| `GekoWidgets/WidgetProvider.swift` | Widget gating (locked entry when not Plus) |
