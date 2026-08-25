local ChromeProfiles = {}

-- Modifiers for profile switching
local hyper = {"cmd", "alt", "ctrl", "shift"}
local standardModifiers = {"cmd", "alt", "ctrl"}

-- Ordered profile definitions matching the Default account pop-up window
local profiles = {
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

local hotkeyObjects = {}

-- Select a profile through Chrome's native macOS Profiles menu bar
-- In Chrome, clicking the profile menu item:
-- 1. Focuses the last active window for that profile if one is already open (no new window created)
-- 2. Opens exactly one new window if no window exists for that profile
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
    local displayName = profile.name

    -- Show instant HUD confirmation
    hs.alert.show(string.format("Chrome: [%s] %s", profile.number, displayName), 0.8)

    local chrome = hs.application.find("Google Chrome")

    if chrome then
        -- When Chrome is running, use native menu bar profile selection to focus existing window
        local success = selectProfileFromChrome(chrome, profile)
        if success then
            return
        end
    end

    -- Cold start or fallback: launch Chrome targeted to that profile directory without forcing a new instance
    local cmd = string.format("open -b com.google.Chrome --args --profile-directory='%s'", profile.dir)
    hs.execute(cmd)

    hs.timer.doAfter(0.1, function()
        local c = hs.application.find("Google Chrome")
        if c then
            c:activate()
        end
    end)
end

-- Initialize hotkeys
function ChromeProfiles.init()
    -- Clear any existing hotkeys
    ChromeProfiles.cleanup()

    for _, profile in ipairs(profiles) do
        local p = profile

        -- Bind Hyper (Caps Lock) + Number
        local hkHyper = hs.hotkey.bind(hyper, p.number, function()
            ChromeProfiles.focusProfile(p)
        end)
        table.insert(hotkeyObjects, hkHyper)

        -- Bind Cmd + Alt + Ctrl + Number
        local hkStd = hs.hotkey.bind(standardModifiers, p.number, function()
            ChromeProfiles.focusProfile(p)
        end)
        table.insert(hotkeyObjects, hkStd)
    end

    print("Chrome Profiles module initialized (" .. #profiles .. " profiles configured).")
    return ChromeProfiles
end

-- Cleanup on reload
function ChromeProfiles.cleanup()
    for _, hk in ipairs(hotkeyObjects) do
        hk:delete()
    end
    hotkeyObjects = {}
end

return ChromeProfiles
