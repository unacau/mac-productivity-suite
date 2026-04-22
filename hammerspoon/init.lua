hs.ipc.cliInstall()
hs.allowAppleScript(true)

-- Load modules
local appSwitcher = require("app_switcher")

hs.alert.show("Hammerspoon Symlink Active - API Enabled")
print("Hammerspoon loaded from symlink! IPC and AppleScript enabled.")
