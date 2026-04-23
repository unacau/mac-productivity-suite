# Work Item 011: Implement Safari Web App Switcher Logic for SoundCloud

## Description
Add logic to iterate through open Safari windows/tabs to identify and focus the SoundCloud web application based on window title using the `D` binding. This implements the first part of Stage 3: Safari Web App Switcher Integration.

## Acceptance Criteria
- With Safari open and playing SoundCloud in any tab/window, pressing Hyper Key + `D` brings that specific Safari window to the front.
- `docs/aide/progress.md` is updated (📋 → 🚧 → ✅) upon completion of this item.

## Implementation Steps
1. Add logic to `app_switcher.lua` (or a dedicated `safari_switcher.lua` module) to search for Safari tabs/windows containing "SoundCloud" in their title.
2. The logic can utilize `hs.osascript` to run a small AppleScript that iterates through Safari windows and tabs, or `hs.application` if it can read window titles directly.
3. Bind Hyper Key + `D` to this new logic.
4. If a new file is created, require it in `init.lua`.

## Testing Strategy
1. Open Safari and navigate to `soundcloud.com`.
2. Open another app (e.g., Terminal) or a different Safari window so SoundCloud is in the background.
3. Press Hyper Key + `D` and verify that the SoundCloud window comes to the foreground.

## Dependencies
- `app_switcher.lua`
- Hammerspoon accessibility permissions.

## Decisions & Trade-offs
- To be updated during implementation.

## Testing Prerequisites

**Required Services**
- N/A

**Environment Configuration**
- macOS with Safari installed.
- Hammerspoon running with the project configuration loaded.

**Manual Validation Checklist**
- [ ] **Application runs**: Hammerspoon configuration reloaded successfully.
- [ ] **Feature verified**: Open Safari to SoundCloud, switch to another app, press Hyper + D, and verify Safari with SoundCloud is focused.

**Expected Outcomes**
- The Safari window with SoundCloud is focused when the keybind is pressed.

## Validation Results
- [ ] Application started successfully: Hammerspoon reloaded without errors.
- [ ] Feature verified: Safari focused correctly.
