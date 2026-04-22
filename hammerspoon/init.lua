hs.ipc.cliInstall()
hs.allowAppleScript(true)

-- Load modules
local appSwitcher = require("app_switcher")

-- Primary Application Bindings
appSwitcher.bindApp("t", "Terminal")
appSwitcher.bindApp("s", "Safari")
appSwitcher.bindApp("b", "Brave Browser")

hs.alert.show("Hammerspoon Symlink Active - API Enabled")
print("Hammerspoon loaded from symlink! IPC and AppleScript enabled.")
