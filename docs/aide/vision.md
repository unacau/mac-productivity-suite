# Project Vision: Mac Productivity Suite

## Project Overview
The Mac Productivity Suite is a collection of custom enhancements designed to optimize workflows on macOS. The core focus of this project is to implement two key features: a "copy on select" behavior for the native macOS Terminal application, and a global "Hyper Key" driven application switcher for instantaneous navigation between frequently used apps and specific web applications.

## Goals & Objectives
*   **Enhance Terminal Workflow:** Eliminate the need for manual keystrokes (`Cmd+C`) when selecting text in the native Terminal by automatically copying the selection to the clipboard.
*   **Accelerate Application Switching:** Provide a lightning-fast, keyboard-driven method to launch or focus specific applications and web apps without relying on `Cmd+Tab` or the Dock.
*   **Minimize Friction:** Implement these features seamlessly so they do not interfere with standard macOS usage patterns.

## Target Users
*   macOS power users seeking to reduce repetitive actions and improve navigation speed.
*   Specifically tailored for the primary user (Igor).

## Core Features
1.  **Hyper Key Mapping:**
    *   Remap the `Caps Lock` key to act as a "Hyper Key" (simulating `Cmd + Opt + Ctrl + Shift` simultaneously) when held down.
    *   (Optional but recommended) Retain standard `Escape` key functionality when the `Caps Lock` key is tapped.
2.  **Copy on Select (Terminal):**
    *   Monitor mouse events (`leftMouseUp`) specifically within the native macOS "Terminal" application.
    *   Automatically trigger a `Cmd+C` keystroke after a brief delay (e.g., 50ms) to copy selected text.
    *   Include intelligent logic to verify a selection actually exists, preventing the clipboard from being overwritten with empty strings during standard clicks.
3.  **Global App Switcher:**
    *   Utilize the Hyper Key in combination with designated letter keys to launch or focus applications.
    *   **Standard Applications:**
        *   `T`: Terminal
        *   `S`: Safari
        *   `B`: Brave
        *   `M`: TextMate
        *   `L`: Telegram
        *   `F`: FreeForm
        *   `G`: Finder
        *   `H`: Photos
        *   `N`: Notes
        *   `R`: Reminders
        *   `C`: Calendar
    *   **PWA / Web Apps (via Safari):**
        *   Iterate through open Safari windows/tabs to focus specific web applications based on their window titles.
        *   `D`: SoundCloud
        *   `P`: Spotify

## Technical Architecture
*   **Key Remapping Engine:** Karabiner-Elements. A complex modification JSON file will be generated to handle the `Caps Lock` to Hyper Key mapping.
*   **Automation & Event Handling Engine:** Hammerspoon (`~/.hammerspoon/`).
*   **Scripting Language:** Lua. The configuration will be modularized:
    *   `init.lua`: Main entry point and module loader.
    *   `copy_on_select.lua`: Handles mouse event tracking (`hs.eventtap`) and clipboard logic for the Terminal.
    *   `app_switcher.lua`: Handles keybindings (`hs.hotkey`) and application/window focusing logic (`hs.application`, `hs.window`).

## Non-Functional Requirements
*   **Performance:** The "copy on select" action must be near-instantaneous and reliable, with minimal noticeable delay. App switching must be immediate.
*   **Reliability:** The clipboard must not be accidentally cleared by normal clicks in the Terminal.
*   **Modularity:** The Hammerspoon Lua code must be split into logical modules for easier maintenance and future expansion.

## Constraints & Assumptions
*   **Dependencies:** Requires both Karabiner-Elements and Hammerspoon to be installed on the target macOS system.
*   **Permissions:** Hammerspoon must be granted necessary Accessibility and Screen Recording permissions in macOS System Settings to monitor mouse events and control the UI.
*   **Target Directory:** The project files will be developed in `~/Igor/igorekishev/mac-productivity-suite` before deployment/symlinking to `~/.hammerspoon/`.

## Out of Scope
*   **Other Terminal Emulators:** The "copy on select" feature is explicitly targeted *only* at the native macOS "Terminal" app. Other emulators like iTerm2, Alacritty, or Kitty (which often have this feature built-in) are excluded.
*   **Other Browsers for PWAs:** The specific logic for focusing web apps (SoundCloud, Spotify) is limited to iterating through Safari windows. Support for Chrome, Brave, or Firefox tabs is out of scope for this specific functionality.

## Success Criteria
*   Pressing and holding `Caps Lock` successfully registers as `Cmd + Opt + Ctrl + Shift`.
*   Highlighting text in the native Terminal application immediately copies the text to the system clipboard without manual keyboard input.
*   Clicking (without dragging/selecting) in the Terminal application does not clear the clipboard or copy an empty string.
*   Pressing the Hyper Key + `T` focuses the Terminal; Hyper Key + `D` focuses the Safari window containing SoundCloud, and all other bindings work as specified.