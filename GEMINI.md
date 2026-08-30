# Project: Mac Productivity Suite

## Tech Stack & Architecture
- **Primary Engine (Swift 6+)**: 100% Pure Native Standalone App (`src/NativeStandaloneApp`) using SwiftUI, AppKit bridging, `CGEvent` taps for Hyper Key handling, and `NSWorkspace` for app switching.
- **Auto-Updates**: Sparkle Framework integrated into the Native App, tracking `appcast.xml`.
- **Legacy/Advanced Engine (Lua 5.4)**: Hammerspoon scripts (`hammerspoon/`) serving advanced users alongside Karabiner-Elements (`karabiner/hyper-key-mapping.json`).
- **Distribution Ecosystem**: `dist/MacProductivitySuite.dmg` (for standard auto-updating users) and `dist/MacProductivitySuite-Full.pkg` (offline installer injecting Hammerspoon/Karabiner).

## Key Build & Verification Commands
- **Release Automation**: `./release.sh` (Builds Native app, creates Full PKG + DMG, signs DMG with Sparkle EdDSA, updates `appcast.xml`, and pushes to GitHub releases for `unacau/mac-productivity-suite`).
- Build Native App: `./build_native_app.sh`
- Build Full Bundle (Offline PKG): `./build_full_pkg.sh`
- Local Testing / Installation: `./install.sh`

## Code Conventions
- **Swift & SwiftUI**:
  - Strictly follow Swift 6 modern concurrency patterns (`async`/`await`, `@MainActor`, `Sendable`). Avoid legacy GCD where possible.
  - Adhere to macOS Human Interface Guidelines (HIG) for all SwiftUI components.
  - Keep `CGEvent` monitoring/filtering logic strictly separated from SwiftUI Views.
  - **Always** ensure explicit accessibility permission checks (`AXIsProcessTrusted`) before activating global event taps.
- **Testing**:
  - Prefer the modern `Swift Testing` framework over legacy `XCTest` for new tests in the `tests/` directory.
- **Lua (Hammerspoon)**:
  - Keep modules decoupled (e.g. `app_switcher.lua`, `chrome_profiles.lua`).
  - Always clean up event taps on reload/stop (`tap:stop()`).
- **Bash Scripting**:
  - Use defensive bash patterns (`set -euo pipefail`) in all build and release scripts to prevent silent failures during packaging.

## Guardrails & Boundaries
- **Sparkle Auto-Updates**: The `.pkg` installs the core apps once. `appcast.xml` and Sparkle exclusively update the `Mac Productivity Suite Native.app` via DMG encapsulation. **Never** attempt to update the `.pkg` payload via Sparkle.
- **Security**: Never commit user configuration tokens, private browser profile paths, or the raw Sparkle EdDSA keychain. `sparkle_private.key` must remain securely managed.
- **Dependencies**: Do not introduce any further C++/Objective-C external dependencies for standard Mac productivity logic—leverage native Swift frameworks (`ApplicationServices`, `Carbon`, `AppKit`).
- **File Hierarchy**: Do not modify installer payloads in `payload_cache/` directly. Always rely on the build scripts to re-assemble the payloads.
