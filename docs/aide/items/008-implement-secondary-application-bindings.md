# Work Item 008: Implement Secondary Application Bindings

## Description
Implement Hyper Key bindings for secondary productivity and communication applications: TextMate (`M`), Telegram (`L`), and Freeform (`F`). This utilizes the `appSwitcher.bindApp` function to register these specific shortcuts for quick access.

## Acceptance Criteria
- [ ] `hammerspoon/init.lua` is updated to bind Hyper Key + `M` to focus/launch TextMate.
- [ ] `hammerspoon/init.lua` is updated to bind Hyper Key + `L` to focus/launch Telegram.
- [ ] `hammerspoon/init.lua` is updated to bind Hyper Key + `F` to focus/launch Freeform.
- [ ] Pressing these shortcuts correctly switches to or launches the respective application.
- [ ] `docs/aide/progress.md` is updated (📋 → 🚧 → ✅) for the corresponding item upon completion.

## Decisions & Trade-offs
To be updated during implementation. The application names will need to match their exact names as installed in macOS (e.g., "TextMate", "Telegram", "Freeform").

## Testing Prerequisites

**Required Services**
- Hammerspoon (running on macOS)

**Environment Configuration**
- `~/.hammerspoon` must be symlinked to `hammerspoon` in this project.
- Karabiner-Elements must have the Hyper key mapped (Caps Lock -> Cmd+Opt+Ctrl+Shift).

**Manual Validation Checklist**
- [ ] **Build succeeds**: N/A (Lua is interpreted)
- [ ] **Tests pass**: N/A
- [ ] **Services started**: Ensure Hammerspoon is running.
- [ ] **Application runs**: Click "Reload Config" in Hammerspoon.
- [ ] **Feature verified**: Press Hyper + M, Hyper + L, and Hyper + F and verify that TextMate, Telegram, and Freeform are focused or launched.
- [ ] **Health checks pass**: N/A

**Expected Outcomes**
- TextMate, Telegram, and Freeform launch or focus when their respective Hyper Key shortcuts are pressed.

## Implementation Steps

### Task 1: Implement the Secondary Bindings

**Files:**
- Modify: `hammerspoon/init.lua`

- [ ] **Step 1: Add bindings using the appSwitcher module**

Add the following lines after the existing primary bindings:

```lua
-- Secondary Application Bindings
appSwitcher.bindApp("m", "TextMate")
appSwitcher.bindApp("l", "Telegram")
appSwitcher.bindApp("f", "Freeform")
```

- [ ] **Step 2: Reload Hammerspoon to verify the bindings**

Run: `hs -c "hs.reload()"`
Expected: The config reloads successfully. Pressing Hyper+M opens TextMate.

## Completion Reminder
Note that `docs/aide/progress.md` MUST be updated (📋 → 🚧 → ✅) when this item is completed.

## Dependencies
- Item 006 (App Switcher Module Skeleton)
- Item 007 (Primary Application Bindings)
