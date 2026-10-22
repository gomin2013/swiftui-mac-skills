---
name: prototyping-mac-app-in-html
description: Use when starting a macOS SwiftUI app (or a big UI change) and the user wants a clickable prototype to iterate on before any Swift, when several apps in a family share the same window chrome, or when turning an approved prototype into the SwiftUI app and its tests.
---

# Prototyping a Mac App in HTML

## Overview
A static HTML prototype in the app's repo is the spec for the SwiftUI app. Each feedback round takes seconds because nothing compiles. **Core trick:** the prototype holds real logic and real strings, not only the look, so the Swift app is tested *against the prototype*: its functions produce the expected values and its string tables become `Localizable.strings`.

## When to Use
- "Prototype it first, we'll iterate until it's right"
- App #2+ in a family with the same rail / panels / settings
- Building the SwiftUI app from a prototype the user approved

Not for exploring a single SwiftUI view's look in Xcode previews.

## Layout
```
.prototype/
  index.html    app: screens, data model, rules (one file is fine — ~1 000 lines)
  shell.js      window chrome shared by every app in the family (byte-identical)
  shell.css
  img/          real art the app will ship (cut sheets, icons)
  README.md     how to run · layout · a "Real vs mock" table · things to try
```
Run it with `cd .prototype && python3 -m http.server 8080`, **not** `open index.html`: Playwright refuses `file:` URLs, and only the server gives the app a real origin for its storage.

## Rules that pay off later
| Rule | Why |
|---|---|
| Keep rules as plain functions (`segmentsOf`, `cleanImport`, `requestBody`) | They become the Swift functions and their test oracle |
| Make free, local features real (on-device speech, key test, local model) | Feedback is then about real behaviour; badge only what's mocked (`MOCK`) |
| Every string in one table per language (`STRINGS = {en:{…}}`, more languages later), placeholders `{0}` | Generated into `.strings` later (`scripts/extract-strings.mjs`) |
| Storage keys prefixed with `document.title` | Several prototypes served from one folder don't share state |
| Imported files go through one cleaning function that rebuilds every field | Imported strings would otherwise reach inline `onclick` handlers (DOM XSS) |
| Shared chrome options are optional and backward compatible; an app overrides a panel body via its config (`panels: {language: …}`) | Edit `shell.js` once, copy to every app, nothing breaks |

## Each round
1. Change it, then load it in Playwright and **query state with `evaluate`** (not just a screenshot): the thing you changed, plus light and dark mode, plus both languages.
2. A cached `shell.js`/`app.js` looks like a failed fix: if the page still behaves the old way, serve it on a new port before debugging.
3. Report what you checked; record settled decisions so later rounds don't reopen them.

## Prototype → SwiftUI
- **"The prototype is the spec":** when Swift and the prototype disagree, ask; don't redesign silently.
- **Oracle tests:** run the prototype's own functions on the test fixtures in the browser, paste the output into the Swift test as the expected value:
  ```js
  // Playwright browser_evaluate on the running prototype
  () => { S.draft = FIXTURE; return JSON.stringify(requestBody(S.draft)); }
  ```
- **Strings:** `node scripts/extract-strings.mjs .prototype Sources/App/Resources`. It stops when the shell table and the app table give one key **different text** — the app silently wins, so a shell button can show the app's text. Rename the app key; only a deliberate override (an app retitling a shared panel) goes in `--allow key`. Pass **Strings**, never Ints, into `%1$@`.
- Port the copy from the generated file, not by retyping it; carry the README's Real/Mock table into the phase plan.

## Common Mistakes
| Mistake | Fix |
|---|---|
| Native SwiftUI prototype | Seconds per round in HTML vs a build; SwiftUI comes after sign-off |
| Copy the chrome into each app, "extract later" | One `shell.js`, identical in every prototype, synced on change |
| Matching only pixels | Oracle tests for the rules, string generation for the copy |
| `Date.formatted` / numbers in the system locale | Format with the app's language (and its calendar) like the prototype does with `Shell.lang` |
