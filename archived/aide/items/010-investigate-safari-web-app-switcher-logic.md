# Work Item: Investigate Safari Web App Switcher Logic

## Description
Research and implement the core logic to iterate through open Safari windows and tabs to identify and focus specific web applications based on their titles. This forms the foundation for mapping Hyper Key shortcuts to specific web apps (like SoundCloud and Spotify) running within Safari.

## Acceptance Criteria
- [x] Logic successfully identifies a Safari tab by its title (or a substring of its title).
- [x] If the tab is found, Safari is brought to the front.
- [x] If the tab is found, the specific window containing the tab is brought to the front.
- [x] If the tab is found, it is made the active tab within its window.
- [x] The logic is encapsulated in a reusable Hammerspoon function within `app_switcher.lua` (e.g., `focusSafariTab(titleSubstring)`).
- [x] Bindings are implemented for SoundCloud (Hyper + D) and Spotify (Hyper + P).

## Implementation Steps
- [x] **Research AppleScript for Safari:** Investigated AppleScript to iterate through Safari windows/tabs and focus a specific one by title.
- [x] **Develop AppleScript Wrapper:** Implemented `AppSwitcher.bindSafariTab` in `app_switcher.lua` using `hs.osascript`.
- [x] **Handle Permissions:** Verified that Hammerspoon requires Automation/Apple Events permission for Safari.
- [x] **Implement Bindings:** Added Hyper + D and Hyper + P bindings in `init.lua`.

## Testing Strategy
1. Open multiple Safari windows with multiple tabs.
2. Ensure one tab is playing SoundCloud and another is playing Spotify.
3. Switch to a completely different application (e.g., Terminal).
4. Trigger the Hyper + D shortcut and verify that the SoundCloud tab becomes active and Safari comes to the front.
5. Repeat for the Hyper + P shortcut and Spotify.

## Dependencies
- `app_switcher.lua` (must exist and be loaded by `init.lua`).
- macOS System Settings: Hammerspoon requires permission to control Safari via Apple Events (Privacy & Security -> Automation).

## Decisions & Trade-offs
- **AppleScript vs Native Hammerspoon:** Chose AppleScript because Safari's tab management is not fully exposed to standard Accessibility APIs used by `hs.window`. AppleScript provides reliable access to tab names and allows setting the `current tab`.
- **String Formatting:** Used `string.format` to inject the search substring into the AppleScript. While this could have quoting issues if the title contained double quotes, it's sufficient for "SoundCloud" and "Spotify" as specified.
- **Automation Permissions:** Explicitly noted that macOS will prompt the user for permission when the script first tries to control Safari.

## Completion Reminder
When this item is completed, update `docs/aide/progress.md` (📋 → 🚧 → ✅).

## Testing Prerequisites

**Required Services**
- N/A

**Environment Configuration**
- Safari must be installed and running.
- macOS System Settings -> Privacy & Security -> Automation -> Hammerspoon must be allowed to control "Safari".

**Manual Validation Checklist**
- [ ] **Services started**: Open Safari.
- [ ] **Data verified**: Open a tab to `soundcloud.com` and another to `spotify.com` (or web player).
- [ ] **Application runs**: Ensure Hammerspoon configuration is reloaded.
- [ ] **Feature verified**: Press Hyper + D. Safari should focus on the SoundCloud tab.
- [ ] **Feature verified**: Press Hyper + P. Safari should focus on the Spotify tab.
- [ ] **Feature verified**: Test when the target tab is in a minimized window or a different window than the currently active Safari window.

**Expected Outcomes**
- A reusable Lua function that can focus any Safari tab by name.
- Working Hyper Key shortcuts for SoundCloud and Spotify web apps.

## Validation Documentation Template

```markdown
## Validation Results
- [ ] Service started: Safari
- [ ] Application started successfully: Hammerspoon configuration loaded without errors.
- [ ] Database tables verified: N/A
- [ ] Seed data verified: N/A
- [ ] API endpoints verified: N/A
- [ ] Screenshots captured: N/A
```
