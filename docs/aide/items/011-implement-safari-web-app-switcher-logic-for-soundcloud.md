# Work Item 011: Implement Safari Web App Switcher Logic for SoundCloud

## Description
This work item focuses on adding logic to iterate through open Safari windows and tabs to identify and focus the SoundCloud web application based on its window title, using the `D` key binding in combination with the Hyper Key.

## Acceptance Criteria
- [ ] The `app_switcher.lua` (or equivalent module) handles the `D` key press to trigger Safari tab iteration.
- [ ] The logic successfully finds a Safari tab with "SoundCloud" in its URL or title.
- [ ] The identified Safari window is brought to the front and the SoundCloud tab is made active.
- [ ] If SoundCloud is not open in any tab, the script degrades gracefully without throwing unhandled errors.
- [ ] `docs/aide/progress.md` is updated when the task status changes.

## Implementation Steps
1. Use `hs.osascript.javascript` or `hs.osascript.applescript` to query Safari for its windows and tabs.
2. Iterate over the tabs, checking if the `name` or `URL` property contains the string "SoundCloud" (case-insensitive if possible).
3. Once found, use AppleScript/JXA commands to set that specific tab as the `current tab` of its parent window.
4. Set the `index` of that parent window to `1` (or use `activate`) to bring it to the foreground.
5. Bind this logic to the `D` key via the existing Hyper Key dispatcher.

## Testing Strategy
- Local, manual testing with multiple Safari windows and tabs to ensure accurate tab targeting and application focus.

## Dependencies
- Basic Hammerspoon configuration and Hyper Key mapping (Items 001-009).
- Safari web browser running locally.

## Decisions & Trade-offs
- *To be updated during implementation.* (e.g., AppleScript vs JavaScript for Automation (JXA) for performance and reliability).

## Testing Prerequisites

**Required Services**
- Safari (native macOS application).
- Internet connection to open SoundCloud.

**Environment Configuration**
- Hammerspoon is active and using the `~/.hammerspoon` configuration.

**Manual Validation Checklist**
- [ ] **Services started**: Open Safari and load SoundCloud in a background tab. Open at least one other Safari window.
- [ ] **Application runs**: Load Hammerspoon configuration successfully.
- [ ] **Feature verified**: Press `Hyper Key + D`. Verify the SoundCloud tab becomes the active tab and its window is brought to the foreground.
- [ ] **Feature verified**: Close all SoundCloud tabs. Press `Hyper Key + D`. Verify no error alerts appear in the Hammerspoon console.

**Expected Outcomes**
- The correct Safari window and tab are brought to the forefront almost instantaneously.
- The Hammerspoon console shows no errors.

## Validation Results
- [ ] Service started: Safari
- [ ] Application started successfully: Hammerspoon configuration reloaded
- [ ] Feature verified: Correct tab focused on match
- [ ] Feature verified: Graceful fallback when no match is found
