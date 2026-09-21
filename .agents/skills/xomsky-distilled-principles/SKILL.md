---
name: xomsky-distilled-principles
description: "Core architectural, UI/UX, hardware fidelity, Polar monetization, and macOS system invariants for the Khomyak / Xomsky application and landing page."
metadata:
  origin: rules-distill
  distilled_sessions: 20
---

# Xomsky (Khomyak) Core Product & System Invariants

This skill codifies the complete set of hard-won engineering, design, monetization, and system rules extracted from the production sessions across the **Xomsky (Khomyak)** ecosystem (native Swift 6 macOS app, WebGL landing page, and Polar monetization). Generic generative AI rules are strictly excluded.

## 1. Native Swift 6 Engine & macOS System Invariants

- **`driverless-hardware-remapping-no-led`**:
  Remap Caps Lock to dedicated modifier (F18) using driverless hardware remapping via `/usr/bin/hidutil` property matching (`UserKeyMapping`), paired with a head-insert `CGEventTap` to intercept physical keydowns without triggering the macOS Caps Lock green LED or toggling capital letters.
  *Violation Risk*: Caps Lock modifier usage desynchronizes case state, triggers distracting green LED blinks, and causes driver instability across macOS versions.

- **`system-app-bundle-resolution`**:
  Never assume macOS system applications exist in `/Applications`. Always resolve applications dynamically via `NSWorkspace.shared.urlForApplication(withBundleIdentifier:)` or search `/System/Applications` and `/System/Library/CoreServices` for core apps like Finder (`com.apple.finder`) and System Settings (`com.apple.systempreferences`).
  *Violation Risk*: Core macOS system utilities fail to launch or pin to quick slots, breaking user workflows.

- **`hud-overlay-dismissal-precedence`**:
  Always hide the HUD overlay window (`MinimalHUDWindow.shared.hideImmediate()`) BEFORE triggering application activation (`NSWorkspace.openApplication`) or window focus transitions.
  *Violation Risk*: Window server focus races swallow keyboard events, lock the run loop, and leave the HUD permanently stuck on screen.

- **`hud-shortcut-transparency-and-split-sections`**:
  Never hide conflicting same-letter application shortcuts in collapsed submenus or nested clicks. Render all apps assigned to the same key transparently with distinct badges, and cleanly demarcate pinned Toolset Shortcuts from dynamic Quick Shortcuts.
  *Violation Risk*: Breaks muscle memory and increases cognitive friction for power users.

- **`chromium-profile-native-accessibility-menu-automation`**:
  Never match Chromium profile windows by window title or profile name substrings. Automate profile switching strictly via the browser's native macOS "Profiles" menu bar item (`kAXMenuBarAttribute`, `getProfilesMenuItems`), selecting items by exact position/index and detecting active state via `AXMenuItemMarkChar == "✓"`.
  *Violation Risk*: Title-based profile matching breaks whenever page tabs change titles, or in localized browser installations.

- **`copy-on-select-distance-and-multi-click-threshold`**:
  Automatic Linux/X11-style clipboard copying (`CopyOnSelectEngine`) must strictly require a drag distance threshold (>10pt) or explicit multi-click selection (double/triple click) before writing to `NSPasteboard.general`. Never copy on trivial mouse clicks or micro-jitters (<10pt). Pair with non-intrusive cursor-following toast (`CopyToastWindow`) with rapid auto-dismiss (<1.2s).
  *Violation Risk*: Overwrites user clipboard history on accidental mouse clicks and causes visual toast spam.

## 2. Polar.sh Monetization & Licensing Architecture

- **`polar-licensing-async-validation`**:
  Online Polar license key validation (`LicenseEngine`) must always execute in a non-blocking asynchronous `Task` on `@MainActor` with graceful offline fallback and explicit network failure messaging. Never block the UI thread during license key verification or checkout redirection (`LicenseEngine.polarCheckoutUrl`).
  *Violation Risk*: Network timeouts or server latency freeze the entire macOS application main run loop during startup or license activation.

## 3. Product Naming

- **`app-name-xomsky`**:
  The application is **Xomsky**, never Khomyak. Always use `Xomsky` for the app name, docs, binaries, and releases.

## 4. Release Automation & Resilience

- **`cloud-release-sync-and-homebrew-cask-resilience`**:
  In release pipelines, never update or publish a Homebrew Cask formula (`Casks/xomsky.rb`) until the GitHub release tag is pushed AND the GitHub Actions cloud build has successfully attached the DMG asset. Deterministically verify the remote URL with `curl -sI` and compute the SHA256 checksum directly from the published binary.
  *Violation Risk*: Broken installation for all Homebrew users experiencing 404 Not Found or checksum mismatch errors.
