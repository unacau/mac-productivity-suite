# Work Item 014: Implement leftMouseUp Event Tracking

## Description
Set up an `hs.eventtap` to track `leftMouseUp` events globally. This is the first step in detecting text selections in the Terminal, as a selection is typically finalized when the user releases the left mouse button.

## Acceptance Criteria
- [x] An `hs.eventtap` is created and started within the `CopyOnSelect.init()` function.
- [x] The event tap specifically listens for `leftMouseUp` events.
- [x] A callback function is implemented that logs a message to the Hammerspoon console whenever a `leftMouseUp` event occurs (for verification).
- [x] The event tap is correctly assigned to a variable in the `CopyOnSelect` table to prevent it from being garbage collected.

## Implementation Steps
1. [x] Open `hammerspoon/copy_on_select.lua`.
2. [x] Inside `CopyOnSelect.init()`, create an `hs.eventtap` using `hs.eventtap.new`.
3. [x] Configure the event tap to listen for `{hs.eventtap.event.types.leftMouseUp}`.
4. [x] Implement a callback function that prints "Mouse Up detected" to the console.
5. [x] Start the event tap using `eventtap:start()`.
6. [x] Store the event tap instance in `CopyOnSelect.tap`.
7. [x] Reload Hammerspoon and verify that mouse clicks trigger the console message.

## Testing Strategy
- Reload Hammerspoon configuration.
- Open the Hammerspoon Console (`hs.openConsole()`).
- Click anywhere on the screen and release the mouse button.
- Verify that "Mouse Up detected" appears in the console.

## Dependencies
- Item 013 (Copy on Select Module Skeleton).

## Decisions & Trade-offs
- Using `hs.eventtap` is the standard way to monitor global mouse/keyboard events in Hammerspoon.
- The callback must return `false` (or nothing) to allow the event to propagate to other applications; otherwise, mouse clicks would be "swallowed" by Hammerspoon.

## Testing Prerequisites

**Required Services**
- Hammerspoon

**Environment Configuration**
- N/A

**Manual Validation Checklist**
- [ ] **Application runs**: Hammerspoon reloads cleanly.
- [ ] **Feature verified**: Mouse clicks trigger "Mouse Up detected" in the console.

**Expected Outcomes**
- A working global event listener for mouse releases.

## Validation Results
- [ ] Application started successfully (Hammerspoon reloads cleanly)
- [ ] Screenshots captured: N/A

## Completion Reminder
Ensure `docs/aide/progress.md` is updated (📋 → 🚧 → ✅) when this item is completed.
