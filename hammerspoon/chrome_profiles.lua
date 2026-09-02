local ChromeProfiles = {}

-- Modifiers for profile switching (can be dynamically switched between "hyper" and "classic")
local hyper = {"cmd", "alt", "ctrl", "shift"}
local currentMode = "hyper"
local MAX_PROFILES = 8

ChromeProfiles.profiles = {}
ChromeProfiles.lastActiveProfileIndex = 1

local contextualHotkeys = {}
local appWatcher = nil

-- Helper to create a circular masked image
local function makeCircularImage(image)
    if not image then return nil end
    local sz = image:size()
    local w = sz.w
    local h = sz.h
    local dim = math.min(w, h)
    if dim <= 0 then return image end

    local c = hs.canvas.new({x = 0, y = 0, w = dim, h = dim})
    c[1] = {
        type = "rectangle",
        action = "strokeAndFill",
        roundedRectRadii = {xRadius = dim / 2, yRadius = dim / 2},
        clipToPath = true
    }
    c[2] = {
        type = "image",
        image = image,
        frame = {x = (dim - w) / 2, y = (dim - h) / 2, w = w, h = h}
    }
    local circularImg = c:imageFromCanvas()
    c:delete()
    return circularImg or image
end

-- Dynamically discover profiles from Local State file
function ChromeProfiles.discoverProfiles()
    local profiles = {}
    local configPath = (hs.configdir or (os.getenv("HOME") .. "/.hammerspoon")) .. "/config.json"
    
    -- 1. Check custom configured profiles in config.json first
    if hs.fs.attributes(configPath) then
        local conf = hs.json.read(configPath)
        if conf and conf.chromeProfiles and #conf.chromeProfiles > 0 then
            for i, p in ipairs(conf.chromeProfiles) do
                table.insert(profiles, {
                    number = tostring(p.index or i),
                    dir = p.dir or ("Profile " .. tostring(i)),
                    name = p.name or p.customName or ("Profile " .. tostring(i)),
                    email = p.email,
                    menuCandidates = { p.name, p.customName, p.email }
                })
            end
            return profiles
        end
    end

    -- 2. Auto-discover from local Chrome / Chromium / Brave data
    local candidatePaths = {
        os.getenv("HOME") .. "/Library/Application Support/Google/Chrome/Local State",
        os.getenv("HOME") .. "/Library/Application Support/BraveSoftware/Brave-Browser/Local State",
        os.getenv("HOME") .. "/Library/Application Support/Microsoft Edge/Local State",
        os.getenv("HOME") .. "/Library/Application Support/Chromium/Local State"
    }

    for _, localStatePath in ipairs(candidatePaths) do
        if hs.fs.attributes(localStatePath) then
            local localState = hs.json.read(localStatePath)
            if localState and localState.profile and localState.profile.info_cache then
                local infoCache = localState.profile.info_cache
                local dirKeys = {}
                for k, _ in pairs(infoCache) do
                    table.insert(dirKeys, k)
                end

                table.sort(dirKeys, function(a, b)
                    if a == "Default" then return true end
                    if b == "Default" then return false end
                    return a < b
                end)

                local idx = 1
                for _, dirKey in ipairs(dirKeys) do
                    local info = infoCache[dirKey]
                    if info then
                        local profileName = info.name or info.gaia_name or info.user_name or (dirKey == "Default" and "Personal" or dirKey)
                        local email = info.user_name or info.email
                        local menuCandidates = { profileName }
                        if email and email ~= "" then
                            table.insert(menuCandidates, profileName .. " (" .. email .. ")")
                            table.insert(menuCandidates, email)
                        end

                        local useGaia = true
                        if info.use_gaia_picture == false or info.use_gaia_picture == 0 then
                            useGaia = false
                        end

                        table.insert(profiles, {
                            number = tostring(idx),
                            dir = dirKey,
                            name = profileName,
                            email = email,
                            useGaia = useGaia,
                            menuCandidates = menuCandidates
                        })

                        idx = idx + 1
                        if idx > MAX_PROFILES then break end
                    end
                end
                break
            end
        end
    end

    -- Fallback default if no profiles found
    if #profiles == 0 then
        table.insert(profiles, {
            number = "1",
            dir = "Default",
            name = "Default Profile",
            useGaia = true,
            menuCandidates = { "Default", "Personal" }
        })
    end

    return profiles
