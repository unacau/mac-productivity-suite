# Architecture & Specification: Khomyak (Хомяк) — v1.0.0

## 1. Vision & Core Objective
Khomyak (Хомяк) is a lightweight, zero-latency macOS productivity suite built in pure native Swift 6 and SwiftUI.
It operates as a driverless standalone application providing:
1. **Dual-Role Caps-Lock**: Tap alone emits `Escape` (`0x35`); hold down acts as a Hyper modifier.
2. **Chrome Profile Quick Access (`Caps-Lock + C` & digits `1`..`4`)**: Instant switching and cycling between open Chromium profiles without AppleScript scripting or creating empty tabs.
3. **5-App Toolkit Fast Switcher (`Caps-Lock + T/I/A/N/C`)**: Instant home-row cycling across Terminal (`T`), IDE (`I`), AI Agent (`A`), Notes (`N`), and Chrome (`C`), with up to 4 pinned application slots.
4. **Antigravity Switcher**: Seamless switching and partner cycling between Antigravity and Antigravity IDE.
5. **Universal Copy-on-Select**: Linux/X11-style automatic clipboard copying upon mouse drag selection (>10pt) or multi-click word/paragraph selection.
6. **Non-Activating Floating Bezel HUD**: Visual feedback showing profile/application avatars, dismissible before window focus transitions.

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
                                                              ├── 'T': Cycle Terminal apps
                                                              ├── 'I': Cycle IDE apps
                                                              ├── 'A': Cycle AI Agent apps
                                                              ├── 'N': Cycle Notes apps
                                                              ├── '1'..'4': Direct index jump
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

### 3.3 App Group Engine (`src/ChromeQuickAccess/Engine/AppGroupEngine.swift`)
- **Universal Pinned Quick Apps**: Maps home-row keys (`T`, `I`, `A`, `N`, `C`) to core toolchains with a strict 4-slot pinned limit.
- **Letter-Cycle Submenus**: When multiple apps share a hotkey or letter group, subsequent presses cycle deterministically across candidates.
- **Slot Replacement**: Allows users to replace pinned slots in 1 click from the menu bar or settings without restarting the daemon.
- **Single-App Mode Optimization**: Automatically hides the avatar card row in HUD overlay when an app group contains only a single candidate.

### 3.4 Antigravity Engine (`src/ChromeQuickAccess/Engine/AntigravityEngine.swift`)
- Discovers `Antigravity` and `Antigravity IDE` application bundles.
- Tracks frontmost application transitions via `NSWorkspace.didActivateApplicationNotification`.
- Provides instant toggle between Antigravity and Antigravity IDE on `Caps-Lock + A`.

### 3.5 Copy-on-Select Engine (`src/ChromeQuickAccess/Engine/CopyOnSelectEngine.swift`)
- **Driverless Mouse Tap**: Listens for `leftMouseDown` and `leftMouseUp` via `.cghidEventTap` (`.listenOnly`) with fallback to `NSEvent.addGlobalMonitorForEvents`.
- **Displacement & Multi-Click Trigger**: Triggers automatic clipboard copying if drag displacement exceeds 10pt (`dx > 10 || dy > 10`) or if multi-click (`clickCount > 1`).
- **Modifier Protection**: Ignores drags with `Command` or `Control` held to avoid conflicting with window movements, canvas operations, or Xcode outlet connections.
- **Loop Prevention & Marking**: Synthesizes `Cmd+C` tagged with `syntheticMarker` (`0x43514150`) to prevent recursive event interception.
- **Auto-Recovery**: Recovers automatically if the event tap is disabled by macOS timeout (`tapDisabledByTimeout`).

### 3.6 Minimal HUD Window (`src/ChromeQuickAccess/Views/MinimalHUDWindow.swift`)
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
├── assets/                                   # Production branding & UI assets
│   ├── explorations/                         # Icon matrices & design exploration archive
│   └── features/                             # README feature infographics
├── docs/                                     # Architecture & Neuroaesthetics brandbooks
│   ├── site/                                 # Official interactive 3D website & web demo
│   ├── BRANDBOOK_BAUHAUS_EDITION.md          # Geometric deconstruction brandbook
│   ├── BRANDBOOK_NEUROAESTHETICS.md          # Neuroaesthetic design hierarchy
│   └── V1_ARCHITECTURE_SPEC.md               # Technical specification
├── src/
│   └── ChromeQuickAccess/
│       ├── main.swift                        # AppKit application entry point
│       ├── AppDelegate.swift                 # Menu bar status item & action routing
│       ├── Info.plist                        # macOS application bundle metadata
│       ├── Resources/                        # AppIcon & DMG background
│       ├── Engine/
│       │   ├── KeyCodes.swift                # Carbon virtual keycode mappings
│       │   ├── CapsLockEngine.swift          # hidutil remapping & event tap dual-role router
│       │   ├── AppGroupEngine.swift          # 5-app toolkit & dynamic letter cycling
│       │   ├── ChromeProfileEngine.swift     # Chromium Local State parser & AX switcher
│       │   ├── AntigravityEngine.swift       # Antigravity app discovery & switcher
│       │   └── CopyOnSelectEngine.swift      # Drag & multi-click copy engine
│       └── Views/
│           └── MinimalHUDWindow.swift        # Floating bezel HUD overlay
├── scripts/
│   ├── generate_media_assets.py              # PIL asset rendering utility
│   ├── health_check.sh                       # 3-point system health validation
│   └── monitor_telemetry.sh                  # macOS Unified Logging telemetry monitor
└── tests/
    ├── run_tests.sh                          # Headless test runner
    └── ChromeQuickAccessTests/
        └── ChromeQuickAccessTests.swift      # 50 Swift Testing unit tests
```
