local obj = {}

obj.startPos = nil
obj.dragThreshold = 10
obj.excludedBundleIDs = {
    "com.apple.Terminal",
    "com.googlecode.iterm2",
    "com.mitchellh.ghostty",
    "dev.warp.Warp-Stable",
    "io.alacritty",
    "net.kovidgoyal.kitty",
    "com.apple.Console"
}

local function getActiveConfig()
    local baseDir = hs.configdir or (os.getenv("HOME") .. "/.hammerspoon")
    local configPath = baseDir .. "/config.json"
    if hs.fs.attributes(configPath) then
        local conf = hs.json.read(configPath)
        if conf and conf.copyOnSelect then
            return conf.copyOnSelect
        end
    end
    return nil
end

function obj.init()
    obj.cleanup()

    -- 1. Record mouse position when user clicks down
    obj.downTap = hs.eventtap.new({ hs.eventtap.event.types.leftMouseDown }, function(e)
        local conf = getActiveConfig()
        if conf and conf.enabled == false then return false end
        obj.startPos = hs.mouse.absolutePosition()
        return false
    end):start()

    -- 2. Check position and trigger copy on mouse release
    obj.upTap = hs.eventtap.new({ hs.eventtap.event.types.leftMouseUp }, function(e)
        local conf = getActiveConfig()
        if conf and conf.enabled == false then
            obj.startPos = nil
            return false
        end

        if not obj.startPos then return false end

        local endPos = hs.mouse.absolutePosition()
        local clicks = e:getProperty(hs.eventtap.event.properties.mouseEventClickState)
        
        -- Resolve active exclusion list
        local exclusions = (conf and conf.excludedBundleIDs) or obj.excludedBundleIDs
        local threshold = (conf and conf.dragThreshold) or obj.dragThreshold
        local delay = (conf and conf.copyDelayMs and (conf.copyDelayMs / 1000.0)) or 0.15

        -- Check if current frontmost app is excluded
        local currentApp = hs.application.frontmostApplication()
        if currentApp and hs.fnutils.contains(exclusions, currentApp:bundleID()) then
            obj.startPos = nil
            return false
        end

        -- Calculate distance moved
        local dx = math.abs(endPos.x - obj.startPos.x)
        local dy = math.abs(endPos.y - obj.startPos.y)

        -- Copy if dragged > threshold OR if double/triple clicked
        if (dx > threshold or dy > threshold) or (clicks > 1) then
            hs.timer.doAfter(delay, function()
                hs.eventtap.keyStroke({"cmd"}, "c")
            end)
        end
        
        obj.startPos = nil
        return false
    end):start()

    print("Copy-on-Select module initialized successfully.")
    return obj
end

function obj.cleanup()
    if obj.downTap then
        obj.downTap:stop()
        obj.downTap = nil
    end
    if obj.upTap then
        obj.upTap:stop()
        obj.upTap = nil
    end
    obj.startPos = nil
end

return obj