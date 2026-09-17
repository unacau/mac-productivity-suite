<p align="center">
  <img src="assets/khomyak_readme_hero.png" alt="Khomyak (Хомяк) — Tap the Hamster. Own the Flow." width="100%">
</p>

<p align="center">
  <strong>The Zero-Latency, 100% Native macOS Productivity Suite</strong><br>
  <em>Dual-Role Caps-Lock • Instant Chrome Profile Switching • Home-Row 5-App Switcher • Linux Copy-on-Select</em>
</p>

<p align="center">
  <a href="https://github.com/unacau/mac-productivity-suite/releases/latest"><img src="https://img.shields.io/badge/version-1.0.1-007AFF.svg?style=flat-square&logo=apple" alt="Version"></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-6.0-F05138.svg?style=flat-square&logo=swift&logoColor=white" alt="Swift 6"></a>
  <a href="#"><img src="https://img.shields.io/badge/macOS-14.0%2B-black.svg?style=flat-square&logo=apple" alt="macOS 14+"></a>
  <a href="#"><img src="https://img.shields.io/badge/DMG-1.6_MB-purple.svg?style=flat-square" alt="DMG Size"></a>
  <a href="#"><img src="https://img.shields.io/badge/Latency-Sub--16ms-FF9500.svg?style=flat-square" alt="Sub-16ms"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square" alt="MIT License"></a>
</p>

<p align="center">
  <a href="https://github.com/unacau/mac-productivity-suite/releases/latest/download/Khomyak.dmg"><b>⬇️ Download DMG (1.6 MB)</b></a> •
  <a href="#-the-spotlight-paradox"><b>⚡ Spotlight Paradox</b></a> •
  <a href="#-key-features"><b>✨ Features</b></a> •
  <a href="#-khomyak-vs-the-world"><b>🏎️ Comparison</b></a> •
  <a href="#-quickstart"><b>🚀 Quickstart</b></a>
</p>

---

> **«Тапни хомяка — войди в поток.»**  
> *“Tap the Hamster. Own the Flow.”*

**Khomyak (Хомяк)** converts the most wasted key on your keyboard—`Caps-Lock`—into a sub-16ms hardware switcher. Built in pure, 100% native **Swift 6** with zero background daemons or drivers.

---

## ⚡ The Spotlight Paradox

Spotlight (`Cmd+Space`) is instant for launching apps. But **macOS is completely blind to browser profiles and sub-windows**.

```
Without Khomyak: Mouse ➔ Chrome ➔ Profiles menu ➔ Scan accounts ➔ Click   [⏱️ 5.4s]
With Khomyak:    Press Caps-Lock + 4  (or Caps-Lock + C)                     [⚡ 0.01s]
```

| Action | Traditional macOS / Spotlight | Khomyak 🐹 | Speedup |
| :--- | :--- | :--- | :---: |
| **Switch Chrome Profile #4** | 5.4s (Mouse hunt & menu scan) | **0.01s (`Caps + 4`)** | **540×** |
| **Cycle Browser Profiles** | 4.2s (`Cmd + \`` window cycle) | **0.01s (`Caps + C`)** | **420×** |
| **Escape Vim / Modals** | Top-left corner (`Esc`) | **Home-row pinky tap (`Caps`)** | **0 Wrist Travel** |
| **Copy Highlighted Text** | Drag ➔ `Cmd + C` finger cramp | **Highlight & release (Linux-style)** | **50% Fewer Keys** |
| **Jump to App (IDE/Term)** | `Cmd + Tab` hunt or Spotlight | **`Caps + T`, `Caps + I`, `Caps + A`** | **Home-Row Focus** |

---

## ✨ Key Features

### 🐹 1. Dual-Role Caps-Lock Hyper Key
<p align="center"><img src="assets/features/feature_caps_hyper.png" alt="Caps-Lock Dual-Role Hyper Key" width="90%"></p>

- **Tap (<200ms)**: Synthesizes hardware `Escape` (`0x35`). Instant Esc for Vim, Neovim, and modals.
- **Hold**: Acts as `Hyper` modifier (`Shift+Ctrl+Opt+Cmd`) without toggling Caps-Lock LED.
- **Driverless**: Zero kernel extensions or daemons. Pure `IOHID` + `CGEventTap`.

### 🌐 2. Sub-16ms Chrome Profile Switcher (`Caps + C` / `Caps + 1..4`)
<p align="center"><img src="assets/features/feature_chrome_switch.png" alt="Chrome Switcher" width="90%"></p>

- **Direct Jump**: `Caps + 1..4` snaps directly to profile slot 1–4. `Caps + C` cycles active profiles.
- **Native AX Engine**: Uses macOS Accessibility API. Zero tab spawning, zero AppleScript lag.
- **Universal**: Supports Chrome, Brave, Edge, and Chromium with authentic avatars.

