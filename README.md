# Khomyak (Хомяк) — v1.0.0

A lightweight, zero-latency macOS productivity suite built in pure native Swift 6 and SwiftUI.

*«Тапни хомяка — войди в поток.»* (*“Tap the Hamster. Own the Flow.”*)

Eliminates workflow friction with driverless Caps-Lock remapping, instant Chrome profile cycling, multi-app toolkit switching (Terminal, IDE, AI Agent, Notes), and Linux/X11-style universal Copy-on-Select.

---

## ⚡ Key Features

- **🐹 Tap the Hamster (Caps-Lock Dual-Role)**:
  - **Tapped Alone**: Synthesizes `Escape` key (`0x35`). Essential for Vim users, terminal commands, and dismissing modals.
  - **Held Down**: Acts as a modifier without toggling the Caps-Lock LED.
- **🌐 Chrome Profile Switcher (`Caps-Lock + C`)**:
  - Instant focus and cycling between open Google Chrome profiles.
  - Direct profile jump via number keys (`Caps-Lock + 1..4`).
  - Dynamic discovery from `~/Library/Application Support/Google/Chrome/Local State` with authentic profile avatars and account badges.
  - Native macOS Accessibility API integration—zero AppleScript UI scripting and no unwanted new tabs.
- **🛠️ 5-App Toolkit Ecosystem**:
  - Direct letter shortcuts for your core stack: Terminal (`T`), IDE (`I`), AI Agent (`A`), Notes (`N`), and Chrome (`C`).
  - Dynamic letter routing matching application names.
- **📋 Universal Copy-on-Select**:
  - Automatically copies highlighted text to the clipboard upon mouse drag selection (>10pt distance) or multi-click (double-click word / triple-click line).
  - Operates universally across all macOS applications with zero configuration required.
  - Toggle on the fly via the menu bar status icon.
- **🖥️ Non-Activating HUD Overlay**:
  - Compact dark-bezel HUD overlay with portrait cards and avatar badges.
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

Khomyak emits structured logs directly to Apple's **macOS Unified Logging System (`os_log`)** under subsystem `com.almosteleven.khomyak`.

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

## 🎨 Brand Identity & Neuroaesthetics

Khomyak's design and visual hierarchy are grounded in empirical cognitive neuroscience and neuroaesthetics.
- See the complete [Neuroaesthetics Brandbook](file:///Users/igorekishev/Igor/igorekishev/mac-productivity-suite/docs/BRANDBOOK_NEUROAESTHETICS.md).

---

## 📄 License
MIT License.
