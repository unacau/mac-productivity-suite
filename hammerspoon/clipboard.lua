local obj = {}

function obj.init()
    hs.loadSpoon("ClipboardTool")
    
    -- 2. History Size: Keep it smaller to eliminate lag
    spoon.ClipboardTool.hist_size = 200
    
    -- Performance & Behavior
    spoon.ClipboardTool.paste_on_select = true
    spoon.ClipboardTool.show_copied_alert = false
    spoon.ClipboardTool.show_in_menubar = false
    
    -- THE LAG FIX: Stop writing to disk. (Note: History will clear if you reboot your Mac)
    spoon.ClipboardTool.persist_history = false 
    
    -- Bind your shortcut
    spoon.ClipboardTool:bindHotkeys({
        show_clipboard = {{"cmd", "alt"}, "v"}
    })
    
    spoon.ClipboardTool:start()
    
    -- 3. UI Tweaks (Making it wider acts as a better "Preview")
    if spoon.ClipboardTool.hist_chooser then
        spoon.ClipboardTool.hist_chooser:width(50) -- Screen width percentage (default is ~20)
        spoon.ClipboardTool.hist_chooser:rows(15)  -- Show 15 rows instead of 10
    end
    
    print("Clipboard manager initialized (Optimized for Speed).")
end

return obj