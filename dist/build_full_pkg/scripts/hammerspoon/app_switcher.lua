local AppSwitcher = {}

-- Modifiers table (can be updated dynamically between "hyper" and "classic")
local hyper = {"cmd", "alt", "ctrl", "shift"}
local currentMode = "hyper"

-- Internal registry of key -> list of application names
AppSwitcher.bindings = {}
AppSwitcher.hotkeys = {}
AppSwitcher.lastActiveIndex = {}

-- Active switching session state
local activeSession = nil
local hudCanvas = nil
local flagsTap = nil
local iconCache = {}
local tempNumberHotkeys = {}
local appWatcher = nil

-- Helper: Retrieve or cache an app's icon
local function getAppIcon(appName)
    if not appName or appName == "" then return nil end
    if iconCache[appName] then
        return iconCache[appName]
    end

    -- 1. Check if application is currently running
    local runningApp = hs.application.find(appName, true)
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
        if path and hs.fs.attributes(path) then
            local img = hs.image.iconForFile(path)
            if img then
                iconCache[appName] = img
                return img
            end
        end
    end

    -- 2. Search common macOS application directories (verifying existence on disk first)
    local candidatePaths = {
        "/Applications/" .. appName .. ".app",
        "/System/Applications/" .. appName .. ".app",
        "/System/Applications/Utilities/" .. appName .. ".app",
        os.getenv("HOME") .. "/Applications/" .. appName .. ".app",
        os.getenv("HOME") .. "/Applications/Chrome Apps.localized/" .. appName .. ".app",
        "/System/Library/CoreServices/" .. appName .. ".app",
        "/Applications/Setapp/" .. appName .. ".app"
    }

    for _, path in ipairs(candidatePaths) do
        if hs.fs.attributes(path) then
            local img = hs.image.iconForFile(path)
            if img then
                iconCache[appName] = img
                return img
            end
        end
    end

    -- 3. Attempt direct bundle ID lookup
    local img = hs.image.imageFromAppBundle(appName)
    if img then
        iconCache[appName] = img
        return img
    end

    -- 4. Fallback: Search via Spotlight/mdfind for custom installed locations
    local findCmd = string.format("mdfind \"kMDItemContentType == com.apple.application-bundle && kMDItemFSName == '%s.app'\" 2>/dev/null", appName)
    local output = hs.execute(findCmd)
    if output and output ~= "" then
        local firstPath = string.match(output, "([^\r\n]+)")
        if firstPath and hs.fs.attributes(firstPath) then
            local fallbackImg = hs.image.iconForFile(firstPath)
            if fallbackImg then
                iconCache[appName] = fallbackImg
                return fallbackImg
            end
        end
    end

    -- 5. Fallback default macOS application icon
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
    local cardHeight = 126
    local cardSpacing = 10
    local padding = 16

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

        local isMultiAppChrome = item.isChrome and not item.isChromeProfile and item.chromeThumbnails

        if isMultiAppChrome then
            -- 1. Normal size Google Chrome App Icon
            local chromeIcon = getAppIcon("Google Chrome")
            local iconSize = 52
            local iconX = cardX + (cardWidth - iconSize) / 2
            local iconY = cardY + 10
            table.insert(elements, {
                type = "image",
                image = chromeIcon,
                frame = { x = iconX, y = iconY, w = iconSize, h = iconSize }
            })

            -- 2. Title Label "Google Chrome"
            local titleY = cardY + 68
            table.insert(elements, {
                type = "text",
                text = item.displayName or item.name,
                textSize = 11,
                textFont = ".AppleSystemUIFontBold",
                textColor = { white = 0.95, alpha = (isSelected and 1.0 or 0.75) },
                textAlignment = "center",
                textLineBreak = "truncateTail",
                frame = { x = cardX + 4, y = titleY, w = cardWidth - 8, h = 18 }
            })

            -- 3. 4 Profile Avatar Thumbnails placed UNDER "Google Chrome"
            local thumbs = item.chromeThumbnails
            local thumbSize = 16
            local thumbSpacing = 4
            local totalThumbW = (#thumbs * thumbSize) + ((#thumbs - 1) * thumbSpacing)
            local startThumbX = cardX + (cardWidth - totalThumbW) / 2
            local thumbY = cardY + 92

            for tIdx, thumbImg in ipairs(thumbs) do
                local tX = startThumbX + (tIdx - 1) * (thumbSize + thumbSpacing)
                table.insert(elements, {
                    type = "image",
                    image = thumbImg,
                    frame = { x = tX, y = thumbY, w = thumbSize, h = thumbSize }
                })
                -- Circular highlight ring around selected profile thumbnail
                if (item.selectedChromeProfileIndex or 1) == tIdx then
                    table.insert(elements, {
                        type = "rectangle",
                        action = "stroke",
                        strokeColor = { red = 0.45, green = 0.85, blue = 1.0, alpha = 1.0 },
                        strokeWidth = 2,
                        roundedRectRadii = { xRadius = 9, yRadius = 9 },
                        frame = { x = tX - 1, y = thumbY - 1, w = thumbSize + 2, h = thumbSize + 2 }
                    })
                end
            end
        elseif item.isChromeProfile then
            -- Single Chrome Profile mode (Hyper+C when bound to Chrome only)
            local icon = item.icon or getAppIcon(item.name)
            local iconSize = 52
            local iconX = cardX + (cardWidth - iconSize) / 2
            local iconY = cardY + 12
            table.insert(elements, {
                type = "image",
                image = icon,
                frame = { x = iconX, y = iconY, w = iconSize, h = iconSize }
            })

            if item.number or item.badge then
                table.insert(elements, {
                    type = "text",
                    text = item.number or item.badge,
                    textSize = 10,
                    textFont = ".AppleSystemUIFontBold",
                    textColor = { white = 0.80, alpha = (isSelected and 1.0 or 0.6) },
                    textAlignment = "center",
                    frame = { x = cardX + 4, y = cardY + 68, w = cardWidth - 8, h = 14 }
                })
            end

            table.insert(elements, {
                type = "text",
                text = item.displayName or item.name,
                textSize = 11,
                textFont = ".AppleSystemUIFontBold",
                textColor = { white = 0.95, alpha = (isSelected and 1.0 or 0.75) },
                textAlignment = "center",
                textLineBreak = "truncateTail",
                frame = { x = cardX + 4, y = cardY + 84, w = cardWidth - 8, h = 22 }
            })
        else
            -- Standard application card (e.g. Calendar, Spotify, Finder)
            local icon = item.icon or getAppIcon(item.appName or item.name)
            local iconSize = 52
            local iconX = cardX + (cardWidth - iconSize) / 2
            local iconY = cardY + 18
            table.insert(elements, {
                type = "image",
                image = icon,
                frame = { x = iconX, y = iconY, w = iconSize, h = iconSize }
            })

            table.insert(elements, {
                type = "text",
                text = item.displayName or item.name,
                textSize = 11,
                textFont = ".AppleSystemUIFontBold",
                textColor = { white = 0.95, alpha = (isSelected and 1.0 or 0.75) },
                textAlignment = "center",
                textLineBreak = "truncateTail",
                frame = { x = cardX + 4, y = cardY + 78, w = cardWidth - 8, h = 20 }
            })
        end
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

-- Track active application to maintain MRU per shortcut key even when focused outside switcher
local function handleGlobalAppEvent(appName, eventType, app)
    if eventType ~= hs.application.watcher.activated then return end
    if not appName or appName == "" then return end

    local lowerApp = string.lower(appName)
    local bundle = app and app:bundleID()

    for k, apps in pairs(AppSwitcher.bindings) do
        if #apps > 1 then
            for idx, name in ipairs(apps) do
                local lowerName = string.lower(name)
                if lowerApp == lowerName then
                    AppSwitcher.lastActiveIndex[k] = idx
                    break
                elseif bundle then
                    local r = hs.application.find(name, true)
                    if r and r:bundleID() == bundle then
                        AppSwitcher.lastActiveIndex[k] = idx
                        break
                    end
                end
            end
        end
    end
end

-- Close HUD and launch the selected app / profile
local function commitSession()
    if not activeSession then return end

    local currentSession = activeSession
    local selectedItem = currentSession.items[currentSession.selectedIndex]
    local sessionKey = currentSession.key
    local selectedIndex = currentSession.selectedIndex

    -- Record last focused candidate index for this shortcut group
    if sessionKey and selectedIndex then
        AppSwitcher.lastActiveIndex[sessionKey] = selectedIndex
    end

    activeSession = nil
    clearTempNumberHotkeys()
    updateHUD()

    if selectedItem then
        if selectedItem.isChromeProfile and selectedItem.profileIndex then
            local ok, chromeProfiles = pcall(require, "chrome_profiles")
            if ok and chromeProfiles then
                chromeProfiles.lastActiveProfileIndex = selectedItem.profileIndex
                if chromeProfiles.focusProfileByIndex then
                    chromeProfiles.focusProfileByIndex(selectedItem.profileIndex)
                else
                    hs.application.launchOrFocus("Google Chrome")
                end
            else
                hs.application.launchOrFocus("Google Chrome")
            end
        elseif selectedItem.isChrome then
            local profileIdx = selectedItem.selectedChromeProfileIndex or 1
            local ok, chromeProfiles = pcall(require, "chrome_profiles")
            if ok and chromeProfiles then
                chromeProfiles.lastActiveProfileIndex = profileIdx
                if chromeProfiles.focusProfileByIndex then
                    chromeProfiles.focusProfileByIndex(profileIdx)
                else
                    hs.application.launchOrFocus("Google Chrome")
                end
            else
                hs.application.launchOrFocus("Google Chrome")
            end
        else
            hs.application.launchOrFocus(selectedItem.appName or selectedItem.name)
        end
    end
end

-- Setup flagsChanged event tap to detect modifier release (Hyper or Classic Cmd+Alt)
local function initFlagsTap()
    if flagsTap then return end

    flagsTap = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(event)
        if not activeSession then return end

        local flags = event:getFlags()
        local isHeld = false
        if currentMode == "classic" then
            isHeld = flags.cmd and flags.alt
        else
            -- Hyper combination: cmd + alt + ctrl + shift
            isHeld = flags.cmd and flags.alt and flags.ctrl and flags.shift
        end

        -- When modifiers are released
        if not isHeld then
            commitSession()
        end
    end)
    flagsTap:start()
