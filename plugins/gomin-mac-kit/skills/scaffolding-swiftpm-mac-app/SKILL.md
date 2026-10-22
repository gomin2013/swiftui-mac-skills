---
name: scaffolding-swiftpm-mac-app
description: Use when starting a new macOS SwiftUI app without an .xcodeproj (Swift Package Manager only), when turning `swift build` output into a runnable .app bundle, or when an SPM-built app on macOS 26 shows the old pre-Liquid-Glass look.
---

# Scaffolding a SwiftPM macOS App

## Overview
A Dock/Launchpad SwiftUI app built entirely from `Package.swift` with zero dependencies. `scripts/build-app.sh` assembles and signs `build/<App>.app`. The one thing you can't guess is this: **SwiftPM stamps the binary with the deployment target as its SDK version** (`sdk 14.0`), and macOS 26 then draws it the legacy way. You get no Liquid Glass even when you build with the newest Xcode.

## When to Use
- You're creating a new macOS app and want to work without an Xcode project
- `swift build` works but you need a double-clickable, signed `.app`
- The app looks "old" on macOS 26 even though it uses `.glassEffect`

Not for iOS, or for apps that need Xcode-only features (App Store archives, storyboards).

## Setup
Copy `templates/` into the new repo, then rename `MyApp` → `<App>` in **paths and contents**. Also replace `com.example.myapp` and `My App`.

```
Package.swift                      # macOS 14+, executableTarget + testTarget, resources: .process("Resources")
Sources/MyApp/MyApp.swift          # @main WindowGroup, File › New Window removed
Sources/MyApp/Info.plist           # excluded from the target; build-app.sh copies it
Sources/MyApp/Resources/en.lproj/  # one .lproj per language
Tests/MyAppTests/MyAppTests.swift  # guards Info.plist ↔ executable name
scripts/build-app.sh               # build → bundle → sign → verify
```

## The SDK stamp (core fix)
```bash
SDK_VERSION="$(xcrun --show-sdk-version)"
LINK_SDK=(-Xlinker -platform_version -Xlinker macos -Xlinker 14.0 -Xlinker "$SDK_VERSION")
swift build -c "$CONFIG" "${LINK_SDK[@]}"
BIN="$(swift build -c "$CONFIG" "${LINK_SDK[@]}" --show-bin-path)"   # same flags, or a different bin path
```
The minimum OS stays at 14.0 and only the SDK field changes. Pass the same flags to `--show-bin-path`.

## Verify (required: done = all three pass)
```bash
swift test
bash scripts/build-app.sh
vtool -show-build build/MyApp.app/Contents/MacOS/MyApp | grep -E 'minos|sdk'   # expect minos 14.0, sdk ≥ 26
```

## Common Mistakes
| Mistake | Result | Fix |
|---|---|---|
| Plain `swift build` into the bundle | `sdk 14.0` → no Liquid Glass on macOS 26 | the `-platform_version` linker flags above |
| Judging the look from `swift run` | Same `sdk 14.0` binary, so it looks legacy | Judge the look only from `build-app.sh` output (debug works too: `bash scripts/build-app.sh debug`) |
| A check that fails when the vtool `sdk` is < 26 but has no stamp | Fails every build, because SwiftPM always writes 14.0 | Stamp first, then check |
| Relying on `Bundle.module` in the .app | SwiftPM's resource bundle isn't sealed or found | Copy `*.lproj` into `Contents/Resources`; use `Bundle.main` |
| `UIDesignRequiresCompatibility` in Info.plist | Opts out of Liquid Glass | Leave it out |
| Executable renamed but not in Info.plist | App won't launch | `MyAppTests` catches it |
| Signing before all copies are done | `codesign --verify` fails | Sign last (helpers inside-out, then the app) |

Templates compile in Swift 6 language mode (tools-version 6.0) with no concurrency warnings. Out of scope: app icon, entitlements/sandbox, notarization.

## Next
For the look, see **adopting-liquid-glass**. For the side panels, see **building-tool-window-panels**. For the colours, see **theming-accent-and-gradients**.
