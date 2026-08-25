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
local chromeProfiles = loadModule("chrome_profiles", "init")


-- Application Bindings
if appSwitcher then

    appSwitcher.bindApp("i", "iTerm")
    appSwitcher.bindApp("s", "Spotify", "SoundCloud", "System Settings")
    appSwitcher.bindApp("t", "Telegram")
    appSwitcher.bindApp("a", "Antigravity", "Antigravity IDE")
    appSwitcher.bindApp("n", "Notes")
    appSwitcher.bindApp("p", "Photos", "Preview", "Passwords")
    appSwitcher.bindApp("c", "Google Chrome", "Calendar")
    appSwitcher.bindApp("m", "Activity Monitor")
    
    appSwitcher.bindApp("f", "Finder", "Freeform")
    
end

hs.alert.show("Hammerspoon Config Reloaded")
print("Hammerspoon configuration loaded with updated bindings.")


-- Key binding: Press Cmd + Shift + H to highlight selected text
hs.hotkey.bind({ "cmd", "shift" }, "H", function()
    -- 1. Copy the currently highlighted text to clipboard
    hs.eventtap.keyStroke({ "cmd" }, "c")
    hs.timer.doAfter(0.2, function()
        local highlightedText = hs.pasteboard.getContents()

        if not highlightedText or highlightedText == "" then
            hs.alert.show("No text selected!")
            return
        end

        -- 2. Fetch the PDF Title and URL directly from Safari via AppleScript
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
        local pdfTitle = "Unknown Document"
        local pdfURL = "Local or Unknown"

        if success and result then
            pdfTitle = result[1] or pdfTitle
            pdfURL = result[2] or pdfURL
        end

        -- 3. Prompt user for the Project Context
        local button, projectTag = hs.dialog.textPrompt(
            "Categorize Highlight",
            "Enter Project Name / Tag:",
            "General", "Save", "Cancel"
        )

        if button == "Save" then
            -- Sanitize project name for file storage
            projectTag = projectTag:gsub("%s+", "_")

            -- Define where your notes should go (Change this path to your preference!)
            local storagePath = os.getenv("HOME") .. "/Documents/Highlights/" .. projectTag .. ".md"

            -- 4. Structure the contextual Markdown block
            local timestamp = os.date("%Y-%m-%d %H:%M:%S")
            local markdownEntry = string.format(
                "### Highlighted on %s\n- **Source:** [%s](%s)\n- **Context/Project:** #%s\n- **Quote:**\n  > %s\n\n---\n\n",
                timestamp, pdfTitle, pdfURL, projectTag, highlightedText:gsub("\n", "\n  > ")
            )

            -- 5. Append to the local file securely
            local file = io.open(storagePath, "a")
            if file then
                file:write(markdownEntry)
                file:close()
                hs.alert.show("Saved to project: " .. projectTag)
            else
                -- Create directory if missing and try one more time
                os.execute("mkdir -p " .. os.getenv("HOME") .. "/Documents/Highlights/")
                file = io.open(storagePath, "a")
                if file then
                    file:write(markdownEntry); file:close()
                    hs.alert.show("Saved to project: " .. projectTag)
                else
                    hs.alert.show("Error saving file locally.")
                end
            end
        end
    end)
end)


hs.window.animationDuration = 0

-- Hotkey: Cmd + Alt + Ctrl + F
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "F", function()
    local win1 = hs.window.focusedWindow()
    if not win1 or win1:application():name() ~= "Finder" then return end

    local finder = win1:application()
    local screen = win1:screen()
    local max = screen:frame()

    -- 1. Hide the sidebar on the primary window
    finder:selectMenuItem({"View", "Hide Sidebar"})

    -- 2. Move primary window to the left half
    local leftFrame = hs.geometry.rect(max.x, max.y, max.w / 2, max.h)
    win1:setFrame(leftFrame)

    -- 3. AppleScript to spawn the window AND force Column View natively
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
        -- 4. Robustly target and format the secondary window
        hs.timer.doAfter(0.1, function()
            local win2 = nil
            
            -- Scan all open Finder windows to find the newly created one
            for _, w in ipairs(finder:allWindows()) do
                if w:id() ~= win1:id() and w:subrole() == "AXStandardWindow" then
                    win2 = w
                    break
                end
            end

            if win2 then
                -- Move secondary window to the right half
                local rightFrame = hs.geometry.rect(max.x + (max.w / 2), max.y, max.w / 2, max.h)
                win2:setFrame(rightFrame)
                
                -- Force window focus to ensure the menu command hits the correct target
                win2:focus()
                
                -- Short execution padding to let the focus stick, then hide the sidebar
                hs.timer.doAfter(0.05, function()
                    win2:application():selectMenuItem({"View", "Hide Sidebar"})
                end)
            end
        end)
    else
        print("--- Hammerspoon Finder Script Debug ---")
        print("Success Status:", success)
        print("Script Result:", result)
    end
end)


-- ============================================================================
-- Chrome Profiles Extension
-- Managed in chrome_profiles.lua (Keys 1..7 mapped to Default & other profiles)
-- ============================================================================