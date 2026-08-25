# Work Item 015: Implement Terminal Application Verification Logic

## Description
Refine the `leftMouseUp` event handler to only perform further logic if the currently active application is the native macOS "Terminal" app. This ensures that the automated copy behavior is scoped strictly to the Terminal and doesn't affect other applications.

## Acceptance Criteria
- [x] The event handler in `copy_on_select.lua` correctly identifies the currently focused application.
- [x] The logic checks if the application's name matches "Terminal".
- [x] If the application is NOT "Terminal", the function returns early without printing any "Mouse Up detected" messages.
- [x] If the application IS "Terminal", the function continues (and prints the message for now).

## Implementation Steps
1. [x] Open `hammerspoon/copy_on_select.lua`.
2. [x] Inside the `handleEvent` function, use `hs.application.frontmostApplication()` to get the current application.
3. [x] Call `:title()` (or `:name()`) on the application object to get its name.
4. [x] Add an `if` statement to check if the name matches "Terminal".
5. [x] Return `false` immediately if it doesn't match.
6. [x] Only print "Mouse Up detected in Terminal" if it matches.
7. [x] Reload Hammerspoon and verify the message only appears when clicking inside a Terminal window.

## Testing Strategy
- Reload Hammerspoon configuration.
- Open the Hammerspoon Console.
- Click in any application *other* than Terminal (e.g., Safari, TextMate). Verify no message appears.
- Open Terminal and click inside its window. Verify "Mouse Up detected in Terminal" appears in the console.

## Dependencies
- Item 014 (Implement leftMouseUp Event Tracking).

## Decisions & Trade-offs
- Using `frontmostApplication():title()` is generally reliable for standard macOS apps.
- The return value of the handler must always be `false` to ensure standard mouse behavior is not blocked.

## Testing Prerequisites

**Required Services**
- Hammerspoon
- macOS Terminal

**Environment Configuration**
- N/A

**Manual Validation Checklist**
- [ ] **Application runs**: Hammerspoon reloads cleanly.
- [ ] **Feature verified**: "Mouse Up detected in Terminal" only appears when Terminal is active.

**Expected Outcomes**
- Context-aware event handling that targets only the Terminal application.

## Validation Results
- [ ] Application started successfully (Hammerspoon reloads cleanly)
- [ ] Screenshots captured: N/A

## Completion Reminder
Ensure `docs/aide/progress.md` is updated (📋 → 🚧 → ✅) when this item is completed.
