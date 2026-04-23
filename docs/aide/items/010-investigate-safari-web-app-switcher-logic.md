# Work Item: Investigate Safari Web App Switcher Logic

## Description
Research and implement the core logic to iterate through open Safari windows and tabs to identify and focus specific web applications based on their titles. This forms the foundation for mapping Hyper Key shortcuts to specific web apps (like SoundCloud and Spotify) running within Safari.

## Acceptance Criteria
- [ ] Logic successfully identifies a Safari tab by its title (or a substring of its title).
- [ ] If the tab is found, Safari is brought to the front.
- [ ] If the tab is found, the specific window containing the tab is brought to the front.
- [ ] If the tab is found, it is made the active tab within its window.
- [ ] The logic is encapsulated in a reusable Hammerspoon function within `app_switcher.lua` (e.g., `focusSafariTab(titleSubstring)`).
- [ ] Bindings are implemented for SoundCloud (Hyper + D) and Spotify (Hyper + P).

## Implementation Steps
1. **Research AppleScript for Safari:** Investigate the required AppleScript syntax to iterate through Safari windows and tabs, find a tab by title, and make it active.
2. **Develop AppleScript Wrapper:** Create a Lua function in `app_switcher.lua` that uses `hs.osascript` to execute the AppleScript logic.
3. **Handle Permissions:** Document and handle the requirement for Hammerspoon to have Automation/Apple Events permissions to control Safari.
4. **Implement Bindings:** Add the specific Hyper Key bindings for SoundCloud (`D`) and Spotify (`P`) to `app_switcher.lua` using the new wrapper function.

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
- To be updated during implementation. (e.g., Considering native Hammerspoon window management vs. AppleScript. AppleScript is generally required for tab-level control in Safari).

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
