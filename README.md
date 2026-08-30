# Mac Productivity Suite (v2.0 Universal)

A high-performance, universal macOS productivity platform built in modern Swift and SwiftUI (with an optional Hammerspoon / Karabiner scripted engine).

Designed to be immediately useful for **any macOS user** out of the box with zero hardcoded settings, intelligent automatic app detection, dynamic browser profile switching, global copy-on-select, and an interactive Preferences manager.

---

## ⚡ Highlights

- **🚀 Universal App Switcher**: Single-key switching between your favorite apps (`⌥⌘ + Key` or `Caps Lock + Key`).
- **🔍 Smart Auto-Detection**: 1-click scan of your Mac to automatically configure shortcuts for your installed code editors, browsers, terminals, chat apps, and music players.
- **🌐 Dynamic Browser Profiles**: Automatically discovers and switches Google Chrome, Brave, Edge, and Chromium profiles (Keys `1..4`) with real profile avatars without manual setup.
- **📋 Global Copy on Select**: Highlight or double-click any text to automatically copy it to your clipboard.
- **🎛️ Interactive Preferences UI**: Built-in macOS Settings window (`⌘,`) with searchable app picker, key customization, and presets.
- **📁 Finder Dual-Column Split (`⌥⌘⌃ + F`)**: Instantly creates side-by-side synchronized Finder windows in column view.
- **📝 Highlight to Quick Notes (`⌘⇧ + H`)**: Automatically saves selected text with source timestamps into Markdown.
- **⚙️ Unified JSON Configuration**: Shared config at `~/.config/mac-productivity-suite/config.json`.

---

## 📦 Editions & Installation

### 1. Pure Native Standalone Edition (Recommended)
Zero background daemons, zero third-party dependencies. Runs as a lightweight native macOS accessory app in your menu bar.

```bash
# Build native universal app (arm64 & x86_64)
make native

# Run installer pkg
sudo installer -pkg dist/MacProductivitySuite-Native.pkg -target /
```

### 2. Full Edition (with Hammerspoon & Karabiner-Elements)
Includes native menu bar controls with bundled offline installers for Hammerspoon and Karabiner-Elements for Caps Lock Hyper Key remapping.

```bash
# Build full bundle
make full

# Run full package installer
sudo installer -pkg dist/MacProductivitySuite-Full.pkg -target /
```

---

## 🛠️ Built-in Presets

| Preset | Shortcuts & Apps |
| :--- | :--- |
| **Developer** | `i`: Terminal (Ghostty / iTerm / Warp / Terminal)<br>`c`: Editor (Cursor / VS Code / Xcode / Zed)<br>`b`: Browser (Chrome / Arc / Safari / Firefox)<br>`t`: Chat (Slack / Telegram / Discord)<br>`n`: Notes (Notes / Obsidian / Notion) |
| **Everyday Mac** | `b`: Safari / Chrome<br>`c`: Calendar<br>`m`: Music / Spotify / Messages<br>`n`: Notes / Reminders<br>`p`: Photos / Preview |
| **Creative & Media**| `d`: Figma / Sketch<br>`p`: Photoshop / Pixelmator Pro / Photos<br>`i`: Illustrator / Affinity<br>`m`: Spotify / Music |
| **Minimalist** | `t`: Terminal<br>`b`: Browser<br>`n`: Notes<br>`f`: Finder |

---

## ⌨️ Default Shortcuts

| Shortcut | Action | Description |
| :--- | :--- | :--- |
| `⌥⌘ + I` | Terminal Switcher | Cycles between installed terminals (`Ghostty`, `iTerm`, `Terminal`, `Warp`) |
| `⌥⌘ + B` | Browser Switcher | Cycles between installed browsers (`Chrome`, `Arc`, `Safari`, `Firefox`) |
| `⌥⌘ + C` | Editor / Calendar | Cycles between configured IDEs or Calendar |
| `⌥⌘ + T` | Chat / Comms | Cycles between `Slack`, `Telegram`, `Discord`, `Messages` |
| `⌥⌘ + N` | Notes | Opens `Notes`, `Obsidian`, `Notion` |
| `⌥⌘ + S` | Audio / Music | Switches between `Spotify`, `Apple Music`, `SoundCloud` |
| `⌥⌘ + F` | Finder | Focuses or opens Finder |
| `⌥⌘ + 1..4`| Browser Profiles | Instantly activates Chrome / Brave / Edge profile slot 1..4 |
| `⌥⌘⌃ + F`| Dual Finder Split | Spawns side-by-side synchronized column view Finder windows |
| `⌘⇧ + H` | Save Highlight | Appends highlighted text to `~/Documents/Highlights/Quick_Notes.md` |

---

## 🧪 Testing & Verification

```bash
# Run unit tests
make test

# Verify distributable PKG integrity
make verify

# Build all binaries and packages
make all
```

---

## 📄 License
MIT License.
