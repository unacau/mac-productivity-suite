local obj = {}

-- Store local state within the module
obj.startPos = nil
obj.dragThreshold = 10
obj.excludedBundleIDs = { "com.apple.Terminal", "com.googlecode.iterm2", "com.apple.Console" }

function obj.init()
    -- 1. Record mouse position when you click down
    obj.downTap = hs.eventtap.new({ hs.eventtap.event.types.leftMouseDown }, function(e)
        obj.startPos = hs.mouse.absolutePosition()
        return false 
    end):start()

    -- 2. Check position when you release the click
    obj.upTap = hs.eventtap.new({ hs.eventtap.event.types.leftMouseUp }, function(e)
        if not obj.startPos then return false end

        local endPos = hs.mouse.absolutePosition()
        local clicks = e:getProperty(hs.eventtap.event.properties.mouseEventClickState)
        
        -- Check if current app should be ignored
        local currentApp = hs.application.frontmostApplication()
        if currentApp and hs.fnutils.contains(obj.excludedBundleIDs, currentApp:bundleID()) then
            obj.startPos = nil
            return false
        end

        -- Calculate distance moved
        local dx = math.abs(endPos.x - obj.startPos.x)
        local dy = math.abs(endPos.y - obj.startPos.y)

        -- Copy if dragged > threshold OR if double/triple clicked
        if (dx > obj.dragThreshold or dy > obj.dragThreshold) or (clicks > 1) then
            hs.timer.doAfter(0.15, function()
                hs.eventtap.keyStroke({"cmd"}, "c")
            end)
        end
        
        obj.startPos = nil
        return false
    end):start()

    print("Copy-on-Select module initialized successfully.")
end

return obj