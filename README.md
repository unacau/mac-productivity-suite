# Chrome Quick Access (v1.0.0)

A lightweight, zero-latency macOS productivity tool built in pure native Swift 6 and SwiftUI.

Eliminates workflow friction with driverless Caps-Lock remapping, instant Chrome profile cycling, Antigravity IDE switching, and Linux/X11-style universal Copy-on-Select.

---

## ⚡ Key Features

- **⌨️ Dual-Role Caps-Lock**:
  - **Tapped Alone**: Synthesizes `Escape` key (`0x35`). Essential for Vim users, terminal commands, and dismissing modals.
  - **Held Down**: Acts as a modifier without toggling the Caps-Lock LED.
- **🌐 Chrome Profile Switcher (`Caps-Lock + C`)**:
  - Instant focus and cycling between open Google Chrome profiles.
  - Direct profile jump via number keys (`Caps-Lock + 1..8` or `Caps-Lock + C + 1..8`).
  - Dynamic discovery from `~/Library/Application Support/Google/Chrome/Local State` with authentic profile avatars and account badges.
  - Native macOS Accessibility API integration—zero AppleScript UI scripting and no unwanted new tabs.
- **🚀 Antigravity Switcher (`Caps-Lock + A`)**:
  - Instant toggle between Antigravity and Antigravity IDE.
  - Direct jump via number keys (`1` / `2`).
- **📋 Universal Copy-on-Select**:
  - Automatically copies highlighted text to the clipboard upon mouse drag selection (>10pt distance) or multi-click (double-click word / triple-click line).
  - Operates universally across all macOS applications with zero configuration required.
  - Toggle on the fly via the menu bar status icon.
- **🖥️ Non-Activating HUD Overlay**:
  - Compact dark-bezel bezel HUD overlay with portrait cards and avatar badges.
  - Instant navigation via Arrow keys, `Tab` / `Shift-Tab`, or digits.
- **🛡️ 100% Pure Native & Driverless**:
  - Zero third-party drivers or background daemons (no Karabiner-Elements, no Hammerspoon).
  - Low-latency CoreGraphics event tap (`CGEventTap`) and IOHID remapping (`hidutil`).

---

## 📦 Building & Installation

### Quick Build
```bash
# Build universal binary (arm64 & x86_64) and DMG
make native

# Run test suite
make test

# Install to /Applications
make install
```

---

## 📊 Observability & Diagnostics

Chrome Quick Access emits structured logs directly to Apple's **macOS Unified Logging System (`os_log`)** under subsystem `com.unacau.chromequickaccess`.

### Stream Logs in Real Time
```bash
make monitor
# or
./scripts/monitor_telemetry.sh stream
```

### Telemetry Summary & Error Analysis
```bash
make diagnostics
# or
./scripts/monitor_telemetry.sh summary 1h
```

---

## 🧪 Testing & Verification

```bash
# Run automated Swift unit tests
make test
# or
swift test

# Run 3-point system health check
make health
```

---

## 📄 License
MIT License.
