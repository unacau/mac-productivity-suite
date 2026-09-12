# Project: Chrome Quick Access (v1.0.0)

## Tech Stack & Architecture
- **Target Platform**: macOS 14.0+ (Sonoma, Sequoia, Tahoe).
- **Primary Engine (Swift 6+)**: 100% Pure Native Standalone App (`src/ChromeQuickAccess`) using SwiftUI, AppKit bridging, CoreGraphics `CGEvent` taps, and driverless IOHID remapping.
  - `Engine/KeyCodes.swift`: Virtual keycode definitions and Carbon/AppKit key lookup.
  - `Engine/CapsLockEngine.swift`: Driverless hardware remapping via `hidutil` (Caps-Lock -> F18) and dual-role head-insert `CGEventTap` (Escape on tap, Hyper modifier on hold).
  - `Engine/ChromeProfileEngine.swift`: Dynamic Chromium `Local State` discovery, monogram avatar rendering, native macOS Accessibility (`AXUIElement`) menu bar profile switching, and window raising.
  - `Engine/AntigravityEngine.swift`: Discovery and fast cycling for Antigravity & Antigravity IDE.
  - `Engine/CopyOnSelectEngine.swift`: Linux/X11-style automatic clipboard copying on text drag selection (>10pt) and multi-click selection.
  - `Views/MinimalHUDWindow.swift`: Non-activating floating bezel HUD overlay with profile avatars and active card indicators.
  - `AppDelegate.swift`: Menu bar status item, hotkey routing, and lifecycle management.
  - `main.swift`: Standard native application entry point.

## Key Build, Verification & Operations Commands
- **Run All Tests**: `make test` or `./tests/run_tests.sh` or `swift test`.
- **System Health & Diagnostics**: `make health` or `./scripts/health_check.sh` (3-point validation).
- **Semantic Version Bumping**: `make bump-patch`, `make bump-minor`, `make bump-major` (Synchronizes `VERSION.txt`, `BUILD.txt`, and `Info.plist`).
- **Telemetry & Direct Log Ingestion**:
  - `make monitor`: Real-time streaming from macOS Unified Logging (`os_log` subsystem `com.unacau.chromequickaccess`).
  - `make diagnostics`: Aggregated log level and category distribution summary over the last hour.
  - `./scripts/monitor_telemetry.sh errors 30m`: Filter errors and faults directly from system log stream.
- **Build Native App**: `make native` or `./build_native_app.sh` (Produces universal Mach-O binary & DMG).
- **Local Installation**: `make install` or `./install.sh` (Installs native app to `/Applications`).
- **Release Automation**: `./release.sh` (Builds native app + DMG and creates GitHub release).

## Code Conventions & Standards
- **Swift & SwiftUI**:
  - Strictly adhere to Swift 6 modern concurrency patterns (`async`/`await`, `@MainActor`, `Sendable`). Avoid legacy GCD / `DispatchQueue` where possible.
  - **Strict Concurrency Captures**: When using `[weak self]` inside a concurrent `@MainActor` `Task`, always safely bind it first (`guard let engine = self else { return }`). Do not pass `self?` directly into the `Task` block.
  - **Explicit Module Imports**: Always include explicit `import AppKit` alongside `import Cocoa` when referencing types like `NSImage`.
  - **Sub-process Execution & ARC**: When executing external CLI utilities synchronously via `Process()`, **always** include `task.waitUntilExit()` (e.g. `/usr/bin/hidutil`, `/usr/bin/open`).
  - **Crucial Distinction**: NEVER execute a long-running GUI application binary directly with `Process().waitUntilExit()`, as this will synchronously block the main thread waiting for the application to terminate. Always delegate GUI launches to `/usr/bin/open` or `NSWorkspace.openApplication`.
  - Adhere to macOS Human Interface Guidelines (HIG) for all SwiftUI views, menus, and HUD overlays.
  - Keep low-level `CGEvent` monitoring/filtering logic strictly separated in `Engine/` services away from SwiftUI Views.
  - **Always** ensure explicit accessibility permission checks (`AXIsProcessTrusted()`) before registering global event taps.
  - Gracefully handle event tap disablement events (`kCGEventTapDisabledByTimeout`, `kCGEventTapDisabledByUserInput`) by re-enabling the tap via `CGEvent.tapEnable(tap: true)`.
  - Instrument structured logs using `os.Logger(subsystem: "com.unacau.chromequickaccess", category: ...)` rather than raw `print()` statements.
- **HUD Overlay Lifecycle & Dismissal Order**:
  - **Always hide the HUD overlay window (`MinimalHUDWindow.shared.hideImmediate()`) BEFORE triggering application activation or window focus**. External window launches cause macOS window server transitions that can swallow keyboard events and block the run loop, trapping the HUD on screen if hidden after the launch.
- **Chromium Profile Automation Guardrail**:
  - **Never match Chromium windows by profile name or title substrings.**
  - **Always automate via native macOS menu bar (`kAXMenuBarAttribute`)**: Target the browser's "Profiles" menu bar item (`getProfilesMenuItems`), select items strictly by position/index, and detect the currently active profile using `AXMenuItemMarkChar == "✓"`.
- **Testing**:
  - Use the modern `Swift Testing` framework (`import Testing`, `@Test`, `#expect`) for all unit tests.
  - Unit tests live in `tests/ChromeQuickAccessTests/ChromeQuickAccessTests.swift`.
  - Tests must run deterministically in headless environments without real GUI spawning.
- **Bash Scripting**:
  - Use defensive bash patterns (`set -euo pipefail`) in all build, verification, and release scripts to prevent silent failures.
