# Project: Mac Productivity Suite

## Tech Stack & Architecture
- **Target Platform**: macOS 14.0+ (Sonoma, Sequoia, Tahoe).
- **Primary Engine (Swift 6+)**: 100% Pure Native Standalone App (`src/NativeStandaloneApp`) using SwiftUI, AppKit bridging, Carbon global event dispatcher / `CGEvent` taps, and decoupled OS service providers.
  - `Engine/AppConfig.swift`: Persistent JSON config in `~/.config/mac-productivity-suite/config.json` (and `~/.hammerspoon/config.json` sync). Supports `MPS_TEST_CONFIG_DIR` override for isolated testing.
  - `Engine/OSProviders.swift`: Protocols and system implementations for OS interaction (`WorkspaceProvider`, `HotkeyProvider`, `ProcessProvider`, `RunningAppProvider`) enabling deterministic, headless dependency-injected testing.
  - `Engine/HotkeyManager.swift`: Global Carbon hotkey registration and event dispatching.
  - `Engine/AppSwitcherEngine.swift`: Smart application switching, candidate cycling, and HUD orchestration.
  - `Engine/AppDiscoveryService.swift`: Discovers installed apps and generates smart default keybindings.
  - `Engine/CopyOnSelectEngine.swift`: Linux/X11-style automatic clipboard copying on text selection.
  - `Engine/ChromeProfileHelper.swift`: Dynamic browser profile discovery and profile-specific tab launching.
  - `Views/HUDOverlayWindow.swift`: Non-activating floating bezel HUD overlay.
  - `Views/SettingsWindow.swift`: Multi-tab SwiftUI configuration interface.
  - `Views/MenuBarPopupView.swift`: Status bar menu and quick binding trigger.
- **Auto-Updates**: Sparkle 2.x Framework (`Frameworks/Sparkle.framework`) integrated into Native App, checking `appcast.xml`.
- **Legacy Engine (Lua 5.4 & Karabiner)**: Hammerspoon scripts (`hammerspoon/`) serving power users alongside Karabiner-Elements (`karabiner/hyper-key-mapping.json`).
- **Distribution Ecosystem**:
  - `dist/MacProductivitySuite.dmg`: Auto-updating standalone native application (Sparkle EdDSA signed).
  - `dist/MacProductivitySuite-Full.pkg`: Offline installer bundle deploying Native App, Hammerspoon config, and Karabiner mappings.

## Key Build, Verification & Operations Commands
- **Run All Tests (Unit + Integration)**: `make test` or `./tests/run_tests.sh` or `swift test`.
- **System Health & Diagnostics**: `make health` or `./scripts/health_check.sh` (5-point validation).
- **Semantic Version Bumping**: `make bump-patch`, `make bump-minor`, `make bump-major` (Synchronizes `VERSION.txt`, `BUILD.txt`, and `Info.plist`).
- **Telemetry & Direct Log Ingestion**:
  - `make monitor`: Real-time streaming from macOS Unified Logging (`os_log` subsystem `com.macproductivity.suite`).
  - `make diagnostics`: Aggregated log level and category distribution summary over the last hour.
  - `./scripts/monitor_telemetry.sh errors 30m`: Filter errors and faults directly from system log stream.
- **Build Native App**: `make native` or `./build_native_app.sh` (Produces universal Mach-O binary & DMG).
- **Build Full Bundle (Offline PKG)**: `make full` or `./build_full_pkg.sh` (Bundles app, Hammerspoon, Karabiner, and configs).
- **Verify Package**: `make verify` or `./verify_pkg.sh` (Validates payload structure and digital receipts).
- **Local Testing & Installation**: `./install.sh` (Installs native app to `/Applications` or local dev environment).
- **Release Automation**: `./release.sh` (Builds Native app, creates Full PKG + DMG, signs DMG with Sparkle EdDSA, updates `appcast.xml`, and publishes GitHub release).

