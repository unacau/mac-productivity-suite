---
name: mac-productivity-ops
description: Operational, CI/CD pipeline management, semantic versioning, observability, and diagnostic procedures for Chrome Quick Access. Use whenever bumping versions, building release artifacts, streaming logs, monitoring system health, running quality gates, or managing the release lifecycle.
---

# Chrome Quick Access Operations & Pipeline Management Guide

This skill governs the end-to-end management, maintenance, versioning, observability, and release lifecycle of Chrome Quick Access.

---

## 1. Pipeline Management Protocols

Whenever tasked with maintaining, updating, or releasing the application:

### Step 1: Quality Gate & Health Check
Always execute pre-flight diagnostics and verification before initiating any build or release:
```bash
make health
```
This runs the 3-point automated verification:
1. Version synchronization check between `VERSION.txt`, `BUILD.txt`, and `src/ChromeQuickAccess/Info.plist`.
2. Binary architecture verification (`arm64` + `x86_64` Mach-O universal slices in `dist/Chrome Quick Access.app`).
3. Automated test suite run (`./tests/run_tests.sh`).

### Step 2: Semantic Version Bumping
Never manually edit version numbers across disparate files. Use the automated semantic versioning commands:
```bash
make bump-patch  # Bug fixes, minor adjustments (e.g. 1.0.0 -> 1.0.1)
make bump-minor  # New non-breaking features (e.g. 1.0.1 -> 1.1.0)
make bump-major  # Breaking architectural changes (e.g. 1.1.0 -> 2.0.0)
```
This automatically:
- Updates `VERSION.txt` and increments `BUILD.txt`.
- Updates `src/ChromeQuickAccess/Info.plist` (`CFBundleShortVersionString` and `CFBundleVersion`) via `plutil`.

### Step 3: Local Builds & Packaging
```bash
# Build standalone universal app & DMG
make native

# Run test suite
make test

# Install locally to /Applications
make install
```

### Step 4: Release Execution
When cutting an official release:
1. Run `make test` and `make health`.
2. Run `./release.sh`.
3. Push the git tag (`git push origin vX.Y.Z`).

---

## 2. Observability & Telemetry Instrumentation

The suite emits structured logs directly to the macOS Unified Logging System (`os_log`) under subsystem `com.unacau.chromequickaccess`.

### Architecture Subsystems:
- `app`: Application lifecycle, menu setup, and general state.
- `engine`: Caps-Lock hardware remapping and global event tap routing.
- `profiles`: Chromium `Local State` parsing, monogram rendering, and menu bar AX profile switching.
- `antigravity`: Antigravity & Antigravity IDE application discovery and switching.
- `copy-on-select`: Universal mouse drag and multi-click text selection copy engine.
- `hid`: `hidutil` hardware modifier mapping service.

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
