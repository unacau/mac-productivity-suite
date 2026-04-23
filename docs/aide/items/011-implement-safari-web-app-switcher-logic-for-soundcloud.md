# Work Item 011: Implement Safari Web App Switcher Logic for SoundCloud

## Description
Add logic to iterate through open Safari windows/tabs to identify and focus the SoundCloud web application based on window title using the `D` binding. This is part of Stage 3: Safari Web App Switcher Integration.

## Acceptance Criteria
- [ ] Logic exists to iterate through open Safari windows and tabs using AppleScript via `hs.osascript` or Hammerspoon's native window management.
- [ ] The `D` binding is implemented to identify the SoundCloud web application based on its window title (e.g., matching "SoundCloud").
- [ ] Pressing Hyper Key + `D` brings the specific Safari window playing SoundCloud to the front, regardless of whether it's in a standalone window or a tab.

## Implementation Steps
1. Extend `app_switcher.lua` (or create a new `web_app_switcher.lua` module) to include functionality for searching Safari windows and tabs.
2. Implement AppleScript logic via `hs.osascript` to query Safari for tabs matching the SoundCloud title.
3. Map the Hyper Key + `D` binding to execute this search logic.
4. If a match is found, bring that specific Safari window to the front and make the matched tab active.
5. If no match is found, do nothing to avoid errors.
6. Handle edge cases where Safari is not running.

## Testing Strategy
- Open Safari with multiple tabs, including one for SoundCloud.
- Press Hyper Key + `D` and verify that the SoundCloud tab becomes active and the Safari window is brought to the front.
- Move the SoundCloud tab to a different Safari window and verify the binding still finds and focuses it.
- Close the SoundCloud tab and press the binding; verify no errors occur.
- Test with Safari completely closed.

## Dependencies
- Item 010 (Investigate Safari Web App Switcher Logic) provides the foundational knowledge for this implementation.

## Decisions & Trade-offs
To be updated during implementation.

## Testing Prerequisites

**Required Services**
- macOS Safari

**Environment Configuration**
- `~/.hammerspoon/` must be correctly symlinked to the project directory.

**Manual Validation Checklist**
- [ ] Build succeeds (Hammerspoon reloads config without errors)
- [ ] **Services started**: Safari is running with at least one window
- [ ] **Application runs**: Hammerspoon is running and responding
- [ ] **Feature verified**: Hyper + D focuses the SoundCloud tab in Safari
- [ ] **Data verified**: N/A
- [ ] **Health checks pass**: N/A

**Expected Outcomes**
- A specific function in the Lua configuration handles switching to the SoundCloud Safari tab using `hs.osascript`.
- Pressing Hyper + D reliably focuses the SoundCloud tab, making it the active tab in the frontmost Safari window.

## Validation Results
- [ ] Service started: macOS Safari
- [ ] Application started successfully (Hammerspoon reloads cleanly)
- [ ] Database tables verified: N/A
- [ ] Seed data verified: N/A
- [ ] API endpoints verified: N/A
- [ ] Screenshots captured: N/A

## Completion Reminder
Ensure `docs/aide/progress.md` is updated (📋 → 🚧 → ✅) when this item is completed.
