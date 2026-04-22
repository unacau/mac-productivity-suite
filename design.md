# Mac Productivity Suite Design

## Objective
Implement a suite of productivity enhancements for macOS using Hammerspoon and Karabiner-Elements, specifically targeting a "copy on select" feature for the native Terminal app and a "Hyper Key" driven app switcher.

## Architecture & Components

**Target Directory:** `~/Igor/igorekishev/mac-productivity-suite`

### 1. Karabiner-Elements Configuration
*   **Purpose:** Remap the `Caps Lock` key to act as a "Hyper Key" (simulating `Cmd + Opt + Ctrl + Shift`).
*   **Mechanism:** A complex modification JSON file for Karabiner-Elements that maps `Caps Lock` to `F18` (or directly to the modifiers) when held down, while retaining `Escape` functionality when tapped (optional but recommended).

### 2. Hammerspoon Configuration (`~/.hammerspoon/`)
Hammerspoon will act as the engine, utilizing Lua scripts split into modular files:

*   **`init.lua`**: The main entry point that loads the sub-modules.
*   **`copy_on_select.lua`**:
    *   Uses `hs.eventtap` to monitor mouse events.
    *   Triggers specifically when the "Terminal" application is active.
    *   Listens for `leftMouseUp`.
    *   Includes a small delay (e.g., 50ms) to allow the system to register the selection, then programmatically triggers `Cmd+C`.
    *   Includes logic to verify a selection exists (if possible via UIScripting or clipboard comparison) to avoid overwriting the clipboard with empty strings on standard clicks.
*   **`app_switcher.lua`**:
    *   Binds the Hyper Key + designated letter to launch or focus specific applications.
    *   **Standard Apps:** Uses `hs.application.launchOrFocus()`.
        *   `T`: Terminal
        *   `S`: Safari
        *   `B`: Brave
        *   `M`: TextMate
        *   `L`: Telegram
        *   `F`: Freeform
        *   `G`: Finder
        *   `H`: Photos
        *   `N`: Notes
        *   `R`: Reminders
        *   `C`: Calendar
    *   **PWA / Browser-based Apps:** Custom logic to iterate through Safari windows and focus the specific tab/window based on the window title.
        *   `D`: SoundCloud
        *   `P`: Spotify

## Implementation Steps (To be executed via SpecKit AIDE)

1.  **Environment Setup:** Create the `~/Igor/igorekishev/mac-productivity-suite` directory and transition the CLI session.
2.  **Karabiner Setup:** Generate the `karabiner.json` complex modification and instruct the user on how to import it into Karabiner-Elements.
3.  **Hammerspoon Setup:**
    *   Create `init.lua`.
    *   Implement `copy_on_select.lua` and test the Terminal integration.
    *   Implement `app_switcher.lua` and test the standard app bindings.
    *   Refine `app_switcher.lua` to handle the Safari PWAs (SoundCloud, Spotify).
4.  **Deployment:** Symlink or copy the Lua files to `~/.hammerspoon/` and reload the Hammerspoon configuration.

## Verification
*   Verify `Caps Lock` triggers the Hyper Key modifiers.
*   Selecting text in the standard macOS Terminal automatically copies it to the clipboard without pressing `Cmd+C`.
*   Clicking in Terminal without selecting text does *not* clear the clipboard.
*   Pressing Hyper + designated letters successfully focuses the correct applications, including the specific Safari PWA windows for SoundCloud and Spotify.
