# Work Item 016: Implement Selection Verification Logic

## Description
Implement logic to verify that a text selection actually occurred in the Terminal before attempting to copy. This prevents the script from triggering a copy command on standard clicks, which would otherwise clear the clipboard or cause unnecessary overhead.

## Acceptance Criteria
- [x] The module tracks the mouse position during `leftMouseDown` events.
- [x] The module compares the `leftMouseDown` position with the `leftMouseUp` position.
- [x] A minimum "drag distance" threshold is defined (e.g., 5 pixels).
- [x] If the distance moved between mouse down and mouse up is below the threshold, it's treated as a simple click and no further action is taken.
- [x] If the distance is above the threshold, it's treated as a selection.

## Implementation Steps
1. [x] Open `hammerspoon/copy_on_select.lua`.
2. [x] Add a local `mouseDownPos` variable to the `CopyOnSelect` table (or top level) to store the starting coordinates.
3. [x] Update the `init()` function to listen for `leftMouseDown` events as well as `leftMouseUp`.
4. [x] Implement a handler for `leftMouseDown` that records the current mouse position using `hs.mouse.getAbsolutePosition()`.
5. [x] In the `leftMouseUp` handler:
    - [x] Only proceed if the application is "Terminal".
    - [x] Get the current mouse position.
    - [x] Calculate the Euclidean distance (or just check if x or y changed by more than a threshold) from `mouseDownPos`.
    - [x] Only print "Selection detected in Terminal" if the threshold is met.
6. [x] Reload Hammerspoon and verify that clicks do not trigger the message, but drags do.

## Testing Strategy
- Reload Hammerspoon configuration.
- Open Terminal.
- Click inside the Terminal window without moving the mouse. Verify no message appears.
- Drag the mouse to select text. Verify "Selection detected in Terminal" appears.
- Perform very small movements (1-2 pixels) and verify they are ignored based on the threshold.

## Dependencies
- Item 015 (Implement Terminal Application Verification Logic).

## Decisions & Trade-offs
- Distance threshold helps ignore accidental micro-movements during clicks.
- Using Euclidean distance `sqrt((x2-x1)^2 + (y2-y1)^2)` is more precise than simple coordinate comparison.

## Testing Prerequisites

**Required Services**
- Hammerspoon
- macOS Terminal

**Environment Configuration**
- N/A

**Manual Validation Checklist**
- [ ] **Application runs**: Hammerspoon reloads cleanly.
- [ ] **Feature verified**: Clicks are ignored, drags are detected as selections.

**Expected Outcomes**
- Robust detection of user intention (selection vs click).

## Validation Results
- [ ] Application started successfully (Hammerspoon reloads cleanly)
- [ ] Screenshots captured: N/A

## Completion Reminder
Ensure `docs/aide/progress.md` is updated (📋 → 🚧 → ✅) when this item is completed.
