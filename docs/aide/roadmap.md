# Roadmap: Mac Productivity Suite

## Purpose
This roadmap outlines the staged development of the Mac Productivity Suite. Each stage delivers a demonstrable and testable version of the project, progressively building the functionality described in the vision.

## Stage 1: Foundation, Permissions & Hyper Key Setup
**Goal:** Establish the project environment, configure permissions, and implement the core `Caps Lock` to Hyper Key mapping.
**Deliverables:**
- Basic project directory structure initialized in `~/Igor/igorekishev/mac-productivity-suite`.
- Symlink created from the project directory to `~/.hammerspoon/` for seamless local testing.
- Hammerspoon granted necessary Accessibility and Screen Recording permissions in macOS System Settings.
- Karabiner-Elements complex modification JSON generated to map `Caps Lock` held to Hyper Key (`Cmd + Opt + Ctrl + Shift`) and `Caps Lock` tapped to `Escape`.
- Basic `init.lua` created to verify Hammerspoon is loading the configuration.
**Dependencies:**
- Karabiner-Elements and Hammerspoon installed.
**Acceptance Criteria:**
- The project directory is successfully symlinked to `~/.hammerspoon/`.
- Pressing and holding `Caps Lock` registers as `Cmd + Opt + Ctrl + Shift` in a keyboard event viewer.
- Tapping `Caps Lock` quickly registers as `Escape`.
- Hammerspoon successfully reloads its configuration without permission errors.

## Stage 2: Global App Switcher (Standard Applications)
**Goal:** Implement the core application switching logic in Hammerspoon for standard macOS applications.
**Deliverables:**
- Hammerspoon script (`app_switcher.lua`) to bind Hyper Key + letter combinations to `hs.application.launchOrFocus`.
- Implementation of the following bindings:
  - `T`: Terminal
  - `S`: Safari
  - `B`: Brave
  - `M`: TextMate
  - `L`: Telegram
  - `F`: FreeForm
  - `G`: Finder
  - `H`: Photos
  - `N`: Notes
  - `R`: Reminders
  - `C`: Calendar
- Update `init.lua` to require `app_switcher.lua`.
**Dependencies:**
- Stage 1 (Hyper Key functional and Hammerspoon configured).
**Acceptance Criteria:**
- Pressing Hyper Key + `T` focuses the Terminal app (or launches it if not running).
- The same behavior works for all other standard application bindings defined in the deliverables.

## Stage 3: Safari Web App Switcher Integration
**Goal:** Extend the application switcher to find and focus specific web applications running inside Safari tabs/windows.
**Deliverables:**
- Logic added to `app_switcher.lua` (or a new module) to iterate through open Safari windows/tabs using AppleScript via `hs.osascript` or Hammerspoon's native window management.
- Implementation of the following bindings based on window titles:
  - `D`: SoundCloud
  - `P`: Spotify
**Dependencies:**
- Stage 2 (App Switcher structure).
**Acceptance Criteria:**
- With Safari open and playing SoundCloud in any tab/window, pressing Hyper Key + `D` brings that specific Safari window to the front.
- With Safari open and playing Spotify in any tab/window, pressing Hyper Key + `P` brings that specific Safari window to the front.

## Stage 4: Copy on Select for Terminal
**Goal:** Implement automated clipboard functionality when selecting text in the native macOS Terminal application.
**Deliverables:**
- Hammerspoon script (`copy_on_select.lua`) tracking `leftMouseUp` events via `hs.eventtap`.
- Logic to verify the currently active application is "Terminal".
- Logic to check if a selection actually exists (to prevent clearing the clipboard on a standard click).
- Logic to trigger a `Cmd+C` keystroke after a short delay (e.g., 50ms) upon a valid selection.
- Update `init.lua` to require `copy_on_select.lua`.
**Dependencies:**
- Stage 1 (Hammerspoon environment and permissions).
**Acceptance Criteria:**
- Highlighting text in the native Terminal automatically copies it to the system clipboard without manual input.
- Regular clicks (without drag/selection) in the Terminal do not clear the existing clipboard content or copy an empty string.
- The feature works consistently and does not interfere with mouse actions in other applications.

## Stage 5: Final Refinement, Modularization, and Polish
**Goal:** Polish the codebase, ensure maintainability, and finalize the deployment structure.
**Deliverables:**
- Code refactored into a clean, modular structure, ensuring `init.lua` properly initializes and handles errors for `copy_on_select.lua` and `app_switcher.lua`.
- Final end-to-end system testing of all features simultaneously.
- Documentation updated (if needed) to reflect the final technical architecture.
**Dependencies:**
- Stages 1-4.
**Acceptance Criteria:**
- All features from previous stages function correctly when loaded simultaneously from a modular `init.lua`.
- Performance is near-instantaneous, with no noticeable lag in app switching or copy-on-select.
- The configuration successfully loads and runs from the `~/.hammerspoon/` symlink without errors.