## Code Conventions & Standards
- **Swift & SwiftUI**:
  - Strictly adhere to Swift 6 modern concurrency patterns (`async`/`await`, `@MainActor`, `Sendable`). Avoid legacy GCD / `DispatchQueue` where possible.
  - **Strict Concurrency Captures**: When using `[weak self]` inside a concurrent `@MainActor` `Task`, always safely bind it first (`guard let engine = self else { return }`). Do not pass `self?` directly into the `Task` block, as Swift 6 treats `weak self` as a mutable variable, failing CI builds.
  - **Explicit Module Imports**: Always include explicit `import AppKit` alongside `import Cocoa` when referencing types like `NSImage`, because strict Swift 6 CI environments (like GitHub Actions) will not implicitly bridge them.
  - **Sub-process Execution & ARC**: When executing external CLI utilities synchronously via `Process()`, **always** include `task.waitUntilExit()` (e.g. `/usr/bin/hidutil`, `/usr/bin/open`). Failing to do so causes Swift ARC to deallocate the `Process` instance upon function return, prematurely killing child tasks. **Crucial Distinction**: NEVER execute a long-running GUI application binary directly with `Process().waitUntilExit()`, as this will synchronously block the main thread waiting for the application to terminate, causing a permanent spinning beachball ("Not Responding"). Always delegate GUI launches to `/usr/bin/open` or `NSWorkspace.openApplication`.
  - Adhere to macOS Human Interface Guidelines (HIG) for all SwiftUI views, menus, and HUD overlays.
  - Keep low-level `CGEvent` monitoring/filtering logic strictly separated in `Engine/` services away from SwiftUI Views.
  - **Always** leverage `OSProviders.swift` abstraction protocols (`WorkspaceProvider`, `HotkeyProvider`, `ProcessProvider`) in core engines to preserve testability and prevent hardcoded system side-effects.
  - **Always** ensure explicit accessibility permission checks (`AXIsProcessTrusted()`) before registering or activating global event taps. Only prompt for permissions interactively on user action, never blindly on headless startup.
  - Gracefully handle event tap disablement events (`kCGEventTapDisabledByTimeout`, `kCGEventTapDisabledByUserInput`) by re-enabling the tap via `CGEvent.tapEnable(tap: true)`.
  - Instrument structured logs using `AppLogger.getLogger(category:)` (os.Logger) rather than raw `print()` statements.
- **macOS Automation & AppleScript**:
  - **Never** use `NSAppleScript` targeting "System Events" for UI scripting (e.g., clicking menu items). This triggers intrusive Automation permission prompts that degrade the user experience.
  - **Always** prefer native UNIX tools or AppleEvents via the `open` command (e.g., `open -b com.google.Chrome --args --profile-directory=...`) to interact with other apps cleanly and silently.
- **Testing**:
  - Use the modern `Swift Testing` framework (`import Testing`, `@Test`, `#expect`) for all unit and integration tests.
  - Unit tests live in `tests/SwiftUnitTests.swift` (`MacProductivitySuiteTests` target).
  - Integration tests live in `tests/IntegrationTests/` (`MacProductivitySuiteIntegrationTests` target).
  - Always use `MPS_TEST_CONFIG_DIR` temporary directories in integration tests to ensure strict sandbox isolation without modifying the user's live configuration.
- **Lua (Hammerspoon)**:
  - Keep modules decoupled (e.g. `app_switcher.lua`, `chrome_profiles.lua`, `copy_on_select.lua`).
  - Always clean up event taps on reload or shutdown (`tap:stop()`).
  - Protect external shell or system calls with `pcall` error handling.
- **Bash Scripting**:
  - Use defensive bash patterns (`set -euo pipefail`) in all build, verification, and release scripts to prevent silent failures.

## Strict Context Guardrails & Anti-Hallucination Boundaries
1. **CLI / SPM Build Architecture (No Xcode Assumptions)**:
   - This project uses command-line Swift Package Manager (`Package.swift`) and dedicated shell scripts (`build_native_app.sh`, `release.sh`, `build_full_pkg.sh`).
   - **Never assume or require an Xcode project (`.xcodeproj`, `.xcworkspace`) or Xcode GUI archive actions.** All builds, signing, and packaging are driven via the repository scripts.
2. **Event Tap & Accessibility Verification**:
   - Never initiate global event tapping without verifying accessibility permissions using `AXIsProcessTrusted()`.
   - Always handle tap auto-disablement (`kCGEventTapDisabledByTimeout`, `kCGEventTapDisabledByUserInput`) to prevent freeze or loss of input control.
   - **macOS Accessibility Bug Handling**: If `AXIsProcessTrusted()` returns `true` but `CGEvent.tapCreate` returns `nil`, it is likely a macOS cdhash caching bug caused by ad-hoc code signature updates. The app must visibly alert the user to manually remove (`-`) and re-add (`+`) the app in System Settings, rather than silently failing.
3. **Mandatory Pre-Execution Test & Health Discipline**:
   - Always run `make test` or `make health` to verify any modifications to Swift engine logic, models, or configurations before completing tasks.
4. **Semantic Versioning Enforcement**:
   - Never hardcode or manually adjust version numbers in isolated files. Always use `make bump-patch`, `make bump-minor`, or `make bump-major` to keep `VERSION.txt`, `BUILD.txt`, `Info.plist`, and installer packages synchronized.
5. **Direct System Log Ingestion**:
   - Telemetry and diagnostics must ingest native system log streams directly via `./scripts/monitor_telemetry.sh` rather than manual context reconstruction.
