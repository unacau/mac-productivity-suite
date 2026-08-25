# Work Item 006: Create App Switcher Module Skeleton

## Description
Create `app_switcher.lua` to house the application switching logic and update `init.lua` to require this new module. This work item implements Stage 2 (partial): setting up the structural skeleton for the Global App Switcher.

## Acceptance Criteria
- [ ] `hammerspoon/app_switcher.lua` exists and exports a module or function for registering application bindings.
- [ ] `hammerspoon/init.lua` successfully `require`s `app_switcher`.
- [ ] Reloading the Hammerspoon configuration throws no errors.
- [ ] `docs/aide/progress.md` is updated (📋 → 🚧 → ✅) for the corresponding items upon completion.

## Decisions & Trade-offs
- Initialized: The Hyper key is defined locally within `app_switcher.lua` for modularity.

## Completion Reminder
`docs/aide/progress.md` MUST be updated (📋 → 🚧 → ✅) when the item is completed.

## Testing Prerequisites

**Required Services**
- Hammerspoon (running on macOS)

**Environment Configuration**
- `~/.hammerspoon` must be symlinked to `hammerspoon` in this project.
- Karabiner-Elements must have the Hyper key mapped (Caps Lock -> Cmd+Opt+Ctrl+Shift).

**Manual Validation Checklist**
- [ ] **Build succeeds**: N/A (Lua is interpreted)
- [ ] **Tests pass**: N/A (No automated unit tests for this skeleton yet)
- [ ] **Services started**: Open Hammerspoon Console (`Cmd + Option + Control + W` if mapped, or via Menu Bar icon)
- [ ] **Application runs**: Click "Reload Config" in Hammerspoon.
- [ ] **Feature verified**: Verify that the Hammerspoon Console shows "Hammerspoon loaded from symlink!" and no Lua syntax or runtime errors.

**Expected Outcomes**
- A valid Lua module is created.
- `init.lua` executes cleanly without `require` failures.

## Validation Results
- [x] Service started: Hammerspoon
- [x] Application started successfully
- [x] Database tables verified: N/A
- [x] Seed data verified: N/A
- [x] API endpoints verified: N/A

## Implementation Steps

### Task 1: Create the App Switcher Module

**Files:**
- Create: `hammerspoon/app_switcher.lua`

- [ ] **Step 1: Write the module skeleton**

```lua
local AppSwitcher = {}

-- Define the Hyper key combination
local hyper = {"cmd", "alt", "ctrl", "shift"}

-- Helper function to bind a key to launch or focus an application
function AppSwitcher.bindApp(key, appName)
    hs.hotkey.bind(hyper, key, function()
        hs.application.launchOrFocus(appName)
    end)
end

return AppSwitcher
```

### Task 2: Wire the Module into init.lua

**Files:**
- Modify: `hammerspoon/init.lua`

- [ ] **Step 1: Update init.lua to require the new module**

```lua
hs.ipc.cliInstall()
hs.allowAppleScript(true)

-- Load modules
local appSwitcher = require("app_switcher")

hs.alert.show("Hammerspoon Symlink Active - API Enabled")
print("Hammerspoon loaded from symlink! IPC and AppleScript enabled.")
```

- [ ] **Step 2: Reload Hammerspoon to verify it passes**

Run: `hs -c "hs.reload()"` (Assuming Hammerspoon CLI is installed, otherwise reload via Menu Bar).
Expected: The config reloads successfully without errors in the Hammerspoon console.

## Dependencies
- Item 004 (Karabiner mapping)
- Item 005 (init.lua created)