end

-- Setup temporary number hotkeys (1..4) while an AppSwitcher session is active
local function setupTempNumberHotkeys(hasChrome, chromeIndex)
    clearTempNumberHotkeys()

    local ok, chromeProfiles = pcall(require, "chrome_profiles")
    local numProfiles = (ok and chromeProfiles and chromeProfiles.profiles and #chromeProfiles.profiles) or 4

    for i = 1, numProfiles do
        local profileNum = i
        local numStr = tostring(profileNum)

        local hk = hs.hotkey.bind(hyper, numStr, function()
            if not activeSession then return end

            if activeSession.isChromeOnly then
                -- Session items ARE the 4 profiles directly
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
                    chromeItem.badge = string.format("%d", profileNum)
                    chromeItem.displayName = "Google Chrome"
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
        -- Single app is Google Chrome: directly expand 4 profiles with their real avatars into HUD
        local ok, chromeProfiles = pcall(require, "chrome_profiles")
        if ok and chromeProfiles and chromeProfiles.profiles then
            for idx, p in ipairs(chromeProfiles.profiles) do
                local avatar = chromeProfiles.getProfileIcon(p)
                table.insert(items, {
                    name = p.name,
                    displayName = p.name,
                    number = p.number,
                    isChromeProfile = true,
                    profileIndex = idx,
                    icon = avatar
                })
            end
        else
            table.insert(items, { name = "Google Chrome", appName = "Google Chrome" })
        end
    else
        -- Multi-app binding: create item for each app
        local ok, chromeProfiles = pcall(require, "chrome_profiles")
        local lastProfileIdx = (ok and chromeProfiles and chromeProfiles.lastActiveProfileIndex) or 1
        local chromeThumbs = {}
        if hasChrome and ok and chromeProfiles and chromeProfiles.profiles then
            for _, p in ipairs(chromeProfiles.profiles) do
                table.insert(chromeThumbs, chromeProfiles.getProfileIcon(p))
            end
        end

        for _, appName in ipairs(rawApps) do
            local isChrome = (appName == "Google Chrome")
            table.insert(items, {
                name = appName,
                displayName = (isChrome and "Google Chrome" or appName),
                appName = appName,
                isChrome = isChrome,
                badge = (isChrome and tostring(lastProfileIdx) or nil),
                selectedChromeProfileIndex = (isChrome and lastProfileIdx or nil),
                chromeThumbnails = (isChrome and chromeThumbs or nil)
            })
        end
    end

    -- If only 1 simple app bound, launch immediately
    if #items == 1 and not items[1].isChromeProfile then
        hs.application.launchOrFocus(items[1].name)
        return
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

    if isChromeOnly then
        local ok, chromeProfiles = pcall(require, "chrome_profiles")
        local lastProf = (ok and chromeProfiles and chromeProfiles.lastActiveProfileIndex) or 1

        if frontApp and (frontApp:name() == "Google Chrome" or frontApp:bundleID() == "com.google.Chrome") then
            -- Focused window IS Google Chrome: select NEXT profile candidate
            startIndex = (lastProf % #items) + 1
        else
            -- Focused window is OTHER than Google Chrome: select PREVIOUSLY focused profile candidate
            startIndex = lastProf
            if startIndex > #items then startIndex = 1 end
        end
    elseif frontApp then
        local frontName = frontApp:name()
        local frontBundle = frontApp:bundleID()
        local lowerFront = frontName and string.lower(frontName)
        local matchedIndex = nil

        -- Pass 1: Exact name or bundle ID match
        for i, it in ipairs(items) do
            local targetName = it.appName or it.name
            local lowerTarget = string.lower(targetName)
            if lowerFront and lowerFront == lowerTarget then
                matchedIndex = i
                break
            end
            if frontBundle then
                local running = hs.application.find(targetName, true)
                if running and running:bundleID() == frontBundle then
                    matchedIndex = i
                    break
                end
            end
        end

        -- Pass 2: Fallback to substring matching only when no exact match was found
        if not matchedIndex and lowerFront then
            for i, it in ipairs(items) do
                local targetName = it.appName or it.name
                local lowerTarget = string.lower(targetName)
                if string.find(lowerFront, lowerTarget, 1, true) or string.find(lowerTarget, lowerFront, 1, true) then
                    matchedIndex = i
                    break
                end
            end
        end

        if matchedIndex then
            -- Focused window IS in the same shortcut group: select NEXT candidate
            startIndex = (matchedIndex % #items) + 1
        else
            -- Focused window is OTHER than pressed shortcut: select PREVIOUSLY focused candidate
            startIndex = AppSwitcher.lastActiveIndex[key] or 1
            if startIndex > #items then startIndex = 1 end
        end
    else
        startIndex = AppSwitcher.lastActiveIndex[key] or 1
        if startIndex > #items then startIndex = 1 end
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

-- Start global application watcher to track MRU across applications
if not appWatcher then
    appWatcher = hs.application.watcher.new(handleGlobalAppEvent):start()
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
                    getAppIcon(name)
                end
            end
        elseif type(arg) == "string" and arg ~= "" then
            table.insert(AppSwitcher.bindings[key], arg)
            getAppIcon(arg)
        end
    end

    -- Bind hotkey once for this key
    if not AppSwitcher.hotkeys[key] then
        AppSwitcher.hotkeys[key] = hs.hotkey.bind(hyper, key, function()
            handleKey(key)
        end)
    end
end

-- Update mode dynamically ("hyper" or "classic")
function AppSwitcher.setMode(mode)
    if mode == "classic" then
        currentMode = "classic"
        hyper = {"cmd", "alt"}
    else
        currentMode = "hyper"
        hyper = {"cmd", "alt", "ctrl", "shift"}
    end

    -- Rebind all existing hotkeys with new modifier
    for key, hk in pairs(AppSwitcher.hotkeys) do
        hk:delete()
        AppSwitcher.hotkeys[key] = hs.hotkey.bind(hyper, key, function()
            handleKey(key)
        end)
    end
    print("AppSwitcher mode set to: " .. currentMode)
    hs.alert.show("AppSwitcher mode: " .. string.upper(currentMode))
end

-- Get current mode
function AppSwitcher.getMode()
    return currentMode
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
    if appWatcher then
        appWatcher:stop()
        appWatcher = nil
    end
    activeSession = nil
end

return AppSwitcher
