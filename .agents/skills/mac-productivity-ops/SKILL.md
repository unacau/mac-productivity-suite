---
name: mac-productivity-ops
description: Operational, CI/CD pipeline management, semantic versioning, observability, and diagnostic procedures for Mac Productivity Suite. Use whenever bumping versions, building release artifacts, streaming logs, monitoring system health, running quality gates, or managing the release lifecycle.
---

# Mac Productivity Suite Operations & Pipeline Management Guide

This skill governs the end-to-end management, maintenance, versioning, observability, and release lifecycle of the Mac Productivity Suite.

---

## 1. Pipeline Management Protocols

Whenever tasked with maintaining, updating, or releasing the application:

### Step 1: Quality Gate & Health Check
Always execute pre-flight diagnostics and verification before initiating any build or release:
```bash
make health
```
This runs the 5-point automated verification:
1. `~/.config/mac-productivity-suite/config.json` schema validation.
2. Binary architecture verification (`arm64` + `x86_64` Mach-O universal slices).
3. `appcast.xml` Sparkle RSS feed validation.
4. Version synchronization check between `VERSION.txt`, `BUILD.txt`, and `Info.plist`.
5. Automated test suite run (`./tests/run_tests.sh`).

### Step 2: Semantic Version Bumping
Never manually edit version numbers across disparate files. Use the automated semantic versioning commands:
```bash
make bump-patch  # Bug fixes, minor adjustments (e.g. 2.1.0 -> 2.1.1)
make bump-minor  # New non-breaking features (e.g. 2.1.1 -> 2.2.0)
make bump-major  # Breaking architectural changes (e.g. 2.2.0 -> 3.0.0)
```
This automatically:
- Updates `VERSION.txt` and increments `BUILD.txt`.
- Updates `src/NativeStandaloneApp/Info.plist` (`CFBundleShortVersionString` and `CFBundleVersion`) via `plutil`.
- Feeds into `build_full_pkg.sh` and `release.sh`.

### Step 3: Local Builds & Packaging
```bash
# Build standalone universal app & DMG
make native

# Build full bundle offline package (Native App + Hammerspoon + Karabiner + scripts)
make full

# Verify digital package integrity & payloads
make verify
```

### Step 4: Release Execution
When cutting an official release:
1. Ensure `SPARKLE_PRIVATE_KEY` is present or keychain is configured.
2. Run `./release.sh`.
3. Push the git tag (`git push origin vX.Y.Z`).

---

## 2. Observability & Telemetry Instrumentation

The suite emits structured logs directly to the macOS Unified Logging System (`os_log`) under subsystem `com.macproductivity.suite`.

### Architecture Subsystems:
- `Config`: Configuration load, save, migration, and sandbox overrides.
- `AppDiscovery`: Installed application scanning and candidate resolution.
- `AppSwitcherEngine`: Global shortcut dispatching, window cycling, and HUD rendering.
- `BrowserProfiles`: Chromium profile detection, avatar extraction, and tab routing.
- `Hotkeys`: Carbon global hotkey registration and event tap handlers.
- `UI`: Menu bar status popups and SwiftUI preference windows.
- `ProductivityActions`: Dual Finder splitting and markdown highlight extraction.

### Telemetry Operations:
```bash
# Live stream real-time telemetry (all categories)
make monitor
# or
./scripts/monitor_telemetry.sh stream

# View aggregated category distribution & error rate
make diagnostics
# or
./scripts/monitor_telemetry.sh summary 1h

# Extract recent errors and faults (last 30 minutes)
./scripts/monitor_telemetry.sh errors 30m

# Export ndjson log records for log analytics ingestion
./scripts/monitor_telemetry.sh json 1h > telemetry.jsonl
```

---

## 3. Incident Management & Rollback Strategy

1. **Phased Rollout**:
   - `appcast.xml` incorporates `<sparkle:phasedRolloutInterval>86400</sparkle:phasedRolloutInterval>` for gradual 7-day distribution.
2. **Rollback**:
   - If an issue is reported, immediately remove the offending `<item>` from `appcast.xml`.
   - Revert the bad commit on `main`.
   - Bump patch version via `make bump-patch` and release a roll-forward hotfix.
