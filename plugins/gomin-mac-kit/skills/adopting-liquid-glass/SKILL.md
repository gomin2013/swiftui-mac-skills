---
name: adopting-liquid-glass
description: Use when adding Liquid Glass (`glassEffect`, `.glass` button styles, `GlassEffectContainer`) to a macOS SwiftUI app that must still run on macOS 14–15, or when glass is missing, too heavy, or covering content.
---

# Adopting Liquid Glass with a Fallback

## Overview
Three modifiers in `Glass.swift` give you glass on macOS 26 and `.regularMaterial` or bordered styles on 14–15. Every glass call goes through them, so no `#available` checks end up scattered across views.

**Rule:** glass belongs to the **control layer**, meaning toolbars, search capsules, button rows and floating panels. It never goes on content such as list rows, text bodies or editors.

## Quick Reference
| Modifier | macOS 26 | macOS 14–15 |
|---|---|---|
| `.glassSurface(cornerRadius:)` | `glassEffect(.regular, in: .rect(cornerRadius:))` | `.regularMaterial` rounded rect |
| `.glassButton(prominent: true)` | `.glassProminent` (tinted with the accent) | `.borderedProminent` |
| `.glassButton()` | `.glass`, tint cleared | `.bordered` |
| `.glassGroup(spacing:)` | `GlassEffectContainer`, so neighbours blend | no-op |

`#if compiler(>=6.2)` keeps the file compiling on older toolchains, and `#available(macOS 26, *)` chooses the look at run time.

## Usage
Copy `Glass.swift` into `Sources/<App>/`.
```swift
HStack {
    searchField
    Button("Add", action: add).glassButton(prominent: true)   // the ONE key action
    Button("Import", action: importFile).glassButton()
}
.padding(8)
.glassSurface(cornerRadius: 16)
.glassGroup()

List(items) { row($0) }            // content layer: no glass
```

## Common Mistakes
| Mistake | Fix |
|---|---|
| Glass works in Xcode previews but not in the built .app | The binary is stamped `sdk 14.0`. See **scaffolding-swiftpm-mac-app** and check with `vtool -show-build` |
| Glass on list rows or cells | Content reads worse and the effect stacks. Keep glass on controls only |
| Every button `.glassProminent` | Colour only the primary action (HIG). The rest use `.glassButton()` |
| Glass nested inside glass | Use one surface and group its neighbours with `.glassGroup()` |
| Text over a colourful gradient behind the glass | Gradients are ambient only. See **theming-accent-and-gradients** |
| Ignoring Reduce Transparency for custom glows | Check `@Environment(\.accessibilityReduceTransparency)` (system glass handles itself) |

## Verify
1. `vtool -show-build <app binary>` shows `sdk ≥ 26`. Without it, nothing else below matters.
2. Open the `build-app.sh` output on macOS 26 and confirm the surfaces refract.
3. Run the same .app on a macOS 14 or 15 machine or VM and confirm the material fallback is legible.
