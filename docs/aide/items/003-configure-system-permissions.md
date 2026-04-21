# Work Item: 003-configure-system-permissions

## Description
Ensure Hammerspoon is granted the necessary Accessibility and Screen Recording permissions in macOS System Settings. These permissions are critical for Hammerspoon to monitor mouse events, control UI elements, and manage window switching effectively.

## Acceptance Criteria
- [ ] Hammerspoon is granted **Accessibility** permissions in System Settings > Privacy & Security.
- [ ] Hammerspoon is granted **Screen Recording** permissions (if required for window title/content inspection) in System Settings > Privacy & Security.
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
4. **Verification**:
    - Run `hs.accessibilityState()` in the Hammerspoon Console to confirm access.
    - Test a simple script that interacts with a window to ensure it works without errors.

## Testing Strategy
### Manual Verification
- Open the Hammerspoon Console and run `print(hs.accessibilityState())`. It should return `true`.
- Attempt to focus a window using `hs.window.focusedWindow()` and ensure it returns a valid window object.

## Dependencies
- Item 002: Setup Local Testing Symlink (so Hammerspoon is running the configuration from this repo).

## Decisions & Trade-offs
- **To be updated during implementation.**

## Project-Specific Adaptations
- None.

## Testing Prerequisites (CRITICAL)

**Required Services**
- Hammerspoon Application (installed and running).

**Environment Configuration**
- macOS with Administrator privileges (to grant permissions in System Settings).

**Manual Validation Checklist**
- [ ] **Application runs**: Hammerspoon is running.
- [ ] **Services started**: N/A
- [ ] **Feature verified**: `hs.accessibilityState()` returns `true`.
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
