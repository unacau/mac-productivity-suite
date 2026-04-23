local CopyOnSelect = {}

-- Configuration
CopyOnSelect.config = {
    threshold = 5,
    copyDelay = 0.1, -- Increased delay to 100ms
    targetBundleID = "com.apple.Terminal" -- Use bundle ID for robustness
}

-- Store the tap in the table to prevent garbage collection
CopyOnSelect.tap = nil
-- Store the initial mouse down position
CopyOnSelect.mouseDownPos = nil

-- Helper function to calculate distance between two points
local function getDistance(p1, p2)
    if not p1 or not p2 then return 0 end
    return math.sqrt((p2.x - p1.x)^2 + (p2.y - p1.y)^2)
end

-- Callback for the event tap
local function handleEvent(event)
    local eventType = event:getType()
    
    if eventType == hs.eventtap.event.types.leftMouseDown then
        -- Record the starting position
        CopyOnSelect.mouseDownPos = hs.mouse.getAbsolutePosition()
    
    elseif eventType == hs.eventtap.event.types.leftMouseUp then
        local app = hs.application.frontmostApplication()
        if app and app:bundleID() == CopyOnSelect.config.targetBundleID then
            local mouseUpPos = hs.mouse.getAbsolutePosition()
            local distance = getDistance(CopyOnSelect.mouseDownPos, mouseUpPos)
            
            if distance > CopyOnSelect.config.threshold then
                -- Selection detected, trigger copy after a short delay
                hs.timer.doAfter(CopyOnSelect.config.copyDelay, function()
                    print("Automated copy triggered in Terminal")
                    hs.eventtap.keyStroke({"cmd"}, "c")
                end)
            end
        end
        -- Reset mouse down position
        CopyOnSelect.mouseDownPos = nil
    end
    
    -- Return false to let the event propagate to other applications
    return false
end

-- Initialize the module
function CopyOnSelect.init()
    -- Create the event tap for leftMouseDown and leftMouseUp
    CopyOnSelect.tap = hs.eventtap.new({
        hs.eventtap.event.types.leftMouseDown,
        hs.eventtap.event.types.leftMouseUp
    }, handleEvent)
    
    -- Start the tap
    CopyOnSelect.tap:start()
end

return CopyOnSelect
