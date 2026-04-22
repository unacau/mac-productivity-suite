# Work Item 009: Implement System Application Bindings

## Description
Implement Hyper Key bindings for built-in macOS system applications: Finder (`G`), Photos (`H`), Notes (`N`), Reminders (`R`), and Calendar (`C`). This utilizes the `appSwitcher.bindApp` function to register these specific shortcuts for quick access.

## Acceptance Criteria
- [ ] `hammerspoon/init.lua` is updated to bind Hyper Key + `G` to focus/launch Finder.
- [ ] `hammerspoon/init.lua` is updated to bind Hyper Key + `H` to focus/launch Photos.
- [ ] `hammerspoon/init.lua` is updated to bind Hyper Key + `N` to focus/launch Notes.
- [ ] `hammerspoon/init.lua` is updated to bind Hyper Key + `R` to focus/launch Reminders.
- [ ] `hammerspoon/init.lua` is updated to bind Hyper Key + `C` to focus/launch Calendar.
- [ ] Pressing these shortcuts correctly switches to or launches the respective built-in application.
- [ ] `docs/aide/progress.md` is updated (📋 → 🚧 → ✅) for the corresponding item upon completion.

## Decisions & Trade-offs
To be updated during implementation. The application names will need to match their exact names as installed in macOS (e.g., "Finder", "Photos", "Notes", "Reminders", "Calendar").

## Implementation Steps

### Task 1: Implement the System Application Bindings

**Files:**
- Modify: `hammerspoon/init.lua`

- [ ] **Step 1: Add bindings using the appSwitcher module**

Add the following lines after the existing secondary bindings:

```lua
-- System Application Bindings
appSwitcher.bindApp("g", "Finder")
appSwitcher.bindApp("h", "Photos")
appSwitcher.bindApp("n", "Notes")
appSwitcher.bindApp("r", "Reminders")
appSwitcher.bindApp("c", "Calendar")
```

- [ ] **Step 2: Reload Hammerspoon to verify the bindings**

Run: `hs -c "hs.reload()"`
Expected: The config reloads successfully. Pressing the configured Hyper+Key combinations opens their respective applications.

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
- [ ] **Feature verified**: Press Hyper + G, H, N, R, and C and verify that Finder, Photos, Notes, Reminders, and Calendar are focused or launched.
- [ ] **Data verified**: N/A
- [ ] **Health checks pass**: N/A

**Expected Outcomes**
- Finder, Photos, Notes, Reminders, and Calendar launch or focus when their respective Hyper Key shortcuts are pressed.

## Validation Results
- [ ] Service started: Hammerspoon
- [ ] Application started successfully
- [ ] Database tables verified: N/A
- [ ] Seed data verified: N/A
- [ ] API endpoints verified: N/A
- [ ] Screenshots captured: N/A

## Completion Reminder
Note that `docs/aide/progress.md` MUST be updated (📋 → 🚧 → ✅) when this item is completed.

## Dependencies
- Item 006 (App Switcher Module Skeleton)
- Item 008 (Secondary Application Bindings)