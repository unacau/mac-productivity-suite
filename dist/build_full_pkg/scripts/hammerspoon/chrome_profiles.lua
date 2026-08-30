local ChromeProfiles = {}

-- Modifiers for profile switching (can be dynamically switched between "hyper" and "classic")
local hyper = {"cmd", "alt", "ctrl", "shift"}
local currentMode = "hyper"
local MAX_PROFILES = 4

-- 4 Configured Profiles matching user specification
ChromeProfiles.profiles = {
    {
        number = "1",
        dir = "Default",
        name = "Igor",
        email = "igorekishev92@gmail.com",
        menuCandidates = {"Igor", "Igor (igorekishev92@gmail.com)", "Igor Ekishev", "Igor Ekishev (Igor)"}
    },
    {
        number = "2",
        dir = "Profile 2",
        name = "Igor (Al11)",
        email = "igor@almosteleven.com",
        menuCandidates = {"Igor (Al11)", "Al11", "Igor • Al11", "Igor (igor@almosteleven.com)", "Igor Ekishev (Al11)", "Al11"}
    },
    {
        number = "3",
        dir = "Profile 5",
        name = "Igor (GCP Free Trial)",
        email = "igorekishev729@gmail.com",
        menuCandidates = {"Igor (GCP Free Trial)", "Igor • GCP Free Trial", "GCP Free Trial (igorekishev729@gmail.com)", "Igor Ekishev (GCP Free Trial)"}
    },
    {
        number = "4",
        dir = "Profile 1",
        name = "Nastya",
        email = "betapoozytron@gmail.com",
        menuCandidates = {"Nastya (betapoozytron@gmail.com)", "Nastya", "Nastya Muravyova", "Nastya Muravyova (Nastya)"}
    },
}

ChromeProfiles.lastActiveProfileIndex = 1

local contextualHotkeys = {}
local appWatcher = nil

-- Enforce strict maximum 4 profiles limit
local function validateProfiles()
    if #ChromeProfiles.profiles > MAX_PROFILES then
        local errMsg = string.format("ChromeProfiles Error: At most %d profiles allowed, but %d are configured!", MAX_PROFILES, #ChromeProfiles.profiles)
        hs.alert.show(errMsg, 5)
        error(errMsg)
    end
end

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

-- Get profile avatar icon (resolves custom theme avatar or Google Profile picture)
function ChromeProfiles.getProfileIcon(profile)
    if not profile then return nil end
    if profile.cachedIcon then return profile.cachedIcon end

    local baseDir = hs.configdir or (os.getenv("HOME") .. "/.hammerspoon")

    -- 1. Check pre-generated circular profile avatar in assets/profiles/
    local profileAsset = baseDir .. "/assets/profiles/" .. profile.dir .. ".png"
    if hs.fs.attributes(profileAsset) then
        local img = hs.image.imageFromPath(profileAsset)
        if img then
            profile.cachedIcon = img
            return img
        end
    end

    local localStatePath = os.getenv("HOME") .. "/Library/Application Support/Google/Chrome/Local State"
    local useGaia = true
    local avatarResource = nil

    if hs.fs.attributes(localStatePath) then
        local localState = hs.json.read(localStatePath)
        if localState and localState.profile and localState.profile.info_cache and localState.profile.info_cache[profile.dir] then
            local info = localState.profile.info_cache[profile.dir]
            if info.use_gaia_picture == false then
                useGaia = false
            end
            if info.avatar_icon then
                avatarResource = string.match(info.avatar_icon, "IDR_PROFILE_AVATAR_%d+")
            end
        end
    end

    -- 2. If using custom/theme avatar (e.g. Sunglasses IDR_PROFILE_AVATAR_44)
    if (not useGaia or avatarResource == "IDR_PROFILE_AVATAR_44") and avatarResource then
        local assetPath = baseDir .. "/assets/avatars/" .. avatarResource .. ".png"
        if hs.fs.attributes(assetPath) then
            local img = hs.image.imageFromPath(assetPath)
            if img then
                local circular = makeCircularImage(img)
                profile.cachedIcon = circular
                return circular
            end
        end
    end

    -- 3. If using Gaia profile picture and it exists on disk
    if useGaia then
        local gaiaPic = os.getenv("HOME") .. "/Library/Application Support/Google/Chrome/" .. profile.dir .. "/Google Profile Picture.png"
        if hs.fs.attributes(gaiaPic) then
            local img = hs.image.imageFromPath(gaiaPic)
            if img then
                local circular = makeCircularImage(img)
                profile.cachedIcon = circular
                return circular
            end
        end
    end

    -- 4. Fallback: Google Chrome application bundle icon
    local chromeIcon = hs.image.imageFromAppBundle("com.google.Chrome")
    profile.cachedIcon = chromeIcon
    return chromeIcon
end

-- Select a profile through Chrome's native macOS Profiles menu bar
local function selectProfileFromChrome(chrome, profile)
    if not chrome then return false end

    -- Activate Chrome first so menu is accessible
    chrome:activate()

    local menuCandidates = profile.menuCandidates or {profile.name}
    local topMenus = {"Profiles", "People"}

    -- Fast path (1-2ms): Directly select without expensive accessibility tree dump
    for _, menuName in ipairs(topMenus) do
        for _, candidate in ipairs(menuCandidates) do
            if chrome:selectMenuItem({menuName, candidate}) then
                return true
            end
        end
    end

    -- Fallback path: only scan getMenuItems() if fast path failed
    local menuItems = chrome:getMenuItems()
    if menuItems then
        for _, topMenu in ipairs(menuItems) do
            if topMenu.AXTitle == "Profiles" or topMenu.AXTitle == "People" then
                local menuName = topMenu.AXTitle
                if topMenu.AXChildren and topMenu.AXChildren[1] then
                    local subItems = topMenu.AXChildren[1].AXChildren or {}
                    for _, item in ipairs(subItems) do
                        local title = item.AXTitle
                        if title and title ~= "" and not string.find(title, "^Edit") and not string.find(title, "^Customize") and not string.find(title, "^Manage") then
                            local lowerTitle = string.lower(title)
                            for _, candidate in ipairs(menuCandidates) do
                                if lowerTitle == string.lower(candidate) or string.find(lowerTitle, string.lower(candidate), 1, true) then
                                    if chrome:selectMenuItem({menuName, title}) then
                                        return true
                                    end
                                end
                            end
                        end
                    end
                end
                break
            end
        end
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

    hs.timer.doAfter(0.05, function()
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
    validateProfiles()
    ChromeProfiles.cleanup()

    -- Pre-warm all profile icons into memory cache so hotkeys execute with 0 disk I/O
    for _, p in ipairs(ChromeProfiles.profiles) do
        ChromeProfiles.getProfileIcon(p)
    end

    -- Check if Chrome is already frontmost on load
    local frontApp = hs.application.frontmostApplication()
    if frontApp and frontApp:name() == "Google Chrome" then
        enableContextualHotkeys()
    end

    appWatcher = hs.application.watcher.new(handleAppEvent)
    appWatcher:start()

    print("Chrome Profiles module initialized (" .. #ChromeProfiles.profiles .. " profiles configured, max " .. MAX_PROFILES .. ").")
    return ChromeProfiles
end

-- Update mode dynamically ("hyper" or "classic")
function ChromeProfiles.setMode(mode)
    if mode == "classic" then
        currentMode = "classic"
        hyper = {"cmd", "alt"}
    else
        currentMode = "hyper"
        hyper = {"cmd", "alt", "ctrl", "shift"}
    end

    -- If contextual hotkeys are currently active, refresh them
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
