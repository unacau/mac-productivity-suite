local ChromeProfiles = {}

-- Modifiers for profile switching
local hyper = {"cmd", "alt", "ctrl", "shift"}

-- Ordered profile definitions matching the Default account pop-up window
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
        dir = "Profile 9",
        name = "GCP Free Trial",
        email = "",
        menuCandidates = {"GCP Free Trial"}
    },
    {
        number = "3",
        dir = "Profile 2",
        name = "Igor (Al11)",
        email = "igor@almosteleven.com",
        menuCandidates = {"Igor (Al11)", "Al11", "Igor • Al11", "Igor (igor@almosteleven.com)", "Igor Ekishev (Al11)", "Al11"}
    },
    {
        number = "4",
        dir = "Profile 5",
        name = "Igor (GCP Free Trial)",
        email = "igorekishev729@gmail.com",
        menuCandidates = {"Igor (GCP Free Trial)", "Igor • GCP Free Trial", "GCP Free Trial (igorekishev729@gmail.com)", "Igor Ekishev (GCP Free Trial)"}
    },
    {
        number = "5",
        dir = "Profile 1",
        name = "Nastya",
        email = "betapoozytron@gmail.com",
        menuCandidates = {"Nastya (betapoozytron@gmail.com)", "Nastya", "Nastya Muravyova", "Nastya Muravyova (Nastya)"}
    },
    {
        number = "6",
        dir = "Profile 10",
        name = "Nastya",
        email = "",
        menuCandidates = {"Nastya"}
    },
    {
        number = "7",
        dir = "Profile 8",
        name = "Zebra",
        email = "",
        menuCandidates = {"Zebra"}
    },
}

local contextualHotkeys = {}
local appWatcher = nil

-- Select a profile through Chrome's native macOS Profiles menu bar
local function selectProfileFromChrome(chrome, profile)
    if not chrome then return false end

    -- Activate Chrome first so menu is accessible
    chrome:activate()

    local menuItems = chrome:getMenuItems()
    local menuName = "Profiles"
    if menuItems then
        for _, topMenu in ipairs(menuItems) do
            if topMenu.AXTitle == "Profiles" or topMenu.AXTitle == "People" then
                menuName = topMenu.AXTitle
                break
            end
        end
    end

    -- 1. Try candidate titles directly
    for _, candidate in ipairs(profile.menuCandidates or {}) do
        if chrome:selectMenuItem({menuName, candidate}) then
            return true
        end
    end

    -- 2. Inspect menu items tree for partial or case-insensitive matching
    if menuItems then
        local profilesMenu = nil
        for _, topMenu in ipairs(menuItems) do
            if topMenu.AXTitle == menuName then
                profilesMenu = topMenu
                break
            end
        end

        if profilesMenu and profilesMenu.AXChildren and profilesMenu.AXChildren[1] then
            local subItems = profilesMenu.AXChildren[1].AXChildren or {}
            for _, item in ipairs(subItems) do
                local title = item.AXTitle
                if title and title ~= "" and not string.find(title, "^Edit") and not string.find(title, "^Customize") and not string.find(title, "^Manage") then
                    local lowerTitle = string.lower(title)
                    for _, candidate in ipairs(profile.menuCandidates or {}) do
                        if lowerTitle == string.lower(candidate) or string.find(lowerTitle, string.lower(candidate), 1, true) then
                            if chrome:selectMenuItem({menuName, title}) then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end

    return false
end

-- Launch or focus a specific Chrome profile
function ChromeProfiles.focusProfile(profile)
    if not profile then return end

    local displayName = profile.name
    hs.alert.show(string.format("Chrome: [%s] %s", profile.number, displayName), 0.8)

    local chrome = hs.application.find("Google Chrome")

    if chrome then
        local success = selectProfileFromChrome(chrome, profile)
        if success then
            return
        end
    end

    -- Fallback / Cold start: Launch Chrome directly to profile directory
    local cmd = string.format("open -b com.google.Chrome --args --profile-directory='%s'", profile.dir)
    hs.execute(cmd)

    hs.timer.doAfter(0.1, function()
        local c = hs.application.find("Google Chrome")
        if c then c:activate() end
    end)
end

-- Focus by 1-based index
function ChromeProfiles.focusProfileByIndex(index)
    local p = ChromeProfiles.profiles[index]
    if p then
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

-- Application watcher: only enable number shortcuts 1..7 when Chrome is frontmost
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

    -- Check if Chrome is already frontmost on load
    local frontApp = hs.application.frontmostApplication()
    if frontApp and frontApp:name() == "Google Chrome" then
        enableContextualHotkeys()
    end

    appWatcher = hs.application.watcher.new(handleAppEvent)
    appWatcher:start()

    print("Chrome Profiles module initialized (Contextual hotkeys active when Chrome is focused).")
    return ChromeProfiles
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
