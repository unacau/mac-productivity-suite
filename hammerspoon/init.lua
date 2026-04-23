hs.ipc.cliInstall()
hs.allowAppleScript(true)

-- Helper function to safely load and initialize modules
local function loadModule(name, initFunc)
    local ok, module = pcall(require, name)
    if ok then
        print("Module loaded: " .. name)
        if initFunc and module[initFunc] then
            local initOk, err = pcall(module[initFunc])
            if initOk then
                print("Module initialized: " .. name)
            else
                hs.alert.show("Failed to initialize module: " .. name)
                print("Error initializing module " .. name .. ": " .. tostring(err))
            end
        end
        return module
    else
        hs.alert.show("Failed to load module: " .. name)
        print("Error loading module " .. name .. ": " .. tostring(module))
        return nil
    end
end

-- Load and initialize modules
local appSwitcher = loadModule("app_switcher")
local copyOnSelect = loadModule("copy_on_select", "init")

-- Application Bindings
if appSwitcher then
    -- Primary Apps
    appSwitcher.bindApp("t", "Terminal")
    appSwitcher.bindApp("s", "Safari")
    appSwitcher.bindApp("b", "Brave Browser")

    -- Secondary & Web Apps (Standalone)
    appSwitcher.bindApp("m", "TextMate")
    appSwitcher.bindApp("l", "Telegram")
    appSwitcher.bindApp("d", "SoundCloud")
    appSwitcher.bindApp("p", "Spotify")

    -- System Apps
    appSwitcher.bindApp("f", "Finder")
    appSwitcher.bindApp("h", "Photos")
    appSwitcher.bindApp("n", "Notes")
    appSwitcher.bindApp("r", "Reminders")
    appSwitcher.bindApp("c", "Calendar")
end

hs.alert.show("Hammerspoon Config Reloaded")
print("Hammerspoon configuration loaded with updated bindings.")
