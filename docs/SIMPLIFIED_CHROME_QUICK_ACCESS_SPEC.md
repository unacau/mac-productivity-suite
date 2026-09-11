# Specification: Native Chrome Profile Quick-Access (Caps-Lock + C)

## 1. Vision & Core Objective
Build a lightweight, hyper-focused, pure native macOS standalone application (Swift 6+) dedicated to a **single function**:
**Instant, zero-latency global switching to Google Chrome and its individual profiles using Caps-Lock + `C` (and numeric profile selectors `1`–`4`).**

This replaces the dual-layer Hammerspoon (`chrome_profiles.lua`) + Karabiner-Elements (`hyper-key-mapping.json`) configuration with a 100% native, driverless Swift daemon.

---

## 2. Keystroke & Modifier Interaction Model

```
               ┌────────────────────────────────────────────────────────┐
               │                  Physical Caps-Lock                    │
               └───────────────────────────┬────────────────────────────┘
                                           │
                    Remapped via hidutil to F18 (0x70000006D)
                                           │
                                           ▼
                            ┌────────────────────────────┐
                            │    CGEventTap (HeadInsert) │
                            └──────────────┬─────────────┘
                                           │
              ┌────────────────────────────┴────────────────────────────┐
              │                                                         │
       Tapped Alone (<250ms)                                      Held Down
              │                                                         │
              ▼                                                         ▼
     Emit Synthetic ESC                                         Act as Hyper Modifier
  (Matching Karabiner UX)                                               │
                                               ┌────────────────────────┴───────────────────────┐
                                               │                                                │
                                         + Key "C"                                      + Key "1".."4"
                                               │                                                │
                                               ▼                                                ▼
                                    Focus Google Chrome                           Focus Specific Profile
                                  (Last active or profile 1)                       (1=Personal, 2=Work, etc.)
```

### Key Behaviors:
1. **Dual-Role Caps-Lock (Tapped vs Held)**:
   - **Tapped Alone**: When released without pressing any other key, synthesizes an `Escape` key event (`kVK_Escape`, `0x35`). Essential for Vim users, dismissing dialogs, and preserving standard hyper-key ergonomics.
   - **Held as Modifier**: Suppresses Caps-Lock LED toggle. Becomes the trigger for application shortcuts.
2. **Primary Shortcut (`Caps-Lock + C`)**:
   - If Chrome is not running: Cold-starts Chrome with the default / last-used profile via `/usr/bin/open -b com.google.Chrome`.
   - If Chrome is in background: Activates Chrome and raises its primary window.
   - If Chrome is already frontmost: Cycles between open profiles or opens the quick profile selector HUD.
3. **Numeric Profile Direct-Switch (`Caps-Lock + 1..4` or `Caps-Lock + C + 1..4`)**:
   - Instantly jumps directly to the corresponding Chrome profile window.
   - If the window for that profile is minimized or hidden, unminimizes and raises it without opening unwanted empty tabs.

---

## 3. Proven Native Architecture & Key Subsystems

All core logic for this simplified app is already proven in `src/NativeStandaloneApp/Engine/`. The new app extracts only these two modules into an ultra-lean footprint:

### Module A: Native Event Tap & HID Service (`HyperKeyEngine.swift`)
- **Driverless Hardware Remapping**:
  ```swift
  // Caps Lock (0x700000039) -> F18 (0x70000006D)
  /usr/bin/hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x70000006D}]}'
  ```
- **Event Tap**:
  - `CGEvent.tapCreate(tap: .cghidEventTap, place: .headInsertEventTap, ...)`
  - Handles `kCGEventTapDisabledByTimeout` / `kCGEventTapDisabledByUserInput` by auto-enabling.
  - Re-applies HID mapping upon wake (`NSWorkspace.didWakeNotification`).
  - Swallows F18 down/up and handled shortcut keys so the system doesn't beep or insert characters.

### Module B: Chrome Profile Discovery & Activation (`ChromeProfileHelper.swift`)
- **Zero Hardcoding**:
  - Discovers profiles dynamically by parsing `~/Library/Application Support/Google/Chrome/Local State` (`profile.info_cache`).
  - Resolves profile directory (`Default`, `Profile 1`, `Profile 2`), GAIA name, custom name, email, and avatar image.
- **Zero AppleScript UI Automation**:
  - Automates via native macOS Accessibility API (`AXUIElementCopyAttributeValue`, `kAXMenuBarAttribute`, `Profiles` menu item).
  - Matches profiles cleanly without ambiguous substring matching.
  - Unminimizes minimized windows via `kAXWindowsAttribute` and `kAXMinimizedAttribute`.
  - Fallback cold start: `/usr/bin/open -b com.google.Chrome --args --profile-directory='<dir>'`.

---

## 4. What Is Eliminated (Scope Reduction)
To achieve the "totally new simplified version from scratch", the following legacy components from `mac-productivity-suite` are **completely stripped**:
- ❌ Multi-app switcher matrices (`AppSwitcherEngine.swift` candidate lists for Finder, Terminal, Slack, Notes, etc.).
- ❌ Global copy-on-select drag listener (`CopyOnSelectEngine.swift`).
- ❌ Finder dual-column tiling (`finderSplitEnabled`).
- ❌ Quick Notes markdown highlighting (`quickNotesEnabled`).
- ❌ Multi-tab SwiftUI preferences window (`SettingsWindow.swift`, `AppPickerSheet.swift`).
- ❌ Hammerspoon Lua scripts (`hammerspoon/`).
- ❌ Karabiner-Elements dependency (`karabiner/`).

---

## 5. File Structure for the Simplified Project

```
SimplifiedChromeSwitcher/
├── Package.swift               # Lean SPM package (AppKit, SwiftUI, Sparkle optional)
├── Sources/
│   ├── main.swift              # App entry point
│   ├── AppDelegate.swift       # Menu bar status item & lifecycle management
│   ├── Engine/
│   │   ├── CapsLockTapEngine.swift  # hidutil Caps->F18 + CGEventTap dual-role Escape
│   │   └── ChromeProfileEngine.swift # Local State parser + AX menu bar switcher
│   └── Views/
│       ├── ProfileHUDView.swift     # Minimal non-activating bezel HUD (optional)
│       └── MenuBarStatusView.swift  # Minimal menu bar icon showing detected profiles
└── Tests/
    └── ProfileEngineTests.swift    # Headless unit tests for Local State parsing & keycodes
```
