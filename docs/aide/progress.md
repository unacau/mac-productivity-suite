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
- [x] ✅ Basic project directory structure initialized in `~/Igor/igorekishev/mac-productivity-suite`.
- [x] ✅ Symlink created from the project directory to `~/.hammerspoon/` for seamless local testing.
- [x] ✅ Hammerspoon granted necessary Accessibility and Screen Recording permissions in macOS System Settings.
- [x] ✅ Karabiner-Elements complex modification JSON generated to map `Caps Lock` held to Hyper Key (`Cmd + Opt + Ctrl + Shift`) and `Caps Lock` tapped to `Escape`.
- [x] ✅ Basic `init.lua` created to verify Hammerspoon is loading the configuration.

### Acceptance Criteria
- [x] ✅ The project directory is successfully symlinked to `~/.hammerspoon/`.
- [x] ✅ Pressing and holding `Caps Lock` registers as `Cmd + Opt + Ctrl + Shift` in a keyboard event viewer.
- [x] ✅ Tapping `Caps Lock` quickly registers as `Escape`.
- [x] ✅ Hammerspoon successfully reloads its configuration without permission errors.

---

## Stage 2: Global App Switcher (Standard Applications)

### Deliverables
- [x] ✅ Hammerspoon script (`app_switcher.lua`) to bind Hyper Key + letter combinations to `hs.application.launchOrFocus`.
- [ ] 🚧 Implementation of the following bindings: `T` (Terminal), `S` (Safari), `B` (Brave), `M` (TextMate), `L` (Telegram), `F` (Freeform), `G` (Finder), `H` (Photos), `N` (Notes), `R` (Reminders), `C` (Calendar).
- [x] ✅ Update `init.lua` to require `app_switcher.lua`.

### Acceptance Criteria
- [x] ✅ Pressing Hyper Key + `T` focuses the Terminal app (or launches it if not running).
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

---

## Detailed Work Items

| ID | Status | Title | Spec |
| :--- | :--- | :--- | :--- |
| 001 | ✅ | Initialize project directory structure | [001](items/001-initialize-project-directory-structure.md) |
| 002 | ✅ | Setup local testing symlink | [002](items/002-setup-local-testing-symlink.md) |
| 003 | ✅ | Configure system permissions | [003](items/003-configure-system-permissions.md) |
| 004 | ✅ | Generate Karabiner-Elements Hyper Key mapping | [004](items/004-generate-karabiner-elements-hyper-key-mapping.md) |
| 005 | ✅ | Create basic init.lua | [005](items/005-create-basic-init-lua.md) |
| 006 | ✅ | Create app switcher module skeleton | [006](items/006-create-app-switcher-module-skeleton.md) |
| 007 | ✅ | Implement primary application bindings | [007](items/007-implement-primary-application-bindings.md) |
| 008 | ✅ | Implement secondary application bindings | [008](items/008-implement-secondary-application-bindings.md) |
| 009 | 🚧 | Implement system application bindings | [009](items/009-implement-system-application-bindings.md) |
| 010 | 📋 | Investigate Safari web app switcher logic | [010](items/010-investigate-safari-web-app-switcher-logic.md) |
