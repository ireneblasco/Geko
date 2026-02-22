# No Matching Device (Simulator Not Found)

When Xcode shows **"No matching device"** with a device UUID (e.g. `AA87A005-9BB9-4DA7-8F8D-EA7030F44B43`) and references `com.apple.CoreSimulator.SimError` code 404, the scheme is targeting a simulator that no longer exists. This typically happens after upgrading Xcode, deleting simulators, or cleaning up iOS runtimes.

## Quick Fix

1. In Xcode, click the **scheme/destination** selector next to the Run button (e.g. "Geko > iPhone 16").
2. Choose a valid simulator such as **iPhone 16** or **iPhone 16 Pro**.
3. Run or test again.

## Deeper Cleanup (if the quick fix doesn't work)

### 1. Reset XCTestDevices

Quit Xcode first, then run:

```bash
rm -rf ~/Library/Developer/XCTestDevices
```

Xcode will recreate this folder when needed.

### 2. Clear Derived Data

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/Geko-*
```

### 3. Reset Scheme Destination

If the scheme keeps reverting to the bad device:

- Use **Product → Destination → Choose Destination…** and select a valid simulator.

Or remove the scheme user state so Xcode forgets the last-used destination:

```bash
rm Geko.xcodeproj/xcuserdata/irenews.xcuserdatad/xcschemes/xcschememanagement.plist
```

### 4. Restart Xcode

Quit Xcode completely and reopen the project.
