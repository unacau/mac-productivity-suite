<p align="center">
  <img src="assets/xomsky_canonical_hero.png" alt="Xomsky — Your Mac’s Home Row on Steroids (5 Tools in 0ms)" width="100%">
</p>

<p align="center">
  <strong>Your Mac’s Home Row on Steroids · 5 Tools in 0ms</strong><br>
  <em>Dedicated Caps-Lock Hyper Key • 0ms Chromium Profile Switcher • Linux Copy-on-Select • 100% Driverless</em>
</p>

<p align="center">
  <a href="https://github.com/unacau/mac-productivity-suite/releases/latest"><img src="https://img.shields.io/badge/version-1.1.0-007AFF.svg?style=flat-square&logo=apple" alt="Version"></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-6.0_Strict_Concurrency-F05138.svg?style=flat-square&logo=swift&logoColor=white" alt="Swift 6"></a>
  <a href="#"><img src="https://img.shields.io/badge/macOS-14.0%2B_(Sonoma_%7C_Sequoia_%7C_Tahoe)-black.svg?style=flat-square&logo=apple" alt="macOS 14+"></a>
  <a href="#"><img src="https://img.shields.io/badge/DMG-2.1_MB-purple.svg?style=flat-square" alt="DMG Size"></a>
  <a href="#"><img src="https://img.shields.io/badge/Latency-Sub--16ms_(1_Frame)-FF9500.svg?style=flat-square&logo=speedtest" alt="Sub-16ms"></a>
  <a href="#"><img src="https://img.shields.io/badge/Tests-73%2F73_Passing-brightgreen.svg?style=flat-square" alt="Tests"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square" alt="MIT License"></a>
</p>

<p align="center">
  <a href="https://github.com/unacau/mac-productivity-suite/releases/latest/download/Xomsky.dmg"><b>⬇️ Download Xomsky.dmg (2.1 MB)</b></a> •
  <a href="#-the-5-key-home-row-cockpit"><b>✨ 5-Key Cockpit</b></a> •
  <a href="#-benchmark-matrix"><b>🏎️ Benchmark</b></a> •
  <a href="#-quickstart"><b>🚀 Quickstart</b></a>
</p>

---

```bash
# Install via Homebrew in 1 second
brew install unacau/tap/xomsky
```

**Xomsky** turns the physical `Caps-Lock` key into a sub-16ms hardware hyper modifier. Built in pure native **Swift 6** with zero background daemons, zero kernel extensions, and a 15 MB footprint, Xomsky puts your entire workstation right under your home-row fingertips.

---

## ✨ The 5-Key Home-Row Cockpit

Hold <kbd>Caps-Lock</kbd> and tap your home row to switch primary workspaces in **0ms** without touching your mouse:

| Key | Station | Target Applications | Action |
| :---: | :--- | :--- | :--- |
| <kbd>C</kbd> / <kbd>B</kbd> / <kbd>E</kbd> | **Chromium Profiles** | Google Chrome, Brave Browser, Microsoft Edge | Cycle profiles or jump directly with <kbd>Caps</kbd> + <kbd>1..4</kbd> |
| <kbd>T</kbd> | **Terminal** | Ghostty, iTerm2, Alacritty, Terminal.app | Instant window jump; tap repeatedly to cycle candidates |
| <kbd>I</kbd> | **IDE** | Antigravity IDE, Cursor, VS Code, Xcode, JetBrains | Focus active code space across macOS desktop spaces |
| <kbd>A</kbd> | **AI Agent** | Antigravity, Claude, ChatGPT | Summon reasoning companion without losing context |
| <kbd>N</kbd> | **Notes** | Obsidian, Apple Notes, Notion, Bear | Instant scratchpad capture under your fingers |

> [!TIP]
> **Dynamic Profile Snapping**: Pressing `Caps + 1..4` focuses the exact browser profile window via native macOS Accessibility APIs (`AXUIElement`). Zero empty tabs, zero AppleScript lag.

---

## ⚡ Core Capabilities

