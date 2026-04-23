hs.ipc.cliInstall()
hs.allowAppleScript(true)

-- Load modules
local appSwitcher = require("app_switcher")

-- Primary Application Bindings
appSwitcher.bindApp("t", "Terminal")
appSwitcher.bindApp("s", "Safari")
appSwitcher.bindApp("b", "Brave Browser")

-- Secondary Application Bindings
appSwitcher.bindApp("m", "TextMate")
appSwitcher.bindApp("l", "Telegram")
appSwitcher.bindApp("f", "Freeform")

-- System Application Bindings
appSwitcher.bindApp("g", "Finder")
appSwitcher.bindApp("h", "Photos")
appSwitcher.bindApp("n", "Notes")
appSwitcher.bindApp("r", "Reminders")
appSwitcher.bindApp("c", "Calendar")

-- Safari Web App Bindings
appSwitcher.bindSafariTab("d", "SoundCloud")
appSwitcher.bindSafariTab("p", "Spotify")

hs.alert.show("Hammerspoon Symlink Active - API Enabled")
print("Hammerspoon loaded from symlink! IPC and AppleScript enabled.")
