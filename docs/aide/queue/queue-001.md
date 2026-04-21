# Queue 001: Foundation & App Switching

This queue focuses on establishing the core environment (Stage 1), implementing the primary application switcher (Stage 2), and beginning the Safari web app integration (Stage 3).

### Item 001: Initialize Project Directory Structure
Create the basic project directory structure in `~/Igor/igorekishev/mac-productivity-suite` to organize Hammerspoon and Karabiner-Elements configurations.

### Item 002: Setup Local Testing Symlink
Create a symlink from the project directory to `~/.hammerspoon/` to allow for seamless local testing and development while keeping files in the suite's repository.

### Item 003: Configure System Permissions
Ensure Hammerspoon is granted the necessary Accessibility and Screen Recording permissions in macOS System Settings to enable monitoring of mouse events and UI control.

### Item 004: Generate Karabiner-Elements Hyper Key Mapping
Create the complex modification JSON for Karabiner-Elements to map `Caps Lock` held to the Hyper Key (`Cmd + Opt + Ctrl + Shift`) and `Caps Lock` tapped to `Escape`.

### Item 005: Create Basic init.lua
Create a minimal `init.lua` in the project root to verify that Hammerspoon correctly loads the configuration from the symlinked directory.

### Item 006: Create App Switcher Module Skeleton
Create `app_switcher.lua` to house the application switching logic and update `init.lua` to require this new module.

### Item 007: Implement Primary Application Bindings
Implement Hyper Key bindings for the most frequently used applications: Terminal (`T`), Safari (`S`), and Brave (`B`).

### Item 008: Implement Secondary Application Bindings
Implement Hyper Key bindings for productivity and communication applications: TextMate (`M`), Telegram (`L`), and FreeForm (`F`).

### Item 009: Implement System Application Bindings
Implement Hyper Key bindings for built-in macOS system applications: Finder (`G`), Photos (`H`), Notes (`N`), Reminders (`R`), and Calendar (`C`).

### Item 010: Investigate Safari Web App Switcher Logic
Research and implement the core logic to iterate through open Safari windows and tabs to identify and focus specific web applications based on their titles.
