# Project: Mac Productivity Suite

## Tech Stack & Architecture
- **Native Suite (Swift 6+)**: SwiftUI + AppKit bridging, CGEvent tap interception, NSWorkspace app switching (`src/NativeStandaloneApp`, `src/MenuBarApp`).
- **Scripted Engine (Lua 5.4)**: Hammerspoon (`~/.hammerspoon/` or `hammerspoon/`), `hs.eventtap`, `hs.application`, `hs.urlevent`.
- **Keyboard Engine**: Karabiner-Elements complex modifications (`karabiner/hyper-key-mapping.json`).
- **Distribution**: macOS Installer Packages (`.pkg`), DMG packaging, `pkgbuild` & `productbuild`.

## Key Build & Verification Commands
- Build Native App: `make native` or `./build_native_app.sh`
- Build Full Bundle (with embedded PKG payloads): `make full` or `./build_full_pkg.sh`
- Verify Distributables: `make verify` or `./verify_pkg.sh`
- Clean Build Artifacts: `make clean`

## Code Conventions
- **Swift**:
  - Prefer modern Swift concurrency (`async`/`await`, `@MainActor`) where applicable.
  - Separate CGEvent monitoring/filtering logic from SwiftUI Views.
  - Require explicit accessibility permission checks before registering global event taps.
- **Lua (Hammerspoon)**:
  - Keep modules decoupled (`copy_on_select.lua`, `app_switcher.lua`, `chrome_profiles.lua`).
  - Always clean up event taps on reload/stop (`tap:stop()`).
  - Use `hs.timer.delayed.new` / debounce for high-frequency window/mouse events.

## Guardrails & Boundaries
- Never commit user configuration tokens, private browser profile paths, or credentials.
- Do not run unverified root/sudo commands in scripts without user confirmation.
- Keep installer payloads isolated in `payload_cache/` or `dist/` (always git-ignored).
