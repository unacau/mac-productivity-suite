# Project: Khomyak (Хомяк) — macOS Productivity Suite (v1.0.0)

## Tech Stack & Runtime
- **Platform**: macOS 14.0+ (Sonoma, Sequoia, Tahoe).
- **Toolchain**: Swift 6+ (Strict Concurrency, `@MainActor`, `Sendable`), Swift Package Manager (SPM).
- **Core Frameworks**: AppKit, CoreGraphics (`CGEventTap`), ApplicationServices (Accessibility `AXUIElement`), IOHID (`hidutil`), SwiftUI.
- **Zero Heavy Runtime Dependencies**: No Karabiner daemon, no Hammerspoon runtime.
- **Unified Logging Subsystem**: `com.almosteleven.khomyak`.

## Key Build & Verification Commands
- **Run Tests**: `make test` or `swift test` or `./tests/run_tests.sh`
- **Build Native App**: `make native` or `./build_native_app.sh`
- **Health Check**: `make health` or `./scripts/health_check.sh`
- **Install App**: `make install` or `./install.sh`
- **Stream System Logs**: `make monitor` or `./scripts/monitor_telemetry.sh stream`
- **Telemetry Summary**: `make diagnostics` or `./scripts/monitor_telemetry.sh summary 1h`

## Architecture & Subsystems
1. **Caps-Lock Engine (`src/ChromeQuickAccess/Engine/CapsLockEngine.swift`)**:
   - Hardware remapping via `hidutil property --set` (Caps Lock `0x700000039` -> F18 `0x70000006D`).
   - Head-insert `CGEventTap` (.cghidEventTap):
     - Tapped alone emits synthetic `Escape` (`0x35`).
     - Held down acts as modifier and routes `C`, `A`, `T`, `I`, `N`, digits `1`..`4`, Arrow keys, and `Tab`.
2. **App Group Engine (`src/ChromeQuickAccess/Engine/AppGroupEngine.swift`)**:
   - Universal Pinned Quick Apps (4 slots max):
     - `Caps + T` ➔ **Terminal** (Ghostty, iTerm2, Alacritty, Terminal)
     - `Caps + I` ➔ **IDE** (VS Code, Cursor, Xcode, JetBrains)
     - `Caps + A` ➔ **AI Agent** (Claude, ChatGPT, Perplexity)
     - `Caps + N` ➔ **Notes** (Obsidian, Apple Notes, Notion)
     - `Caps + C` ➔ **Chrome Profiles**
   - Letter-cycle submenus and dynamic alphabet grouping with 1-click slot replacement.
3. **Chrome Profile Engine (`src/ChromeQuickAccess/Engine/ChromeProfileEngine.swift`)**:
   - Parses Chromium `Local State` (`profile.info_cache`) dynamically.
   - Profile switching via macOS Accessibility menu bar (`kAXMenuBarAttribute` -> `Profiles` menu item).
   - Window raising via `kAXRaiseAction` and `kAXMainAttribute`.
   - Fallback cold start via `/usr/bin/open -b <bundleID> --args --profile-directory='<dir>'`.
4. **Antigravity Engine (`src/ChromeQuickAccess/Engine/AntigravityEngine.swift`)**:
   - Discovers Antigravity and Antigravity IDE bundles/paths.
   - Activates frontmost app or toggles to partner app on `Caps-Lock + A`.
5. **Copy-on-Select Engine (`src/ChromeQuickAccess/Engine/CopyOnSelectEngine.swift`)**:
   - Pure native drag detection (>10pt) and multi-click (double/triple) text selection copying.
   - Synthesizes `Cmd+C` with loop-prevention marker.
6. **HUD Window (`src/ChromeQuickAccess/Views/MinimalHUDWindow.swift`)**:
   - Non-activating, floating bezel overlay showing app icon and profile/app avatars.
   - Always dismissed immediately before window server transitions (`launchOrFocusTarget`).

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
  - Automate strictly via native menu bar item positions or exact index matching.
- **Testing**:
  - Unit tests live in `tests/ChromeQuickAccessTests/ChromeQuickAccessTests.swift`.
  - Never execute real GUI processes or synchronous AppleScript in headless tests.
