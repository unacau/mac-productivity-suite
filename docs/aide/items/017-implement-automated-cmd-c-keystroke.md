# Work Item 017: Implement Automated Cmd+C Keystroke

## Description
The final step of the "copy on select" feature: trigger an automated `Cmd+C` keystroke after a valid text selection is detected in the Terminal. A short delay is added to ensure the OS has finished processing the selection event before the copy command is sent.

## Acceptance Criteria
- [x] The module uses `hs.eventtap.keyStroke` to send a `Cmd+C` command.
- [x] A short delay (e.g., 50ms) is implemented using `hs.timer.doAfter` before the keystroke is sent.
- [x] The automated copy only occurs when all previous checks (Terminal application, distance threshold) have passed.
- [x] The feature works reliably and copies the selected text to the clipboard.

## Implementation Steps
1. [x] Open `hammerspoon/copy_on_select.lua`.
2. [x] Update the `leftMouseUp` logic in the `handleEvent` function.
3. [x] Instead of (or in addition to) printing a message, add an `hs.timer.doAfter(0.05, ...)` call.
4. [x] Inside the timer callback, call `hs.eventtap.keyStroke({"cmd"}, "c")`.
5. [x] Add a debug message "Automated copy triggered in Terminal" to verify execution.
6. [x] Reload Hammerspoon and test by selecting text in Terminal.
7. [x] Verify that the selected text is now in the system clipboard.

## Testing Strategy
- Reload Hammerspoon configuration.
- Open Terminal and some other text source (e.g., this readme).
- Copy some text from the readme to the clipboard (manually).
- Select a *different* piece of text in Terminal.
- Paste into a text editor and verify that the text from Terminal was copied automatically.

## Dependencies
- Item 016 (Implement Selection Verification Logic).

## Decisions & Trade-offs
- `0.05` seconds (50ms) is a common "safe" delay for UI interactions in Hammerspoon.
- Using `hs.eventtap.keyStroke` is more reliable than trying to manipulate the clipboard directly if we want the application's native copy behavior to be respected.

## Testing Prerequisites

**Required Services**
- Hammerspoon
- macOS Terminal

**Environment Configuration**
- N/A

**Manual Validation Checklist**
- [ ] **Application runs**: Hammerspoon reloads cleanly.
- [ ] **Feature verified**: Selecting text in Terminal automatically updates the clipboard.

**Expected Outcomes**
- Fully functional "copy on select" for macOS Terminal.

## Validation Results
- [ ] Application started successfully (Hammerspoon reloads cleanly)
- [ ] Screenshots captured: N/A

## Completion Reminder
Ensure `docs/aide/progress.md` is updated (📋 → 🚧 → ✅) when this item is completed.