### 🛠️ 3. Home-Row 5-Toolkit Switcher
<p align="center"><img src="assets/features/feature_toolkit_switch.png" alt="5-Toolkit Switcher" width="90%"></p>

Think in tools, not bundle IDs. Jump directly from the home row:
- <kbd>Caps</kbd> + <kbd>T</kbd> ➔ **Terminal** (Ghostty, iTerm2, Alacritty)
- <kbd>Caps</kbd> + <kbd>I</kbd> ➔ **IDE** (Cursor, VS Code, Xcode, JetBrains)
- <kbd>Caps</kbd> + <kbd>A</kbd> ➔ **AI Agent** (Antigravity, Claude, ChatGPT)
- <kbd>Caps</kbd> + <kbd>N</kbd> ➔ **Notes** (Obsidian, Apple Notes, Notion)
- <kbd>Caps</kbd> + <kbd>C</kbd> ➔ **Chrome Profiles** *(Dynamic letter cycling for multi-app groups)*

### 📋 4. Universal Linux/X11 Copy-on-Select
<p align="center"><img src="assets/features/feature_copy_select.png" alt="Copy-on-Select" width="90%"></p>

- **Drag-to-Copy**: Highlight text (>10pt) and release to copy automatically.
- **Multi-Click**: Double/triple click word or paragraph to copy instantly.
- **Modifier-Safe**: Ignores drags with `Cmd`/`Ctrl` held. Works everywhere across macOS.

---

## 🏎️ Khomyak vs. The World

| Feature / Metric | Khomyak 🐹 | Raycast / Alfred | Karabiner | AltTab |
| :--- | :---: | :---: | :---: | :---: |
| **Profile Direct Jump (`Caps+1..4`)** | **YES (Sub-16ms)** | ❌ | ❌ | ❌ |
| **Dual-Role Caps (Tap Esc / Hold Hyper)** | **Built-in** | ❌ | ⚠️ (Complex JSON) | ❌ |
| **Linux Copy-on-Select** | **YES** | ❌ | ❌ | ❌ |
| **Mnemonic Home-Row Switcher** | **YES (`T,I,A,N,C`)** | ⚠️ (Manual) | ⚠️ (Manual) | ❌ |
| **Driverless (No Kext/Virtual HID)** | **100% Native** | 100% Native | ❌ (Driver) | 100% Native |
| **RAM Footprint / Engine** | **~15 MB (Swift 6)** | 150–350 MB | 40–80 MB | 50–100 MB |
| **Focus Latency** | **< 16 ms** | 80–250 ms | N/A | 50–120 ms |
| **Price** | **100% Free & Open Source** | Freemium | Free | Free / Paid |

---

## ⌨️ Shortcuts Cheat Sheet

| Shortcut | Action | Description |
| :--- | :--- | :--- |
| <kbd>Caps-Lock</kbd> *(Tap)* | **Escape** | Synthesizes `Esc`. Exit Vim insert mode / dismiss modals. |
| <kbd>Caps-Lock</kbd> + <kbd>C</kbd> | **Cycle Profiles** | Cycle through open browser profile windows. |
| <kbd>Caps-Lock</kbd> + <kbd>1..4</kbd> | **Profile 1..4** | Snap directly to profile slot index 1, 2, 3, or 4. |
| <kbd>Caps-Lock</kbd> + <kbd>T / I / A / N</kbd> | **Toolkit** | Switch to Terminal (`T`), IDE (`I`), AI Agent (`A`), Notes (`N`). |
| <kbd>Caps-Lock</kbd> + <kbd>Tab</kbd> / <kbd>Arrows</kbd> | **HUD Step** | Step selection forward/backward in active HUD overlay. |
| <kbd>Mouse Drag</kbd> *(>10pt)* | **Copy-on-Select** | Auto clipboard copy on mouse release. |

---

## 🚀 Quickstart

### Pre-built DMG
1. Download **[Khomyak.dmg (1.6 MB)](https://github.com/unacau/mac-productivity-suite/releases/latest/download/Khomyak.dmg)**.
2. Move `Khomyak.app` to `/Applications` and enable **Accessibility** in *System Settings*.

### Build from Source
```bash
git clone https://github.com/unacau/mac-productivity-suite.git && cd mac-productivity-suite
make native && make test && make install
```

---

## 🛠️ Architecture & Observability

- **Engine**: Pure native Swift 6 with `@MainActor` strict concurrency and AppKit `AXUIElement` bridging.
- **Resilience**: Auto-re-applies HID mappings and event taps on system wake (`NSWorkspace.didWakeNotification`).
- **Telemetry**: Emits structured logs to macOS Unified Logging (`os_log` subsystem `com.almosteleven.khomyak`).
  ```bash
  make monitor      # Stream real-time logs
  make diagnostics  # Generate hourly diagnostic summary
  make health       # Run 3-point system health check
  ```

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.

<p align="center">
  <b>Enjoying Khomyak? Star ⭐️ us on GitHub!</b>
</p>
