local AppSwitcher = {}

-- Define the Hyper key combination as a local variable
local hyper = {"cmd", "alt", "ctrl", "shift"}

-- Helper function to bind a key to launch or focus an application
function AppSwitcher.bindApp(key, appName)
    hs.hotkey.bind(hyper, key, function()
        hs.application.launchOrFocus(appName)
    end)
end

-- Helper function to bind a key to focus a specific Safari tab
function AppSwitcher.bindSafariTab(key, titleSubstring)
    hs.hotkey.bind(hyper, key, function()
        local appleScript = string.format([[
            tell application "Safari"
                repeat with w in windows
                    repeat with t in tabs of w
                        if name of t contains "%s" then
                            set current tab of w to t
                            set index of w to 1
                            activate
                            return
                        end if
                    end repeat
                end repeat
            end tell
        ]], titleSubstring)
        
        local ok, _, _ = hs.osascript.applescript(appleScript)
        if not ok then
            hs.alert.show("Failed to focus Safari tab: " .. titleSubstring)
        end
    end)
end

return AppSwitcher
