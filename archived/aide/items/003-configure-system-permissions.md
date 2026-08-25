# Work Item: 003-configure-system-permissions

## Description
Ensure Hammerspoon is granted the necessary Accessibility, Screen Recording, and Automation permissions in macOS System Settings. These permissions are critical for Hammerspoon to monitor mouse events, control UI elements (Accessibility), capture window information (Screen Recording), and control Safari via AppleScript (Automation) for the web app switcher.

## Acceptance Criteria
- [x] Hammerspoon is granted **Accessibility** permissions in System Settings > Privacy & Security.
- [x] Hammerspoon is granted **Screen Recording** permissions (if required for window title/content inspection) in System Settings > Privacy & Security.
- [x] Hammerspoon is granted **Automation** permissions to control **Safari** (to allow for tab/window iteration via AppleScript).
- [x] A verification script or manual check confirms that Hammerspoon can access the accessibility API (e.g., `hs.accessibilityState()`).
- [x] Hammerspoon does not show permission prompts when performing basic window management or application switching.

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
- **Enabled IPC and AppleScript support**: Added `hs.ipc.cliInstall()` and `hs.allowAppleScript(true)` to `init.lua` to allow the CLI and AppleScript to communicate with Hammerspoon for automated verification.
- **Triggered prompts via CLI**: Used `hs` command to trigger Accessibility and Automation prompts, then relied on user confirmation for Screen Recording.
- **Verification via Window Titles**: Confirmed that `hs.window.allWindows()` can access titles, which validates both accessibility and the basic functional requirement of screen recording for window identification.

## Project-Specific Adaptations
- None.

## Testing Prerequisites (CRITICAL)

**Required Services**
- Hammerspoon Application (installed and running).
- Safari Application (installed).

**Environment Configuration**
- macOS with Administrator privileges (to grant permissions in System Settings).

**Manual Validation Checklist**
- [x] **Application runs**: Hammerspoon is running.
- [x] **Services started**: Safari is open.
- [x] **Feature verified**: `hs.accessibilityState()` returns `true`.
- [x] **Feature verified**: AppleScript to Safari returns a valid response without a permission prompt.
- [x] **Data verified**: N/A
- [x] **Health checks pass**: N/A

**Expected Outcomes**
- Hammerspoon has full control over the UI as required for the productivity suite.
- The Hammerspoon Console shows no "Accessibility not enabled" warnings.

## Validation Documentation Template

## Validation Results
- [x] Service started: Hammerspoon
- [x] Application started successfully
- [x] Database tables verified: N/A
- [x] Seed data verified: N/A
- [x] API endpoints verified: N/A
- [x] Screenshots captured: Optional (System Settings permission toggles)

## Completion Reminder
Note that `docs/aide/progress.md` MUST be updated (📋 → 🚧 → ✅) when the item is completed.
