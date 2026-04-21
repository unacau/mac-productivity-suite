# Work Item: 003-configure-system-permissions

## Description
Ensure Hammerspoon is granted the necessary Accessibility, Screen Recording, and Automation permissions in macOS System Settings. These permissions are critical for Hammerspoon to monitor mouse events, control UI elements (Accessibility), capture window information (Screen Recording), and control Safari via AppleScript (Automation) for the web app switcher.

## Acceptance Criteria
- [ ] Hammerspoon is granted **Accessibility** permissions in System Settings > Privacy & Security.
- [ ] Hammerspoon is granted **Screen Recording** permissions (if required for window title/content inspection) in System Settings > Privacy & Security.
- [ ] Hammerspoon is granted **Automation** permissions to control **Safari** (to allow for tab/window iteration via AppleScript).
- [ ] A verification script or manual check confirms that Hammerspoon can access the accessibility API (e.g., `hs.accessibilityState()`).
- [ ] Hammerspoon does not show permission prompts when performing basic window management or application switching.

## Implementation Steps
1. **Initial Check**: Open Hammerspoon and check the console/log for any permission-related warnings.
2. **Accessibility Permission**:
    - Navigate to `System Settings` > `Privacy & Security` > `Accessibility`.
    - Ensure Hammerspoon is in the list and toggled **ON**.
    - If not present, add it manually or trigger the prompt by running a script that requires accessibility.
3. **Screen Recording Permission**:
    - Navigate to `System Settings` > `Privacy & Security` > `Screen Recording`.
    - Ensure Hammerspoon is in the list and toggled **ON**.
4. **Automation Permission (Safari)**:
    - Trigger a prompt by running a simple AppleScript via Hammerspoon: `hs.osascript.applescript('tell application "Safari" to return count windows')`.
    - When the macOS prompt appears, click **OK**.
    - Verify in `System Settings` > `Privacy & Security` > `Automation`.
5. **Verification**:
    - Run `hs.accessibilityState()` in the Hammerspoon Console to confirm access.
    - Run the AppleScript above and verify it returns a number (even `0`).

## Testing Strategy
### Manual Verification
- Open the Hammerspoon Console and run `print(hs.accessibilityState())`. It should return `true`.
- Attempt to focus a window using `hs.window.focusedWindow()` and ensure it returns a valid window object.
- Run `hs.osascript.applescript('tell application "Safari" to return count windows')` and ensure it doesn't error out.

## Dependencies
- Item 002: Setup Local Testing Symlink (so Hammerspoon is running the configuration from this repo).

## Decisions & Trade-offs
- **To be updated during implementation.**

## Project-Specific Adaptations
- None.

## Testing Prerequisites (CRITICAL)

**Required Services**
- Hammerspoon Application (installed and running).
- Safari Application (installed).

**Environment Configuration**
- macOS with Administrator privileges (to grant permissions in System Settings).

**Manual Validation Checklist**
- [ ] **Application runs**: Hammerspoon is running.
- [ ] **Services started**: Safari is open.
- [ ] **Feature verified**: `hs.accessibilityState()` returns `true`.
- [ ] **Feature verified**: AppleScript to Safari returns a valid response without a permission prompt.
- [ ] **Data verified**: N/A
- [ ] **Health checks pass**: N/A

**Expected Outcomes**
- Hammerspoon has full control over the UI as required for the productivity suite.
- The Hammerspoon Console shows no "Accessibility not enabled" warnings.

## Validation Documentation Template

```markdown
## Validation Results
- [ ] Service started: Hammerspoon
- [ ] Application started successfully
- [ ] Database tables verified: N/A
- [ ] Seed data verified: N/A
- [ ] API endpoints verified: N/A
- [ ] Screenshots captured: Optional (System Settings permission toggles)
```

## Completion Reminder
Note that `docs/aide/progress.md` MUST be updated (📋 → 🚧 → ✅) when the item is completed.
