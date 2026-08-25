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
local tempNumberHotkeys = {}

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

    local items = activeSession.items
    local selectedIndex = activeSession.selectedIndex
    local count = #items

    local cardWidth = 110
    local cardHeight = 125
    local cardSpacing = 10
    local padding = 16
    local iconSize = 56

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
        fillColor = { red = 0.10, green = 0.10, blue = 0.12, alpha = 0.95 },
        roundedRectRadii = { xRadius = 18, yRadius = 18 }
    })
    table.insert(elements, {
        type = "rectangle",
        action = "stroke",
        strokeColor = { white = 1.0, alpha = 0.15 },
        strokeWidth = 1,
        roundedRectRadii = { xRadius = 18, yRadius = 18 }
    })

    -- Render each card
    for i, item in ipairs(items) do
        local cardX = padding + (i - 1) * (cardWidth + cardSpacing)
        local cardY = padding
        local isSelected = (i == selectedIndex)

        -- Highlight box for currently selected item
        if isSelected then
            table.insert(elements, {
                type = "rectangle",
                action = "fill",
                fillColor = { red = 0.22, green = 0.47, blue = 0.90, alpha = 0.65 },
                roundedRectRadii = { xRadius = 12, yRadius = 12 },
                frame = { x = cardX, y = cardY, w = cardWidth, h = cardHeight }
            })
            table.insert(elements, {
                type = "rectangle",
                action = "stroke",
                strokeColor = { red = 0.45, green = 0.70, blue = 1.0, alpha = 0.95 },
                strokeWidth = 2,
                roundedRectRadii = { xRadius = 12, yRadius = 12 },
                frame = { x = cardX, y = cardY, w = cardWidth, h = cardHeight }
            })
        end

        -- App / Profile Icon
        local icon = item.icon or getAppIcon(item.appName or item.name)
        local iconX = cardX + (cardWidth - iconSize) / 2
        local iconY = cardY + 12
        table.insert(elements, {
            type = "image",
            image = icon,
            frame = { x = iconX, y = iconY, w = iconSize, h = iconSize }
        })

        -- Number / Subtitle badge
        local badgeText = item.number or item.badge
        if badgeText then
            table.insert(elements, {
                type = "text",
                text = badgeText,
                textSize = 10,
                textFont = ".AppleSystemUIFontBold",
                textColor = { white = 0.75, alpha = (isSelected and 1.0 or 0.6) },
                textAlignment = "center",
                frame = { x = cardX + 4, y = iconY + iconSize + 4, w = cardWidth - 8, h = 14 }
            })
        end

        -- Title Label
        local labelY = iconY + iconSize + (badgeText and 18 or 8)
        table.insert(elements, {
            type = "text",
            text = item.displayName or item.name,
            textSize = 11,
            textFont = ".AppleSystemUIFontBold",
            textColor = { white = 0.95, alpha = (isSelected and 1.0 or 0.75) },
            textAlignment = "center",
            textLineBreak = "truncateTail",
            frame = { x = cardX + 4, y = labelY, w = cardWidth - 8, h = 26 }
        })
    end

    hudCanvas:replaceElements(elements)
    hudCanvas:show()
end

-- Clear temporary number shortcuts
local function clearTempNumberHotkeys()
    for _, hk in ipairs(tempNumberHotkeys) do
        hk:delete()
    end
    tempNumberHotkeys = {}
end

-- Close HUD and launch the selected app / profile
local function commitSession()
    if not activeSession then return end

    local selectedItem = activeSession.items[activeSession.selectedIndex]
    activeSession = nil
    clearTempNumberHotkeys()
    updateHUD()

    if selectedItem then
        if selectedItem.isChromeProfile and selectedItem.profileIndex then
            local ok, chromeProfiles = pcall(require, "chrome_profiles")
            if ok and chromeProfiles and chromeProfiles.focusProfileByIndex then
                chromeProfiles.focusProfileByIndex(selectedItem.profileIndex)
            else
                hs.application.launchOrFocus("Google Chrome")
            end
        elseif selectedItem.selectedChromeProfileIndex then
            local ok, chromeProfiles = pcall(require, "chrome_profiles")
            if ok and chromeProfiles and chromeProfiles.focusProfileByIndex then
                chromeProfiles.focusProfileByIndex(selectedItem.selectedChromeProfileIndex)
            else
                hs.application.launchOrFocus("Google Chrome")
            end
        else
            hs.application.launchOrFocus(selectedItem.appName or selectedItem.name)
        end
    end
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