- **Sub-16ms Multi-Browser Switcher**: Autodetects your default browser. Dedicated hotkeys (`Caps + C` for Chrome, `Caps + B` for Brave, `Caps + E` for Edge) with live avatar parsing from Chromium's `Local State`.
- **Linux/X11 Copy-on-Select**: Highlight text with your mouse (>10pt) and release to copy. Includes a cursor-following tactile HUD toast (`CopyToastWindow`) with rapid auto-dismiss (<1.2s). Modifier-safe (ignores drags when `Cmd`/`Ctrl` is held).
- **Dedicated Hardware Hyper Modifier**: Remaps Caps-Lock to F18 at the hardware layer via native `hidutil`. Never toggles the green LED and never flashes ALL CAPS.
- **XomskyMotion**: Tactile procedural mascot micro-interactions (blinking, breathing springs, gaze tracking) built into the status bar and non-activating HUD.
- **100% Native & Driverless**: Pure Swift 6 with `@MainActor` strict concurrency, 73/73 unit tests, ~15 MB RAM, and zero third-party telemetry SDKs.

---

## 🏎️ Benchmark Matrix

| Feature / Metric | Xomsky 🐹 | Raycast / Alfred | Karabiner-Elements | AltTab / Magnet |
| :--- | :---: | :---: | :---: | :---: |
| **Browser Profile Direct Jump (`Caps + 1..4`)** | **YES (Sub-16ms)** | ❌ (Window title search only) | ❌ (No profile awareness) | ❌ (Flat window list) |
| **Dynamic Browser Switch (`C` / `B` / `E`)** | **YES (Auto-detects)** | ❌ | ❌ | ❌ |
| **Dedicated Clean Hyper Modifier** | **Built-in (Zero Config)** | ❌ (Requires Karabiner) | ⚠️ (Complex JSON config) | ❌ |
| **Universal Linux Copy-on-Select** | **YES (With tactile toast)** | ❌ | ❌ | ❌ |
| **Driverless (No Kernel Ext / Virtual HID)** | **100% Driverless** | 100% Driverless | ❌ (Virtual HID driver) | 100% Driverless |
| **RAM Footprint** | **~15 MB** | 150 MB – 350 MB | 40 MB – 80 MB | 50 MB – 100 MB |
| **Focus Latency** | **< 16 ms (1 frame)** | 80 ms – 250 ms | N/A | 50 ms – 120 ms |
| **Privacy** | **100% Local / Zero Tracking** | Account / Cloud sync | Local Only | Local Only |
| **License & Price** | **Free & Open Source (MIT)** | Freemium ($8+/mo Pro) | Free | Free / Paid |

---

## 🚀 Quickstart

### Install via Homebrew (Recommended)

```bash
brew install unacau/tap/xomsky
```

### Pre-built DMG

1. Download **[Xomsky.dmg (2.1 MB)](https://github.com/unacau/mac-productivity-suite/releases/latest/download/Xomsky.dmg)**.
2. Drag `Xomsky.app` into `/Applications` and launch it.
3. Grant **Accessibility** permission (*System Settings ➔ Privacy & Security ➔ Accessibility*).

### Build from Source

```bash
git clone https://github.com/unacau/mac-productivity-suite.git
cd mac-productivity-suite
make native install   # Builds universal Mach-O binary and installs to /Applications
make test             # Runs 73 unit tests in <0.05s
```

---

## 📊 Telemetry & Health

Xomsky logs directly to Apple's native **macOS Unified Logging System (`os_log`)** under subsystem `com.almosteleven.khomyak`:

```bash
make monitor       # Stream live telemetry
make diagnostics   # Hourly latency & event summary
make health        # Run 3-point system health check
```

---

## ❓ FAQ

<details>
<summary><b>Does Xomsky install any kernel extensions or background daemons?</b></summary>
<br>
<b>No.</b> Xomsky is 100% driverless. It uses Apple’s native <code>hidutil</code> to remap physical Caps-Lock to F18 at the hardware layer and captures key events via non-blocking <code>CGEventTap</code>. Zero SIP bypass, zero kernel panic risk.
</details>

<details>
<summary><b>What happens to the Caps-Lock green LED?</b></summary>
<br>
Because Caps-Lock is remapped to F18 at the hardware layer, macOS never toggles Alpha Lock, the green LED never blinks, and you will never accidentally type in ALL CAPS.
</details>

<details>
<summary><b>How do I uninstall Xomsky?</b></summary>
<br>
Quit Xomsky and delete <code>/Applications/Xomsky.app</code>. Upon quit, Xomsky automatically restores your keyboard mappings to factory defaults via <code>hidutil</code>.
</details>

---

## 📄 License

Distributed under the **MIT License**. See [LICENSE](LICENSE) for details.
