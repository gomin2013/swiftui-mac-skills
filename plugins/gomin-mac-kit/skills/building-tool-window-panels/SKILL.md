---
name: building-tool-window-panels
description: Use when a macOS SwiftUI window needs side panels (History, AI chat, Help, Settings, About) beside the main content, an inspector or IDE-style icon rail, or when switching panels loses chat or scroll state.
---

# Building a Tool-Window Panel Rail

## Overview
This is the JetBrains-style right-hand tool window: an icon rail on the trailing edge, **one panel at a time** at full height, and a "–" button that hides it. It replaces stacked fold-out panels, which crowd each other.

**Core trick:** every panel stays mounted in a `ZStack`. The inactive ones get opacity 0, no hit testing and no accessibility, and the closed window has zero width. With a `switch`, the AI chat would lose its conversation on every switch.

## When to Use
- You need three or more secondary panels next to a main list or editor
- A panel holds `@State` that must survive switching (a chat, a draft, a scroll position)

Not for a single inspector. SwiftUI's `.inspector` is enough there.

## Usage
Copy `ToolWindow.swift` (it needs `glassSurface` from **adopting-liquid-glass**). Edit the `ToolPanel` cases, icons and titles, and choose which ones go in `ToolPanel.bottom` (settings-like panels).
```swift
struct ContentView: View {
    @AppStorage("ui.toolPanel") private var toolPanelRaw = ToolPanel.agent.rawValue
    /// @AppStorage can't hold an Optional: "" = hidden.
    private var toolPanel: Binding<ToolPanel?> {
        Binding(get: { ToolPanel(rawValue: toolPanelRaw) }, set: { toolPanelRaw = $0?.rawValue ?? "" })
    }

    var body: some View {
        HStack(spacing: 0) {
            MainList().frame(minWidth: 420, maxWidth: .infinity)
            ToolWindow(panel: toolPanel, glow: theme.colors) { item in
                switch item {
                case .history: HistoryPanel()
                case .agent: ChatPanel()
                case .help: HelpPanel()
                case .appearance: AppearancePanel()
                case .about: AboutView()
                }
            }
        }
    }
}
```
Help › App Help (⌘?) can open a panel by writing the key: `UserDefaults.standard.set(ToolPanel.help.rawValue, forKey: "ui.toolPanel")`.

## Quick Reference
| Behaviour | How |
|---|---|
| Toggle a panel | Click its rail icon or press ⌥⌘1…n (in `ToolPanel.allCases` order) |
| Hide | "–" in the header, or click the active icon |
| First launch | Defaults to `.agent`, so the welcome screen introduces the app. After that the last choice is kept, including hidden |
| Ambient glow | `glow: [Color]` with 2 colours. Turns off with Reduce Transparency and never sits under text |
| Panel width | 320 pt. Give the main column `minWidth` so the panel never squeezes it |

## Common Mistakes
| Mistake | Fix |
|---|---|
| `switch panel { … }` as the body | Chat and draft state reset on every switch. Keep all panels mounted |
| Only `.opacity(0)` on hidden panels | Clicks and VoiceOver still reach them. Also add `allowsHitTesting(false)` and `accessibilityHidden(true)` |
| `@AppStorage var panel: ToolPanel?` | Not supported. Store the raw `String`, with `""` meaning hidden |
| Each panel draws its own fold header | The tool window already has a title. Give panels an `isToolWindow` flag that hides their header |
| Removing or reordering a `ToolPanel` case without updating Help text | ⌥⌘ numbers follow `allCases` order, so they shift. Update any docs that name them |
| Rail icons with no label | Use `.help("Title (⌥⌘n)")`, `.accessibilityLabel`, and `.isSelected` on the active icon |