-- Setup temporary number hotkeys (1..N) while an AppSwitcher session is active
local function setupTempNumberHotkeys(hasChrome, chromeIndex)
    clearTempNumberHotkeys()

    local ok, chromeProfiles = pcall(require, "chrome_profiles")
    local numProfiles = (ok and chromeProfiles and chromeProfiles.profiles and #chromeProfiles.profiles) or 7

    for i = 1, numProfiles do
        local profileNum = i
        local numStr = tostring(profileNum)

        local hk = hs.hotkey.bind(hyper, numStr, function()
            if not activeSession then return end

            if activeSession.isChromeOnly then
                -- Session items ARE the profiles directly
                if profileNum <= #activeSession.items then
                    activeSession.selectedIndex = profileNum
                    updateHUD()
                end
            elseif hasChrome and chromeIndex then
                -- Multi-app session: select Chrome item and assign profile index
                activeSession.selectedIndex = chromeIndex
                local chromeItem = activeSession.items[chromeIndex]
                chromeItem.selectedChromeProfileIndex = profileNum

                if ok and chromeProfiles and chromeProfiles.profiles[profileNum] then
                    local p = chromeProfiles.profiles[profileNum]
                    chromeItem.displayName = string.format("Chrome: [%d] %s", profileNum, p.name)
                    chromeItem.badge = string.format("Profile %d", profileNum)
                end

                updateHUD()
            end
        end)
        table.insert(tempNumberHotkeys, hk)
    end
end

-- Handle hotkey press for a key
local function handleKey(key)
    local rawApps = AppSwitcher.bindings[key]
    if not rawApps or #rawApps == 0 then return end

    initFlagsTap()

    -- Check if Chrome is in the bound applications list
    local hasChrome = false
    local chromeIndex = nil
    for idx, appName in ipairs(rawApps) do
        if appName == "Google Chrome" then
            hasChrome = true
            chromeIndex = idx
            break
        end
    end

    local isChromeOnly = (hasChrome and #rawApps == 1)

    local items = {}
    if isChromeOnly then
        -- Single app is Google Chrome: directly expand all 7 profiles into HUD
        local ok, chromeProfiles = pcall(require, "chrome_profiles")
        if ok and chromeProfiles and chromeProfiles.profiles then
            local chromeIcon = getAppIcon("Google Chrome")
            for idx, p in ipairs(chromeProfiles.profiles) do
                table.insert(items, {
                    name = p.name,
                    displayName = p.name,
                    number = p.number,
                    isChromeProfile = true,
                    profileIndex = idx,
                    icon = chromeIcon
                })
            end
        else
            table.insert(items, { name = "Google Chrome", appName = "Google Chrome" })
        end
    else
        -- Multi-app binding: create item for each app
        for _, appName in ipairs(rawApps) do
            table.insert(items, {
                name = appName,
                displayName = appName,
                appName = appName,
                isChrome = (appName == "Google Chrome")
            })
        end
    end

    -- If a session is already active for this key, cycle to next item
    if activeSession and activeSession.key == key then
        activeSession.selectedIndex = (activeSession.selectedIndex % #items) + 1
        updateHUD()
        return
    end

    -- Starting a new session
    local startIndex = 1
    local frontApp = hs.application.frontmostApplication()
    local frontName = frontApp and frontApp:name()

    if frontName and not isChromeOnly then
        local lowerFront = string.lower(frontName)
        for i, it in ipairs(items) do
            local lowerTarget = string.lower(it.appName or it.name)
            if lowerFront == lowerTarget or string.find(lowerFront, lowerTarget, 1, true) then
                startIndex = (i % #items) + 1
                break
            end
        end
    end

    activeSession = {
        key = key,
        items = items,
        selectedIndex = startIndex,
        isChromeOnly = isChromeOnly
    }

    if hasChrome then
        setupTempNumberHotkeys(hasChrome, chromeIndex)
    end

    updateHUD()
end

-- Helper function to bind a key to one or more applications
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
    clearTempNumberHotkeys()
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
