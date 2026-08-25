# Work Item 012: Implement Safari Web App Switcher Logic for Spotify

## Description
Add logic to iterate through open Safari windows/tabs to identify and focus the Spotify web application based on window title using the `P` binding. This is part of Stage 3: Safari Web App Switcher Integration.

## Acceptance Criteria
- [x] Logic exists to iterate through open Safari windows and tabs using AppleScript via `hs.osascript` or Hammerspoon's native window management.
- [x] The `P` binding is implemented to identify the Spotify web application based on its window title (e.g., matching "Spotify").
- [x] Pressing Hyper Key + `P` brings the specific Safari window playing Spotify to the front, regardless of whether it's in a standalone window or a tab.

## Implementation Steps
1. [x] Extend `app_switcher.lua` (or use the shared `web_app_switcher.lua` module if created for Item 011) to include functionality for searching Safari windows and tabs.
2. [x] Implement AppleScript logic via `hs.osascript` to query Safari for tabs matching the Spotify title.
3. [x] Map the Hyper Key + `P` binding to execute this search logic.
4. [x] If a match is found, bring that specific Safari window to the front and make the matched tab active.
5. [x] If no match is found, do nothing to avoid errors.
6. [x] Handle edge cases where Safari is not running.

## Testing Strategy
- Open Safari with multiple tabs, including one for Spotify (open `open.spotify.com`).
- Press Hyper Key + `P` and verify that the Spotify tab becomes active and the Safari window is brought to the front.
- Move the Spotify tab to a different Safari window and verify the binding still finds and focuses it.
- Close the Spotify tab and press the binding; verify no errors occur.
- Test with Safari completely closed.

## Dependencies
- Item 010 (Investigate Safari Web App Switcher Logic) provides the foundational knowledge for this implementation.
- Item 011 (Implement Safari Web App Switcher Logic for SoundCloud) establishes the implementation pattern.

## Decisions & Trade-offs
- Used `hs.osascript` to reliably control Safari tabs as per investigation results in Item 010.

## Testing Prerequisites

**Required Services**
- macOS Safari

**Environment Configuration**
- `~/.hammerspoon/` must be correctly symlinked to the project directory.

**Manual Validation Checklist**
- [x] Build succeeds (Hammerspoon reloads config without errors)
- [x] **Services started**: Safari is running with at least one window
- [x] **Application runs**: Hammerspoon is running and responding
- [x] **Feature verified**: Hyper + P focuses the Spotify tab in Safari
- [x] **Data verified**: N/A
- [x] **Health checks pass**: N/A

**Expected Outcomes**
- A specific function in the Lua configuration handles switching to the Spotify Safari tab using `hs.osascript`.
- Pressing Hyper + P reliably focuses the Spotify tab, making it the active tab in the frontmost Safari window.

## Validation Results
- [x] Service started: macOS Safari
- [x] Application started successfully (Hammerspoon reloads cleanly)
- [x] Database tables verified: N/A
- [x] Seed data verified: N/A
- [x] API endpoints verified: N/A
- [x] Screenshots captured: N/A

## Completion Reminder
Ensure `docs/aide/progress.md` is updated (📋 → 🚧 → ✅) when this item is completed.
