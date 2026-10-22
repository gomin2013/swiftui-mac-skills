---
name: theming-accent-and-gradients
description: Use when a macOS SwiftUI app needs a user-chosen accent colour, gradient or colour themes, or a Light/Dark/System switch, or when custom accents fail contrast in light or dark mode.
---

# Theming: Accent, Gradient, Appearance

## Overview
`Theme.swift` provides three settings stored in `@AppStorage` and an `AppearancePanel` to edit them:

- **Appearance:** Light, Dark or System, applied through `NSApp.appearance`.
- **Accent:** System plus 16 fixed hex hues, **all at relative luminance ≈ 0.16**. White text on each one is 5.0:1, and each one on a dark window is 3.3:1, so **a single value works in both light and dark** with no dynamic colour.
- **Gradient theme:** 8 two-tone pairs used as **ambient light only**. Picking a theme also sets its paired solid accent, and the accent is what colours the controls.

## Why not generate hues (HSB, 360/16 steps)?
At equal HSB brightness, yellow and green look much lighter than blue and violet, so contrast varies from hue to hue and white button text fails on some of them. The palette here is measured instead. Don't replace it with computed hues.

## Usage
Copy `Theme.swift`. At the root view:
```swift
@AppStorage("ui.accent") private var storedAccent = AccentChoice.system
@AppStorage("ui.gradient") private var storedTheme = GradientTheme.none
@AppStorage("app.appearance") private var appearance = Appearance.system

private var accent: AccentChoice { AccentChoice.launchOverride ?? GradientTheme.launchOverride?.accent ?? storedAccent }
private var theme: GradientTheme { GradientTheme.launchOverride ?? storedTheme }

var body: some View {
    content
        .tint(accent.color)                         // nil = System Settings accent
        .onChange(of: appearance, initial: true) { NSApp.appearance = appearance.nsAppearance }
}
```
Show `AppearancePanel()` in a settings panel (for example the `.appearance` tool-window panel). Pass `theme.colors` as `ToolWindow(glow:)`.

For screenshots, `open MyApp.app --args -accent teal` or `-gradient lagoon` overrides the stored values without touching them.

## Rules
| Rule | Why |
|---|---|
| Gradients never go under text, controls or the whole window background | No pair keeps white text ≥ 4.5:1 end to end, and some ends disappear on dark (#251351 on a dark window ≈ 1.02:1) |
| A gradient is a blurred glow in a panel corner | Ambient only, turned off with Reduce Transparency |
| Controls use `.tint(accent.color)` | One solid colour that passes contrast |
| Choosing a gradient sets `accent = theme.accent` | The controls then match the glow |
| `.tint` at the root, not `NSColor.controlAccentColor` | The system accent can't be overridden per app |
| Root view and panel read the **same** `@AppStorage` keys | Changes in the panel apply immediately everywhere |

## Common Mistakes
| Mistake | Fix |
|---|---|
| `theme.gradient.opacity(0.15)` behind all content | The glow belongs in one corner of a panel, not behind the content |
| Gradient used as a button fill | Use the paired `accent` |
| More than 16 accents | At the same luminance, extra hues become indistinguishable |
| Names via `rawValue.capitalized` in a localized app | Replace them with your localization keys |
