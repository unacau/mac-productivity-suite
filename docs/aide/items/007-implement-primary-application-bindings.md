# Work Item 007: Implement Primary Application Bindings

## Description
Implement Hyper Key bindings for primary applications: Terminal (`T`), Safari (`S`), and Brave (`B`). This utilizes the `AppSwitcher.bindApp` function (created in Item 006) to register these specific shortcuts for quick access.

## Acceptance Criteria
- [ ] `hammerspoon/init.lua` is updated to bind Hyper Key + `T` to focus/launch Terminal.
- [ ] `hammerspoon/init.lua` is updated to bind Hyper Key + `S` to focus/launch Safari.
- [ ] `hammerspoon/init.lua` is updated to bind Hyper Key + `B` to focus/launch Brave Browser.
- [ ] Pressing these shortcuts correctly switches to or launches the respective application.
- [ ] `docs/aide/progress.md` is updated (📋 → 🚧 → ✅) for the corresponding items upon completion.

## Decisions & Trade-offs
To be updated during implementation.

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
- [ ] **Feature verified**: Press Hyper + T, Hyper + S, and Hyper + B and verify that Terminal, Safari, and Brave are focused or launched.
- [ ] **Health checks pass**: N/A

**Expected Outcomes**
- Terminal, Safari, and Brave launch or focus when their respective Hyper Key shortcuts are pressed.

## Implementation Steps

### Task 1: Implement the Bindings

**Files:**
- Modify: `hammerspoon/init.lua`

- [ ] **Step 1: Add bindings using the AppSwitcher module**

Add the following lines after requiring `app_switcher`:

```lua
appSwitcher.bindApp("t", "Terminal")
appSwitcher.bindApp("s", "Safari")
appSwitcher.bindApp("b", "Brave Browser")
```

- [ ] **Step 2: Reload Hammerspoon to verify the bindings**

Run: `hs -c "hs.reload()"`
Expected: The config reloads successfully. Pressing Hyper+T opens Terminal.

## Completion Reminder
Note that `docs/aide/progress.md` MUST be updated (📋 → 🚧 → ✅) when this item is completed.

## Dependencies
- Item 006 (App Switcher Module Skeleton) must be completed first to provide the `AppSwitcher` module.