end

-- Get circular profile icon (loads cached or rasterizes into circular mask)
function ChromeProfiles.getProfileIcon(profile)
    if not profile then return nil end
    if profile.cachedIcon then return profile.cachedIcon end

    local sharedConfigDir = os.getenv("HOME") .. "/.config/mac-productivity-suite"

    if profile.useGaia ~= false then
        local candidatePaths = {
            os.getenv("HOME") .. "/Library/Application Support/Google/Chrome/" .. profile.dir .. "/Google Profile Picture.png",
            os.getenv("HOME") .. "/Library/Application Support/Google/Chrome/" .. profile.dir .. "/Google Profile Picture.jpg",
            os.getenv("HOME") .. "/Library/Application Support/Google/Chrome/" .. profile.dir .. "/Google Profile Picture",
            sharedConfigDir .. "/assets/profiles/" .. profile.dir .. ".png",
            os.getenv("HOME") .. "/Library/Application Support/BraveSoftware/Brave-Browser/" .. profile.dir .. "/Google Profile Picture.png",
            os.getenv("HOME") .. "/Library/Application Support/Microsoft Edge/" .. profile.dir .. "/Edge Profile Picture.png"
        }

        for _, picPath in ipairs(candidatePaths) do
            if hs.fs.attributes(picPath) then
                local img = hs.image.imageFromPath(picPath)
                if img then
                    local circular = makeCircularImage(img)
                    profile.cachedIcon = circular
                    return circular
                end
            end
        end
    end

    -- Monogram / Chrome fallback
    local c = hs.canvas.new({x = 0, y = 0, w = 96, h = 96})
    local colors = {
        {red = 0.22, green = 0.50, blue = 0.95, alpha = 1.0},
        {red = 0.58, green = 0.30, blue = 0.88, alpha = 1.0},
        {red = 0.95, green = 0.42, blue = 0.25, alpha = 1.0},
        {red = 0.18, green = 0.70, blue = 0.45, alpha = 1.0},
        {red = 0.92, green = 0.65, blue = 0.15, alpha = 1.0}
    }
    local colIdx = (string.byte(profile.name or "C") % #colors) + 1
    local bg = colors[colIdx]

    c[1] = {
        type = "rectangle",
        action = "fill",
        roundedRectRadii = {xRadius = 48, yRadius = 48},
        fillColor = bg
    }
    c[2] = {
        type = "text",
        text = string.upper(string.sub(profile.name or "C", 1, 1)),
        textColor = {white = 1.0, alpha = 1.0},
        textSize = 48,
        textAlignment = "center",
        frame = {x = 0, y = 18, w = 96, h = 60}
    }
    local monogram = c:imageFromCanvas()
    c:delete()
    profile.cachedIcon = monogram
    return monogram
end

-- Find a discovered profile by directory name
function ChromeProfiles.findProfileByDir(dir)
    for idx, p in ipairs(ChromeProfiles.profiles) do
        if p.dir == dir then
            return p, idx
        end
    end
    return nil, nil
end

-- Select a profile through Chrome's native macOS Profiles menu bar
local function selectProfileFromChrome(chrome, profile)
    if not chrome then return false end

    local name = profile.name or profile.dir or ""
    local email = profile.email or ""

    local as = string.format([[
        tell application "Google Chrome" to activate
        tell application "System Events"
            tell process "Google Chrome"
                if exists menu "Profiles" of menu bar 1 then
                    set pMenu to menu "Profiles" of menu bar 1
                    set targetName to %q
                    set targetEmail to %q

                    if targetName is not "" and (exists menu item targetName of pMenu) then
                        click menu item targetName of pMenu
                        return "OK"
                    end if

                    repeat with mi in (every menu item of pMenu)
                        set miName to name of mi
                        if miName is not missing value then
                            if (targetName is not "" and miName contains targetName) or (targetEmail is not "" and miName contains targetEmail) then
                                click mi
                                return "OK"
                            end if
                        end if
                    end repeat
                end if
            end tell
        end tell
        return "FALLBACK"
    ]], name, email)

    local success, result = hs.osascript.applescript(as)
    if success and result == "OK" then
        return true
    end

    return false
end

-- Launch or focus a specific Chrome profile
function ChromeProfiles.focusProfile(profile)
    if not profile then return end

    local pIdx = tonumber(profile.number)
    if pIdx then
        ChromeProfiles.lastActiveProfileIndex = pIdx
    end

    local chrome = hs.application.find("Google Chrome", true)
    if chrome then
        local success = selectProfileFromChrome(chrome, profile)
        if success then
            return
        end
    end

    -- Fallback / Cold start: Launch Chrome directly to profile directory
    local cmd = string.format("open -b com.google.Chrome --args --profile-directory='%s'", profile.dir)
    hs.execute(cmd)

    hs.timer.doAfter(0.15, function()
        local c = hs.application.find("Google Chrome", true)
        if c then c:activate() end
    end)
end

-- Focus by 1-based index (1..4)
function ChromeProfiles.focusProfileByIndex(index)
    local p = ChromeProfiles.profiles[index]
    if p then
        ChromeProfiles.lastActiveProfileIndex = index
        ChromeProfiles.focusProfile(p)
    end
end

-- Enable contextual hotkeys when Chrome is frontmost
local function enableContextualHotkeys()
    if #contextualHotkeys > 0 then return end

    for _, p in ipairs(ChromeProfiles.profiles) do
        local profile = p
        local hk = hs.hotkey.bind(hyper, profile.number, function()
            ChromeProfiles.focusProfile(profile)
        end)
        table.insert(contextualHotkeys, hk)
    end
end

-- Disable contextual hotkeys when Chrome loses focus
local function disableContextualHotkeys()
    for _, hk in ipairs(contextualHotkeys) do
        hk:delete()
    end
    contextualHotkeys = {}
end

-- Application watcher: only enable number shortcuts 1..4 when Chrome is frontmost
local function handleAppEvent(appName, eventType, app)
    if appName == "Google Chrome" then
        if eventType == hs.application.watcher.activated then
            enableContextualHotkeys()
        elseif eventType == hs.application.watcher.deactivated then
            disableContextualHotkeys()
        end
    end
end

-- Initialize module
function ChromeProfiles.init()
    ChromeProfiles.cleanup()
    ChromeProfiles.profiles = ChromeProfiles.discoverProfiles()

    -- Pre-warm all profile icons into memory cache
    for _, p in ipairs(ChromeProfiles.profiles) do
        ChromeProfiles.getProfileIcon(p)
    end

    local frontApp = hs.application.frontmostApplication()
    if frontApp and frontApp:name() == "Google Chrome" then
        enableContextualHotkeys()
    end

    appWatcher = hs.application.watcher.new(handleAppEvent)
    appWatcher:start()

    print("Chrome Profiles module initialized with " .. #ChromeProfiles.profiles .. " discovered profiles.")
    return ChromeProfiles
end

-- Update mode dynamically ("hyper" or "classic")
function ChromeProfiles.setMode(mode)
    if mode == "classic" then
        currentMode = "classic"
        hyper = {"cmd", "alt"}
    elseif mode == "ctrl_opt" then
        currentMode = "ctrl_opt"
        hyper = {"ctrl", "alt"}
    elseif mode == "cmd_shift" then
        currentMode = "cmd_shift"
        hyper = {"cmd", "shift"}
    else
        currentMode = "hyper"
        hyper = {"cmd", "alt", "ctrl", "shift"}
    end

    if #contextualHotkeys > 0 then
        disableContextualHotkeys()
        enableContextualHotkeys()
    end
    print("ChromeProfiles mode set to: " .. currentMode)
end

-- Get current mode
function ChromeProfiles.getMode()
    return currentMode
end

-- Cleanup on reload
function ChromeProfiles.cleanup()
    disableContextualHotkeys()
    if appWatcher then
        appWatcher:stop()
        appWatcher = nil
    end
end

return ChromeProfiles
