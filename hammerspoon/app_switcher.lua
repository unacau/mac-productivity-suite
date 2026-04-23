local AppSwitcher = {}

-- Define the Hyper key combination as a local variable
local hyper = {"cmd", "alt", "ctrl", "shift"}

-- Helper function to bind a key to launch or focus an application
function AppSwitcher.bindApp(key, appName)
    hs.hotkey.bind(hyper, key, function()
        hs.application.launchOrFocus(appName)
    end)
end

return AppSwitcher
