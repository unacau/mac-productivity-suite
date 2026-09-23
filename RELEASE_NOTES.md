## What's Changed in v1.1.5

### 🎨 Branding & Web Identity
* **Optically Centered Brand Mark (LOD 0):** Replaced heavy macOS squircle with a crisp, transparent vector mascot in website navbar.
* **Contrast & Theme Fix:** Eliminated white container cutout in dark mode and muddy drop shadows in light mode.
* **Tactile Micro-Hover:** Smooth 8% scale spring on navbar branding hover.

### ⚡ Navigation & Core Engine
* **Unified Browser Letter Cycling (C):** Seamless cyclic rotation (`· 1/2 ↻`) between browsers (Chrome, Brave) and other pinned apps sharing keycodes.
* **Smart App Discovery:** Prevented invalid missing bundle pins; guaranteed compatibility with macOS system tools (Finder, Settings).
* **Monolithic HUD Geometry:** Standardized all horizontal switcher app cards to a fixed 132pt width.

### 🛠 Feedback & Stability
* **Direct Diagnostic Bundling:** New feedback window with draggable ZIP export for instant sharing (Telegram, Slack) and pre-filled GitHub issues.
* **Copy-on-Select Self-Exclusion:** Selecting text inside Xomsky windows no longer overwrites system clipboard.
* **Deterministic Headless CI:** Hardened test suite against headless runner timeouts during app discovery.
