local AppSwitcher = {}

-- Define the Hyper key combination as a local variable
local hyper = {"cmd", "alt", "ctrl", "shift"}

-- Internal registry of key -> list of application names
AppSwitcher.bindings = {}
AppSwitcher.hotkeys = {}

-- Active switching session state
local activeSession = nil
local hudCanvas = nil
local flagsTap = nil
local iconCache = {}

-- Helper: Retrieve or cache an app's icon
local function getAppIcon(appName)
    if iconCache[appName] then
        return iconCache[appName]
    end

    -- 1. Check if application is currently running
    local runningApp = hs.application.find(appName)
    if runningApp then
        local bundleID = runningApp:bundleID()
        if bundleID then
            local img = hs.image.imageFromAppBundle(bundleID)
            if img then
                iconCache[appName] = img
                return img
            end
        end
        local path = runningApp:path()
        if path then
            local img = hs.image.iconForFile(path)
            if img then
                iconCache[appName] = img
                return img
            end
        end
    end

    -- 2. Search common macOS application directories
    local candidatePaths = {
        "/Applications/" .. appName .. ".app",
        "/System/Applications/" .. appName .. ".app",
        "/System/Applications/Utilities/" .. appName .. ".app",
        os.getenv("HOME") .. "/Applications/" .. appName .. ".app",
        "/Applications/Setapp/" .. appName .. ".app"
    }

    for _, path in ipairs(candidatePaths) do
        local img = hs.image.iconForFile(path)
        if img then
            iconCache[appName] = img
            return img
        end
    end

    -- 3. Attempt direct bundle ID lookup
    local img = hs.image.imageFromAppBundle(appName)
    if img then
        iconCache[appName] = img
        return img
    end

    -- 4. Fallback default macOS application icon
    local generic = hs.image.iconForFile("/System/Library/CoreServices/Finder.app")
    iconCache[appName] = generic
    return generic
end

-- Render or update the visual HUD canvas
local function updateHUD()
    if not activeSession then
        if hudCanvas then
            hudCanvas:hide()
            hudCanvas:delete()
            hudCanvas = nil
        end
        return
    end

    local apps = activeSession.apps
    local selectedIndex = activeSession.selectedIndex
    local count = #apps

    local cardWidth = 110
    local cardHeight = 120
    local cardSpacing = 12
    local padding = 16
    local iconSize = 64

    local totalWidth = (padding * 2) + (count * cardWidth) + ((count - 1) * cardSpacing)
    local totalHeight = (padding * 2) + cardHeight

    local screen = hs.screen.mainScreen()
    local screenFrame = screen:frame()
    local canvasX = screenFrame.x + (screenFrame.w - totalWidth) / 2
    local canvasY = screenFrame.y + (screenFrame.h - totalHeight) / 2

    if not hudCanvas then
        hudCanvas = hs.canvas.new({
            x = canvasX,
            y = canvasY,
            w = totalWidth,
            h = totalHeight
        })
        hudCanvas:level(hs.canvas.windowLevels.overlay)
    else
        hudCanvas:frame({
            x = canvasX,
            y = canvasY,
            w = totalWidth,
            h = totalHeight
        })
    end

    local elements = {}

    -- Background panel (Dark translucent frosted glass style)
    table.insert(elements, {
        type = "rectangle",
        action = "fill",
        fillColor = { red = 0.12, green = 0.12, blue = 0.14, alpha = 0.94 },
        roundedRectRadii = { xRadius = 18, yRadius = 18 }
    })
    table.insert(elements, {
        type = "rectangle",
        action = "stroke",
        strokeColor = { white = 1.0, alpha = 0.15 },
        strokeWidth = 1,
        roundedRectRadii = { xRadius = 18, yRadius = 18 }
    })

    -- Render each app card
    for i, appName in ipairs(apps) do
        local cardX = padding + (i - 1) * (cardWidth + cardSpacing)
        local cardY = padding

        -- Highlight box for currently selected app
        if i == selectedIndex then
            table.insert(elements, {
                type = "rectangle",
                action = "fill",
                fillColor = { red = 0.22, green = 0.47, blue = 0.90, alpha = 0.60 },
                roundedRectRadii = { xRadius = 12, yRadius = 12 },
                frame = { x = cardX, y = cardY, w = cardWidth, h = cardHeight }
            })
            table.insert(elements, {
                type = "rectangle",
                action = "stroke",
                strokeColor = { red = 0.45, green = 0.70, blue = 1.0, alpha = 0.90 },
                strokeWidth = 2,
                roundedRectRadii = { xRadius = 12, yRadius = 12 },
                frame = { x = cardX, y = cardY, w = cardWidth, h = cardHeight }
            })
        end

        -- App Icon
        local icon = getAppIcon(appName)
        local iconX = cardX + (cardWidth - iconSize) / 2
        local iconY = cardY + 12
        table.insert(elements, {
            type = "image",
            image = icon,
            frame = { x = iconX, y = iconY, w = iconSize, h = iconSize }
        })

        -- App Label
        local labelY = iconY + iconSize + 8
        table.insert(elements, {
            type = "text",
            text = appName,
            textSize = 12,
            textFont = ".AppleSystemUIFontBold",
            textColor = { white = 0.95, alpha = (i == selectedIndex and 1.0 or 0.75) },
            textAlignment = "center",
            textLineBreak = "truncateTail",
            frame = { x = cardX + 4, y = labelY, w = cardWidth - 8, h = 24 }
        })
    end

    hudCanvas:replaceElements(elements)
    hudCanvas:show()
