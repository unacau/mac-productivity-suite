# Architecture & Specification: Chrome Quick Access (v1.0.0)

## 1. Vision & Core Objective
Chrome Quick Access is a lightweight, zero-latency macOS productivity tool built in pure native Swift 6 and SwiftUI.
It operates as a driverless standalone application providing:
1. **Dual-Role Caps-Lock**: Tap alone emits `Escape` (`0x35`); hold down acts as a Hyper modifier.
2. **Chrome Profile Quick Access (`Caps-Lock + C` & digits `1`..`8`)**: Instant switching and cycling between open Chromium profiles without AppleScript scripting or creating empty tabs.
3. **Antigravity Switcher (`Caps-Lock + A`)**: Instant toggle and cycling between Antigravity and Antigravity IDE.
4. **Universal Copy-on-Select**: Linux/X11-style automatic clipboard copying upon mouse drag selection (>10pt) or multi-click word/paragraph selection.
5. **Non-Activating Floating Bezel HUD**: Visual feedback showing profile/application avatars, dismissible before window focus transitions.

---

## 2. Keystroke & Interaction Flow

```
                     ┌────────────────────────────────────────┐
                     │          Physical Caps-Lock            │
                     └───────────────────┬────────────────────┘
                                         │
                  Remapped via hidutil to F18 (0x70000006D)
                                         │
                                         ▼
                               ┌───────────────────┐
                               │    CGEventTap     │
                               └─────────┬─────────┘
                                         │
         ┌───────────────────────────────┴───────────────────────────────┐
         │                                                               │
  Tapped Alone (<250ms)                                            Held Down
         │                                                               │
         ▼                                                               ▼
 Emit Synthetic Escape                                        Route Active Key Actions:
 (Matching Vim/macOS UX)                                      ├── 'C': Cycle Chrome profiles
                                                              ├── 'A': Toggle Antigravity apps
                                                              ├── '1'..'8': Direct index jump
                                                              ├── 'Tab' / 'Shift-Tab': Navigate
                                                              ├── 'Escape': Cancel HUD
                                                              └── Arrows: Navigate Left/Right
```

---

## 3. Subsystem Architecture

### 3.1 CapsLock Engine (`src/ChromeQuickAccess/Engine/CapsLockEngine.swift`)
- **Driverless Remapping**: Uses macOS `hidutil property --set` to map Caps-Lock (`0x700000039`) to F18 (`0x70000006D`). Restores default mapping upon application termination.
- **Head-Insert Event Tap**: Intercepts `keyDown`, `keyUp`, and `flagsChanged` via `.cghidEventTap`.
- **Dual-Role State Machine**: Tracks physical F18 events and isolates external Hyper modifier (`Cmd+Opt+Ctrl+Shift`) state, ensuring modifier keys (e.g. Shift during Shift-Tab navigation) never cause premature Caps-Lock release.
- **Sleep/Wake Resilience**: Registers an observer for `NSWorkspace.didWakeNotification` to re-apply HID mappings and re-enable event taps upon system wake.

### 3.2 Chrome Profile Engine (`src/ChromeQuickAccess/Engine/ChromeProfileEngine.swift`)
- **Zero Hardcoding**: Dynamically parses Chromium `Local State` JSON files (`profile.info_cache`) across Google Chrome, Brave, Microsoft Edge, and Chromium.
- **Avatar & Monogram Rendering**: Resolves custom profile avatars, Google Profile Pictures, or generates high-resolution circular monogram avatars with deterministic color seeding.
- **Native Accessibility Switching**: Uses macOS Accessibility API (`AXUIElementCopyAttributeValue`) traversing the browser's menu bar (`kAXMenuBarAttribute`) to trigger profile switching via `AXMenuItemMarkChar == "✓"` and item selection, eliminating brittle window title matching.
- **Minimized Window Recovery**: Detects minimized windows via `kAXMinimizedAttribute` and unminimizes/raises them without unwanted tab creation.

### 3.3 Antigravity Engine (`src/ChromeQuickAccess/Engine/AntigravityEngine.swift`)
- Discovers `Antigravity` and `Antigravity IDE` application bundles.
- Tracks frontmost application transitions via `NSWorkspace.didActivateApplicationNotification`.
- Provides instant toggle between Antigravity and Antigravity IDE on `Caps-Lock + A`.

### 3.4 Copy-on-Select Engine (`src/ChromeQuickAccess/Engine/CopyOnSelectEngine.swift`)
- **Driverless Mouse Tap**: Listens for `leftMouseDown` and `leftMouseUp` via `.cghidEventTap` (`.listenOnly`) with fallback to `NSEvent.addGlobalMonitorForEvents`.
- **Displacement & Multi-Click Trigger**: Triggers automatic clipboard copying if drag displacement exceeds 10pt (`dx > 10 || dy > 10`) or if multi-click (`clickCount > 1`).
- **Modifier Protection**: Ignores drags with `Command` or `Control` held to avoid conflicting with window movements, canvas operations, or Xcode outlet connections.
- **Loop Prevention & Marking**: Synthesizes `Cmd+C` tagged with `syntheticMarker` (`0x43514150`) to prevent recursive event interception.
- **Auto-Recovery**: Recovers automatically if the event tap is disabled by macOS timeout (`tapDisabledByTimeout`).

### 3.5 Minimal HUD Window (`src/ChromeQuickAccess/Views/MinimalHUDWindow.swift`)
- Non-activating, floating bezel overlay rendered in SwiftUI with AppKit bridging.
- Conforms to macOS Human Interface Guidelines (HIG) with portrait card indicators.
- Dismissal Guardrail: Always hidden immediately (`MinimalHUDWindow.shared.hideImmediate()`) BEFORE triggering application activation to avoid window server transition lockouts.

---

## 4. File Layout

```
mac-productivity-suite/
├── Package.swift                             # Swift Package Manager manifest
├── VERSION.txt                               # Semantic version tracking (1.0.0)
├── BUILD.txt                                 # Build increment counter (1)
├── Makefile                                  # Convenience targets (build, test, health, bump)
├── build_native_app.sh                       # Universal Mach-O binary & DMG build pipeline
├── bump_version.sh                           # Semantic version bump utility
├── install.sh                                # /Applications installation script
├── release.sh                                # Production build & GitHub release automation
├── src/
│   └── ChromeQuickAccess/
│       ├── main.swift                        # AppKit application entry point
│       ├── AppDelegate.swift                 # Menu bar status item & action routing
│       ├── Info.plist                        # macOS application bundle metadata
│       ├── Engine/
│       │   ├── KeyCodes.swift                # Carbon virtual keycode mappings
│       │   ├── CapsLockEngine.swift          # hidutil remapping & event tap dual-role router
│       │   ├── ChromeProfileEngine.swift     # Chromium Local State parser & AX switcher
│       │   ├── AntigravityEngine.swift       # Antigravity app discovery & switcher
│       │   └── CopyOnSelectEngine.swift      # Drag & multi-click copy engine
│       └── Views/
│           └── MinimalHUDWindow.swift        # Floating bezel HUD overlay
├── scripts/
│   ├── health_check.sh                       # 3-point system health validation
│   └── monitor_telemetry.sh                  # macOS Unified Logging telemetry monitor
└── tests/
    ├── run_tests.sh                          # Headless test runner
    └── ChromeQuickAccessTests/
        └── ChromeQuickAccessTests.swift      # Comprehensive Swift Testing unit tests
```
