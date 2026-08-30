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

-- Load modules
appSwitcher = loadModule("app_switcher")
copyOnSelect = loadModule("copy_on_select", "init")
chromeProfiles = loadModule("chrome_profiles", "init")

-- Config path resolution
local baseDir = hs.configdir or (os.getenv("HOME") .. "/.hammerspoon")
local configPath = baseDir .. "/config.json"
local sharedConfigPath = os.getenv("HOME") .. "/.config/mac-productivity-suite/config.json"

-- Default Universal Configuration
local defaultBindings = {
    i = {"Ghostty", "iTerm", "Terminal", "Warp", "Alacritty"},
    b = {"Google Chrome", "Arc", "Safari", "Brave Browser", "Firefox"},
    c = {"Google Chrome", "Calendar"},
    e = {"Cursor", "Visual Studio Code", "Xcode", "Sublime Text", "IntelliJ IDEA"},
    f = {"Finder", "Freeform"},
    m = {"Activity Monitor", "Music", "Spotify"},
    n = {"Notes", "Notion", "Obsidian", "Bear"},
    p = {"Preview", "Photos", "Passwords"},
    s = {"Spotify", "Apple Music", "SoundCloud", "System Settings"},
    t = {"Slack", "Telegram", "Discord", "WhatsApp", "Messages"}
}

function loadConfig()
    local targetPath = configPath
    if not hs.fs.attributes(targetPath) and hs.fs.attributes(sharedConfigPath) then
        targetPath = sharedConfigPath
    end

    local conf = nil
    if hs.fs.attributes(targetPath) then
        conf = hs.json.read(targetPath)
    end

    if not conf then
        conf = {
            version = "2.0.0",
            mode = "hyper",
            bindings = defaultBindings,
            copyOnSelect = { enabled = true, dragThreshold = 10 },
            productivityShortcuts = {
                finderSplitEnabled = true,
                quickNotesEnabled = true,
                quickNotesDirectory = os.getenv("HOME") .. "/Documents/Highlights"
            }
        }
        hs.json.write(conf, configPath, true, true)
    end

    return conf
end

-- Apply productivity mode ("hyper", "classic", "ctrl_opt", "cmd_shift")
function setProductivityMode(mode)
    if appSwitcher and appSwitcher.setMode then
        appSwitcher.setMode(mode)
    end
    if chromeProfiles and chromeProfiles.setMode then
        chromeProfiles.setMode(mode)
    end
    print("Productivity mode applied: " .. tostring(mode))
end

-- Apply configuration dynamically
function applyConfiguration()
    local config = loadConfig()
    local mode = config.mode or "hyper"

    if appSwitcher then
        -- Clear existing bindings and rebind from config
        if appSwitcher.cleanup then appSwitcher.cleanup() end
        appSwitcher.bindings = {}
        appSwitcher.hotkeys = {}

        local bindings = config.bindings or defaultBindings
        for key, apps in pairs(bindings) do
            if type(apps) == "table" then
                appSwitcher.bindApp(key, table.unpack(apps))
            elseif type(apps) == "string" then
                appSwitcher.bindApp(key, apps)
            end
        end

        setProductivityMode(mode)
    end

    if chromeProfiles and chromeProfiles.init then
        chromeProfiles.init()
        chromeProfiles.setMode(mode)
    end

    print("Hammerspoon configuration refreshed in " .. mode .. " mode.")
end

-- Initial load
applyConfiguration()
local activeConfig = loadConfig()
hs.alert.show("Hammerspoon Loaded (" .. string.upper(activeConfig.mode or "HYPER") .. " Mode)")

-- Watch config.json for live reload
if configWatcher then configWatcher:stop() end
configWatcher = hs.pathwatcher.new(baseDir, function(files)
    for _, file in ipairs(files) do
        if string.match(file, "config%.json$") then
            print("Detected config.json update, reloading settings...")
            applyConfiguration()
            break
        end
    end
end):start()

