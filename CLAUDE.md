# Project: Mac Productivity Suite (Chrome Quick-Access Native)

## Tech Stack & Runtime
- **Platform**: macOS 14.0+ (Sonoma, Sequoia, Tahoe).
- **Toolchain**: Swift 6+ (Strict Concurrency, `@MainActor`, `Sendable`), Swift Package Manager (SPM).
- **Core Frameworks**: AppKit, CoreGraphics (`CGEventTap`), ApplicationServices (Accessibility `AXUIElement`), IOHID (`hidutil`).
- **Zero Heavy Runtime Dependencies**: No Karabiner daemon, no Hammerspoon runtime required for core switching.

## Commands
- Run Tests: `swift test` or `./tests/run_tests.sh`
- Build Native App: `make native` or `./build_native_app.sh`
- Health Check: `make health` or `./scripts/health_check.sh`
- Stream System Logs: `./scripts/monitor_telemetry.sh stream`

## Next-Generation Objective (Simplified Chrome Quick-Access)
A focused native standalone application featuring a single function:
- **Caps-Lock Key**: Remapped via `hidutil` to F18 (`0x70000006D`). Dual-role behavior: tap alone emits `Escape` (`0x35`), held acts as modifier.
- **Caps-Lock + C**: Instant focus/activation of Google Chrome (or last active profile).
- **Caps-Lock + 1..4** (or `Caps-Lock + C + 1..4`): Direct switch to Chrome profile 1, 2, 3, or 4.
- **Profile Discovery**: Dynamically parses `~/Library/Application Support/Google/Chrome/Local State` (`profile.info_cache`). No hardcoded usernames or profile paths.
- **Window Activation**: Driven via macOS Accessibility Menu Bar (`kAXMenuBarAttribute` -> `Profiles` menu item) to prevent duplicate tabs and avoid intrusive AppleScript prompts.

## Key Code Conventions & Guardrails
- **Accessibility & Event Taps**:
  - Always verify `AXIsProcessTrusted()` before creating event taps.
  - Auto-recover taps when disabled by system timeout (`kCGEventTapDisabledByTimeout`, `kCGEventTapDisabledByUserInput`).
  - Alert the user if `AXIsProcessTrusted()` is true but `CGEvent.tapCreate` returns `nil` (macOS cdhash caching bug on ad-hoc signed builds).
- **Sub-process Execution**:
  - For synchronous CLI helpers (like `/usr/bin/hidutil`, `/usr/bin/open`), always call `task.waitUntilExit()` to prevent Swift ARC premature deallocation.
  - NEVER call `.waitUntilExit()` directly on long-running GUI application binaries (delegate to `/usr/bin/open` or `NSWorkspace.openApplication`).
- **Profile Switching**:
  - Never match Chromium windows by profile name or title substrings.
  - Automate strictly via native menu bar item positions or exact index matching, unminimizing target windows using `kAXWindowsAttribute` and `kAXMinimizedAttribute`.
- **Testing**:
  - Unit tests live in `tests/SwiftUnitTests.swift`.
  - Integration tests live in `tests/IntegrationTests/`.
  - Always isolate config and file system paths using temporary test directories (`MPS_TEST_CONFIG_DIR`).
  - Never execute real GUI processes or synchronous AppleScript in headless tests.

## Curated Source References
- Event Tap & Caps-Lock Hardware Remap: `src/NativeStandaloneApp/Engine/HyperKeyEngine.swift`
- Chrome Local State & Accessibility Switcher: `src/NativeStandaloneApp/Engine/ChromeProfileHelper.swift`
- Full Architecture Spec for Simplified Version: `docs/SIMPLIFIED_CHROME_QUICK_ACCESS_SPEC.md`
