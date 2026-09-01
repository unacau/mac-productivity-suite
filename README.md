# Mac Productivity Suite (v2.2 Universal)

A high-performance, ultra-minimal macOS productivity tool built in modern Swift 6 and SwiftUI.

Designed to eliminate workflow friction: switch instantly between favorite apps and specific Google Chrome profiles using the **Caps Lock (Hyper)** key, without accessibility permission hurdles, bloated background processes, or hardcoded settings.

---

## ⚡ Highlights

- **🚀 Hyper Key App Switcher**: Lightning-fast switching and cycling between your favorite apps using `Caps Lock + Key`.
- **🌐 Dynamic Browser Profiles**: Discovers Google Chrome profiles and renders authentic user avatars. Switch between profiles with `Caps Lock + 1..9`.
- **🔍 1-Click Smart Detection**: Automatically detects installed IDEs, terminals, browsers, and communicators to map clean default bindings.
- **✨ Pure Minimalism**: Single-page Settings UI. No complex tabs, no permission locks, no unnecessary import/export bloat.
- **🛡️ Native & Zero-Permission**: Uses native Carbon hotkey registration and AppKit activation—no macOS Accessibility permission prompts or event tap interference required.
- **⚙️ Unified JSON Configuration**: Stored cleanly at `~/.config/mac-productivity-suite/config.json`.

---

## 📦 Installation & Packaging

### 1. Pure Native Standalone Edition
Runs as a lightweight native macOS accessory app in your menu bar.

```bash
# Build native universal app & DMG (arm64 & x86_64)
make native

# Or run the installer PKG
sudo installer -pkg dist/MacProductivitySuite-Full.pkg -target /
```

---

## 📊 Monitoring & Telemetry (Diagnostics)

The app logs directly to Apple's **macOS Unified Logging System (`os_log`)** under the subsystem `com.macproductivity.suite`. This provides zero-overhead, privacy-first, local telemetry that can be inspected on any Mac without developer tools or repository checkouts.

### A. Visual Monitoring via macOS Console App
For users or testing on another Mac without using the terminal:
1. Open **Console.app** (`/System/Applications/Utilities/Console.app` or via Spotlight).
2. In the search box in the top-right corner, enter:
   ```text
   subsystem:com.macproductivity.suite
   ```
3. Click **Start streaming** in the toolbar to observe real-time keypresses, app activations, and profile switches.

### B. Command-Line Log Ingestion (Any Mac)
You or an end-user can run native `log` commands directly in the macOS Terminal:

- **Live Real-Time Stream:**
  ```bash
  log stream --predicate 'subsystem == "com.macproductivity.suite"' --level debug
  ```

- **Inspect Recent Errors & Faults (Past 1 Hour):**
  ```bash
  log show --predicate 'subsystem == "com.macproductivity.suite" and (messageType == error or messageType == fault)' --last 1h
  ```

- **Export Diagnostic Bundle for Support / Debugging:**
  Generate a diagnostic log dump on the Desktop:
  ```bash
  log show --predicate 'subsystem == "com.macproductivity.suite"' --last 24h > ~/Desktop/mps-debug-logs.txt
  ```

### C. Developer Repository Helpers
When working inside this repository, convenient make targets are available:
```bash
# Stream live logs
make monitor

# Generate 1-hour metrics and category distribution summary
make diagnostics

# Filter error stream over custom timeframes
./scripts/monitor_telemetry.sh errors 30m
```

### D. Crash Diagnostics
If the app terminates unexpectedly, macOS automatically records crash reports:
- **Location:** `~/Library/Logs/DiagnosticReports/` (Look for `MacProductivitySuiteNative-*.ips` or `.crash`)
- **Console App:** Accessible directly in **Console.app** under the **Crash Reports** tab.

---

## 🧪 Testing & Verification

The suite includes an automated test harness covering unit tests, sandboxed integration tests (using OS provider abstractions), and health checks.

```bash
# Run automated test suite
make test

# Run 5-point system health check
make health

# SPM Direct
swift test
```

---

## 📄 License
MIT License.
