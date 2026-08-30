import Cocoa

@MainActor
public final class ProductivityActionsHelper {
    public static let shared = ProductivityActionsHelper()
    
    private init() {
        setupActions()
    }
    
    public func setupActions() {
        let config = AppConfigManager.shared.config
        let cmdOptCtrlModifiers = KeyCodes.cmdOptCtrlModifiers
        let cmdShiftModifiers = KeyCodes.cmdShiftModifiers
        
        // 1. Dual-column Finder Split: Cmd + Alt + Ctrl + F
        if config.productivityShortcuts.finderSplitEnabled {
            HotkeyManager.shared.register(keyCode: KeyCodes.kVK_ANSI_F, modifiers: cmdOptCtrlModifiers) {
                Task { @MainActor in
                    ProductivityActionsHelper.shared.splitFinderWindows()
                }
            }
        }
        
        // 2. Highlight text to markdown note: Cmd + Shift + H
        if config.productivityShortcuts.quickNotesEnabled {
            HotkeyManager.shared.register(keyCode: KeyCodes.kVK_ANSI_H, modifiers: cmdShiftModifiers) {
                Task { @MainActor in
                    ProductivityActionsHelper.shared.saveHighlightedText()
                }
            }
        }
    }
    
    public func splitFinderWindows() {
        let script = """
        tell application "Finder"
            if (count Finder windows) > 0 then
                set currentTarget to target of Finder window 1
                set newWin to make new Finder window
                set target of newWin to currentTarget
                set current view of newWin to column view
            end if
        end tell
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }
    
    public func saveHighlightedText() {
        let config = AppConfigManager.shared.config.productivityShortcuts
        
        // Synthesize Cmd+C
        let src = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: src, virtualKey: 0x08, keyDown: true)
        keyDown?.flags = .maskCommand
        let keyUp = CGEvent(keyboardEventSource: src, virtualKey: 0x08, keyDown: false)
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard let text = NSPasteboard.general.string(forType: .string), !text.isEmpty else { return }
            
            var targetDirPath = config.quickNotesDirectory
            if targetDirPath.hasPrefix("~") {
                targetDirPath = (NSHomeDirectory() as NSString).appendingPathComponent(String(targetDirPath.dropFirst(2)))
            }
            
            let dir = URL(fileURLWithPath: targetDirPath)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let fileURL = dir.appendingPathComponent("Quick_Notes.md")
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let timestamp = formatter.string(from: Date())
            
            let entry = "\n### Highlighted on \(timestamp)\n> \(text.replacingOccurrences(of: "\n", with: "\n> "))\n\n---\n"
            
            if let data = entry.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                        _ = try? fileHandle.seekToEnd()
                        try? fileHandle.write(contentsOf: data)
                        try? fileHandle.close()
                    }
                } else {
                    try? data.write(to: fileURL)
                }
            }
        }
    }
}