-- ============================================================================
-- Productivity Action 1: Highlight & Save to Quick Notes (Cmd + Shift + H)
-- ============================================================================
hs.hotkey.bind({ "cmd", "shift" }, "H", function()
    local config = loadConfig()
    if config.productivityShortcuts and config.productivityShortcuts.quickNotesEnabled == false then
        return
    end

    hs.eventtap.keyStroke({ "cmd" }, "c")
    hs.timer.doAfter(0.2, function()
        local highlightedText = hs.pasteboard.getContents()
        if not highlightedText or highlightedText == "" then
            hs.alert.show("No text selected!")
            return
        end

        local appleScript = [[
            tell application "Safari"
                if (count of windows) is not 0 then
                    tell current tab of window 1
                        return {name, URL}
                    end tell
                else
                    return {"", ""}
                end if
            end tell
        ]]
        local success, result, _ = hs.osascript.applescript(appleScript)
        local docTitle = (success and result and result[1] ~= "" and result[1]) or "Quick Note"
        local docURL = (success and result and result[2] ~= "" and result[2]) or "Local"

        local baseStorage = (config.productivityShortcuts and config.productivityShortcuts.quickNotesDirectory) or (os.getenv("HOME") .. "/Documents/Highlights")
        if string.sub(baseStorage, 1, 2) == "~/" then
            baseStorage = os.getenv("HOME") .. string.sub(baseStorage, 2)
        end

        -- Ensure the directory path is safely quoted for the shell
        local safeStorage = string.format("%q", baseStorage)
        os.execute("mkdir -p " .. safeStorage)
        local storagePath = baseStorage .. "/Quick_Notes.md"
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        local markdownEntry = string.format(
            "### Highlighted on %s\n- **Source:** [%s](%s)\n- **Quote:**\n  > %s\n\n---\n\n",
            timestamp, docTitle, docURL, highlightedText:gsub("\n", "\n  > ")
        )

        local file = io.open(storagePath, "a")
        if file then
            file:write(markdownEntry)
            file:close()
            hs.alert.show("Saved to Quick Notes!")
        else
            hs.alert.show("Error saving note locally.")
        end
    end)
end)

-- ============================================================================
-- Productivity Action 2: Finder Dual-Column Split (Cmd + Alt + Ctrl + F)
-- ============================================================================
hs.window.animationDuration = 0
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "F", function()
    local config = loadConfig()
    if config.productivityShortcuts and config.productivityShortcuts.finderSplitEnabled == false then
        return
    end

    local win1 = hs.window.focusedWindow()
    if not win1 or win1:application():name() ~= "Finder" then return end

    local finder = win1:application()
    local screen = win1:screen()
    local max = screen:frame()

    finder:selectMenuItem({"View", "Hide Sidebar"})
    local leftFrame = hs.geometry.rect(max.x, max.y, max.w / 2, max.h)
    win1:setFrame(leftFrame)

    local cloneScript = [[
        tell application "Finder"
            try
                if (count Finder windows) > 0 then
                    set currentTarget to target of Finder window 1
                    set newWin to make new Finder window
                    set target of newWin to currentTarget
                    set current view of newWin to column view
                    return "SUCCESS"
                else
                    return "ERROR: No Finder windows found"
                end if
            on error errMsg
                return "ERROR: " & errMsg
            end try
        end tell
    ]]

    local success, result, raw = hs.osascript.applescript(cloneScript)
    if success and result == "SUCCESS" then
        hs.timer.doAfter(0.1, function()
            local win2 = nil
            for _, w in ipairs(finder:allWindows()) do
                if w:id() ~= win1:id() and w:subrole() == "AXStandardWindow" then
                    win2 = w
                    break
                end
            end

            if win2 then
                local rightFrame = hs.geometry.rect(max.x + (max.w / 2), max.y, max.w / 2, max.h)
                win2:setFrame(rightFrame)
                win2:focus()
                hs.timer.doAfter(0.05, function()
                    win2:application():selectMenuItem({"View", "Hide Sidebar"})
                end)
            end
        end)
    end
end)