end

-- Close HUD and launch the selected app
local function commitSession()
    if not activeSession then return end

    local targetApp = activeSession.apps[activeSession.selectedIndex]
    activeSession = nil
    updateHUD()

    if targetApp then
        hs.application.launchOrFocus(targetApp)
    end
end

-- Cancel session without switching
local function cancelSession()
    activeSession = nil
    updateHUD()
end

-- Setup flagsChanged event tap to detect Caps Lock (Hyper) release
local function initFlagsTap()
    if flagsTap then return end

    flagsTap = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(event)
        if not activeSession then return end

        local flags = event:getFlags()
        -- Hyper combination: cmd + alt + ctrl + shift
        local isHyperHeld = flags.cmd and flags.alt and flags.ctrl and flags.shift

        -- When Caps Lock (Hyper) is released
        if not isHyperHeld then
            commitSession()
        end
    end)
    flagsTap:start()
end

-- Handle hotkey press for a key
local function handleKey(key)
    local apps = AppSwitcher.bindings[key]
    if not apps or #apps == 0 then return end

    -- Ensure the eventtap listener is running
    initFlagsTap()

    -- Single app: launch immediately
    if #apps == 1 then
        hs.application.launchOrFocus(apps[1])
        return
    end

    -- If a session is already active for this key, cycle to the next app
    if activeSession and activeSession.key == key then
        activeSession.selectedIndex = (activeSession.selectedIndex % #apps) + 1
        updateHUD()
        return
    end

    -- Starting a new session for this key:
    -- Determine initial selected index based on frontmost app
    local frontApp = hs.application.frontmostApplication()
    local frontName = frontApp and frontApp:name()
    local startIndex = 1

    if frontName then
        local lowerFront = string.lower(frontName)
        for i, appName in ipairs(apps) do
            local lowerTarget = string.lower(appName)
            if lowerFront == lowerTarget or string.find(lowerFront, lowerTarget, 1, true) or string.find(lowerTarget, lowerFront, 1, true) then
                -- Next in sequence
                startIndex = (i % #apps) + 1
                break
            end
        end
    end

    activeSession = {
        key = key,
        apps = apps,
        selectedIndex = startIndex
    }
    updateHUD()
end

-- Helper function to bind a key to one or more applications
-- Usage:
--   AppSwitcher.bindApp("c", "Google Chrome")
--   AppSwitcher.bindApp("a", "Antigravity", "Antigravity IDE")
--   AppSwitcher.bindApp("m", {"Spotify", "SoundCloud"})
function AppSwitcher.bindApp(key, ...)
    local args = {...}
    if not AppSwitcher.bindings[key] then
        AppSwitcher.bindings[key] = {}
    end

    for _, arg in ipairs(args) do
        if type(arg) == "table" then
            for _, name in ipairs(arg) do
                if type(name) == "string" and name ~= "" then
                    table.insert(AppSwitcher.bindings[key], name)
                end
            end
        elseif type(arg) == "string" and arg ~= "" then
            table.insert(AppSwitcher.bindings[key], arg)
        end
    end

    -- Bind hotkey once for this key
    if not AppSwitcher.hotkeys[key] then
        AppSwitcher.hotkeys[key] = hs.hotkey.bind(hyper, key, function()
            handleKey(key)
        end)
    end
end

-- Cleanup function on config reload
function AppSwitcher.cleanup()
    if hudCanvas then
        hudCanvas:hide()
        hudCanvas:delete()
        hudCanvas = nil
    end
    if flagsTap then
        flagsTap:stop()
        flagsTap = nil
    end
    activeSession = nil
end

return AppSwitcher
