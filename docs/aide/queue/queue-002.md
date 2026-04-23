# Queue 002: Safari Web App Switcher & Copy on Select

This queue focuses on completing the Safari web app integration (Stage 3), implementing the copy on select functionality for Terminal (Stage 4), and finalizing refinement and polish (Stage 5).

### Item 011: Implement Safari Web App Switcher Logic for SoundCloud
Add logic to iterate through open Safari windows/tabs to identify and focus the SoundCloud web application based on window title using the `D` binding.

### Item 012: Implement Safari Web App Switcher Logic for Spotify
Add logic to iterate through open Safari windows/tabs to identify and focus the Spotify web application based on window title using the `P` binding.

### Item 013: Create Copy on Select Module Skeleton
Create the `copy_on_select.lua` file to serve as the foundation for the terminal copy on select functionality.

### Item 014: Implement leftMouseUp Event Tracking
Set up an `hs.eventtap` to track `leftMouseUp` events globally to detect potential text selections.

### Item 015: Implement Terminal Application Verification Logic
Add logic to the event tap handler to verify that the currently active application is the native macOS "Terminal" app before proceeding.

### Item 016: Implement Selection Verification Logic
Implement logic (e.g., checking if the mouse moved during the click) to verify a text selection actually occurred to prevent clearing the clipboard on regular clicks.

### Item 017: Implement Automated Cmd+C Keystroke
Trigger an automated `Cmd+C` keystroke after a short delay upon a valid text selection in the Terminal.

### Item 018: Integrate Copy on Select Module
Require the `copy_on_select.lua` module in the `init.lua` file to activate the functionality.

### Item 019: Refactor and Modularize Codebase
Refactor the codebase to ensure clean initialization, proper error handling, and a modular structure.

### Item 020: Perform Final End-to-End System Testing
Conduct comprehensive testing of all features (app switcher, copy on select) simultaneously to ensure near-instantaneous performance and correct behavior.

### Item 021: Update Project Documentation
Update any necessary documentation to reflect the final technical architecture and setup instructions.
