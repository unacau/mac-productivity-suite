# Progress: Mac Productivity Suite

## Status Legend
- 📋 Planned
- 🚧 In Progress
- ✅ Complete
- ⏸️ Deferred
- ❌ Excluded

---

### Stage 1: Foundation, Permissions & Hyper Key Setup

### Deliverables
- [ ] ✅ Basic project directory structure initialized in `~/Igor/igorekishev/mac-productivity-suite`.
- [ ] 📋 Symlink created from the project directory to `~/.hammerspoon/` for seamless local testing.
- [ ] 📋 Hammerspoon granted necessary Accessibility and Screen Recording permissions in macOS System Settings.
- [ ] 📋 Karabiner-Elements complex modification JSON generated to map `Caps Lock` held to Hyper Key (`Cmd + Opt + Ctrl + Shift`) and `Caps Lock` tapped to `Escape`.
- [ ] 📋 Basic `init.lua` created to verify Hammerspoon is loading the configuration.

### Acceptance Criteria
- [ ] 📋 The project directory is successfully symlinked to `~/.hammerspoon/`.
- [ ] 📋 Pressing and holding `Caps Lock` registers as `Cmd + Opt + Ctrl + Shift` in a keyboard event viewer.
- [ ] 📋 Tapping `Caps Lock` quickly registers as `Escape`.
- [ ] 📋 Hammerspoon successfully reloads its configuration without permission errors.

---

## Stage 2: Global App Switcher (Standard Applications)

### Deliverables
- [ ] 📋 Hammerspoon script (`app_switcher.lua`) to bind Hyper Key + letter combinations to `hs.application.launchOrFocus`.
- [ ] 📋 Implementation of the following bindings: `T` (Terminal), `S` (Safari), `B` (Brave), `M` (TextMate), `L` (Telegram), `F` (FreeForm), `G` (Finder), `H` (Photos), `N` (Notes), `R` (Reminders), `C` (Calendar).
- [ ] 📋 Update `init.lua` to require `app_switcher.lua`.

### Acceptance Criteria
- [ ] 📋 Pressing Hyper Key + `T` focuses the Terminal app (or launches it if not running).
- [ ] 📋 The same behavior works for all other standard application bindings defined in the deliverables.

---

## Stage 3: Safari Web App Switcher Integration

### Deliverables
- [ ] 📋 Logic added to `app_switcher.lua` (or a new module) to iterate through open Safari windows/tabs using AppleScript via `hs.osascript` or Hammerspoon's native window management.
- [ ] 📋 Implementation of the following bindings based on window titles: `D` (SoundCloud), `P` (Spotify).

### Acceptance Criteria
- [ ] 📋 With Safari open and playing SoundCloud in any tab/window, pressing Hyper Key + `D` brings that specific Safari window to the front.
- [ ] 📋 With Safari open and playing Spotify in any tab/window, pressing Hyper Key + `P` brings that specific Safari window to the front.

---

## Stage 4: Copy on Select for Terminal

### Deliverables
- [ ] 📋 Hammerspoon script (`copy_on_select.lua`) tracking `leftMouseUp` events via `hs.eventtap`.
- [ ] 📋 Logic to verify the currently active application is "Terminal".
- [ ] 📋 Logic to check if a selection actually exists (to prevent clearing the clipboard on a standard click).
- [ ] 📋 Logic to trigger a `Cmd+C` keystroke after a short delay (e.g., 50ms) upon a valid selection.
- [ ] 📋 Update `init.lua` to require `copy_on_select.lua`.

### Acceptance Criteria
- [ ] 📋 Highlighting text in the native Terminal automatically copies it to the system clipboard without manual input.
- [ ] 📋 Regular clicks (without drag/selection) in the Terminal do not clear the existing clipboard content or copy an empty string.
- [ ] 📋 The feature works consistently and does not interfere with mouse actions in other applications.

---

## Stage 5: Final Refinement, Modularization, and Polish

### Deliverables
- [ ] 📋 Code refactored into a clean, modular structure, ensuring `init.lua` properly initializes and handles errors for `copy_on_select.lua` and `app_switcher.lua`.
- [ ] 📋 Final end-to-end system testing of all features simultaneously.
- [ ] 📋 Documentation updated (if needed) to reflect the final technical architecture.

### Acceptance Criteria
- [ ] 📋 All features from previous stages function correctly when loaded simultaneously from a modular `init.lua`.
- [ ] 📋 Performance is near-instantaneous, with no noticeable lag in app switching or copy-on-select.
- [ ] 📋 The configuration successfully loads and runs from the `~/.hammerspoon/` symlink without errors.
