# swiftui-mac-skills

Claude Code skills for building native macOS SwiftUI apps. They are extracted from two shipping apps,
[Hosts Manager](https://gomin2013.github.io/hosts-manager/) and
[Git Exclude Manager](https://gomin2013.github.io/git-exclude-manager/).

Each skill has real, compiling code to copy and the pitfalls we hit getting it right.

## Install

```
/plugin marketplace add gomin2013/swiftui-mac-skills
/plugin install gomin-mac-kit@gomin
```

Then ask Claude something like *"start a new macOS SwiftUI app with Liquid Glass and a side panel rail"*.

## Skills (`gomin-mac-kit`)

| Skill | What you get |
|---|---|
| `scaffolding-swiftpm-mac-app` | SwiftPM-only app (no `.xcodeproj`), `build-app.sh` → signed `.app`, and the SDK-stamp fix without which macOS 26 shows no Liquid Glass |
| `adopting-liquid-glass` | `glassSurface` / `glassButton` / `glassGroup`: glass on macOS 26 with a material fallback on 14–15 |
| `building-tool-window-panels` | IDE-style icon rail with one panel at a time, ⌥⌘1…n shortcuts, and panels that keep their state when you switch |
| `theming-accent-and-gradients` | Light/Dark/System, 16 contrast-matched accents, and 8 gradient themes used as ambient light |

Requirements: macOS 14+ target, Swift 6, Xcode 26+ SDK for Liquid Glass.

## Pro skills (for sponsors)

A private plugin, `gomin-mac-kit-pro`, builds on these skills. It's available to [GitHub Sponsors](https://github.com/sponsors/gomin2013):

- **Available now:** AI agent panel (Claude, OpenAI, Gemini, Ollama, Apple Foundation Models), with streaming and visible thinking, Keychain-stored keys and Markdown replies · History panel (Photoshop-style, with pins)
- **Coming:** Help & About · in-app language switching (12 languages) · privileged helper over XPC · DMG release

## License

MIT, see [LICENSE](LICENSE). Support the work on [GitHub Sponsors](https://github.com/sponsors/gomin2013).