6. **Sparkle Auto-Updates Delivery Boundary**:
   - The `.pkg` installs core applications once. `appcast.xml` and Sparkle exclusively update `Mac Productivity Suite Native.app` via DMG encapsulation. **Never** attempt to deliver the `.pkg` payload via Sparkle.
   - **Code Signing & Sparkle Requirements**: Because the app is ad-hoc signed (`-`), the default `cdhash` Designated Requirement will change on every build, causing Sparkle updates to fail. Always sign the main application with a stable DR (`-r="designated => identifier \"com.unacau.macproductivitysuite\""`). Furthermore, NEVER use `--deep` when code signing, as it overwrites and corrupts the internal Sparkle framework's pre-existing XPC service signatures.
8. **Chromium Profile Automation Guardrail**:
   - **Never match Chromium windows by profile name or title substrings.** Users frequently have multiple profiles with identical display names (e.g. personal and work signed in under the same first name "Igor").
   - **Always automate via native macOS menu bar (`kAXMenuBarAttribute`)**: Target the browser's "Profiles" menu bar item (`getProfilesMenuItems`), select items strictly by position/index, and detect the currently active profile using `AXMenuItemMarkChar == "✓"`. This prevents duplicate windows, extra new tabs, and avoids all Automation permission prompts.
   - **Disambiguated Email Titles Precedence**: When users rename profiles or have multiple accounts with the same given name, Chromium appends the account email (`EffectiveName (email@domain.com)`). Exact match against `disambiguatedEmailTitle` MUST be evaluated before base/expected name matching to prevent base names from shadowing specific profiles.
   - **Never execute unconstrained window raising (`kAXRaiseAction`)**: Never call `kAXRaiseAction` on every window in `kAXWindowsAttribute`. Doing so cycles through and raises all 20+ browser windows in sequence, leaving the last window in the array on top and completely trampling Chromium's profile window switch. Window de-miniaturization must strictly check `isMin == true` and match the target profile title.
   - **Never execute `/usr/bin/open -b` after `kAXPressAction`**: When the browser is already running, invoking `/usr/bin/open -b <bundleID>` causes LaunchServices to re-activate the previously focused window, fighting with Chromium's asynchronous window switch. Rely solely on `NSRunningApplication.activate()`.
9. **HUD Overlay Lifecycle & Dismissal Order**:
   - In window switchers and HUD managers, **always hide the HUD overlay window (`HUDOverlayWindow.shared.hide()`) BEFORE triggering application activation or window focus (`launchOrFocusTarget`)**. External window launches cause macOS window server transitions that can swallow keyboard `flagsChanged` events and block the run loop, trapping the HUD on screen if hidden after the launch.
10. **Installer Payloads & Security**:
   - Do not modify payloads in `payload_cache/` directly. Always rely on build scripts (`build_native_app.sh`, `build_full_pkg.sh`) to assemble payloads.
   - Never commit user configuration tokens, private browser profile paths, or the raw Sparkle EdDSA private key (`sparkle_private.key`).
11. **Headless Integration Testing (Anti-Deadlock)**:
    - Integration tests must NEVER spawn or interact with real GUI applications (like Google Chrome) using `/usr/bin/open` or `NSAppleScript`.
    - Executing synchronous `NSAppleScript` commands (`tell application "System Events"`) against UI apps in headless CI runners (which lack WindowServer and TCC permissions) will permanently deadlock the runner.
    - Always use Dependency Injection (e.g., `MockProcessProvider`) for tests instead of hardcoded singletons (`.shared`).
12. **Swift Testing Dependency Resilience**:
    - Do not remove the `apple/swift-testing` dependency from `Package.swift` to resolve deprecation warnings in Xcode 16 / Swift 6. Removing it causes `missing required module '_TestingInternals'` on CI environments that only have macOS Command Line Tools (CLT) installed.
13. **SPM Target Entry Points**:
    - To prevent SPM warnings, `main.swift` containing `@main` must be excluded from library targets in `Package.swift`, and application setup should be decoupled into a separate `AppDelegate.swift`.
14. **Modern Node Actions in CI**:
    - GitHub Actions workflows must use modern versions (`actions/checkout@v7` and `actions/cache@v6`) to avoid Node.js 20 deprecation warnings.
15. **Release DMG Origin**:
    - Never use cloud CI workflows to build or overwrite DMG release assets if they cannot be signed with the Sparkle EdDSA private key. Releases must only be built and signed locally using `release.sh`.

## Task-Specific Context Matrix
- **Native App Logic**: Load `src/NativeStandaloneApp/`, consult `tests/SwiftUnitTests.swift` and `tests/IntegrationTests/`, and test with `./tests/run_tests.sh`.
- **Operations & Releases**: Consult `.agents/skills/mac-productivity-ops/SKILL.md`, `release.sh`, `build_full_pkg.sh`, `build_native_app.sh`, and `appcast.xml`.
- **Diagnostics & Monitoring**: Run `make health`, `make monitor`, or `make diagnostics` (`scripts/monitor_telemetry.sh`).
- **Hammerspoon / Karabiner**: Load `hammerspoon/` and `karabiner/`.
