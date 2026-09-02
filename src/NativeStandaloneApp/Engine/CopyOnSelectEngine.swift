import Foundation
import Cocoa
import CoreGraphics

@MainActor
public final class CopyOnSelectEngine: @unchecked Sendable {
    public static let shared = CopyOnSelectEngine()
    
    public var isEnabled: Bool = false
    public var dragThreshold: CGFloat = 10.0
    public var copyDelayMs: UInt64 = 150
    
    public var excludedBundleIDs: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "com.mitchellh.ghostty",
        "dev.warp.Warp-Stable",
        "io.alacritty",
        "net.kovidgoyal.kitty",
        "com.apple.Console"
    ]
    
    private var mouseDownLocation: CGPoint?
    private var globalMouseDownMonitor: Any?
    private var globalMouseUpMonitor: Any?
    
    private init() {}
    
    public func start() {
        guard globalMouseDownMonitor == nil else { return }
        
        globalMouseDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard let engine = self, engine.isEnabled else { return }
            engine.mouseDownLocation = NSEvent.mouseLocation
        }
        
        globalMouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
            guard let engine = self, engine.isEnabled else { return }
            engine.handleMouseUp(event: event)
        }
        
        AppLogger.getLogger(category: .engine).info("CopyOnSelectEngine monitors installed.")
    }
    
    public func stop() {
        if let monitor = globalMouseDownMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseDownMonitor = nil
        }
        if let monitor = globalMouseUpMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseUpMonitor = nil
        }
        mouseDownLocation = nil
        AppLogger.getLogger(category: .engine).info("CopyOnSelectEngine stopped.")
    }
    
    private func handleMouseUp(event: NSEvent) {
        guard let startPos = mouseDownLocation else { return }
        self.mouseDownLocation = nil
        
        let endPos = NSEvent.mouseLocation
        let dx = abs(endPos.x - startPos.x)
        let dy = abs(endPos.y - startPos.y)
        let clicks = event.clickCount
        
        // Only trigger if dragged beyond threshold OR double/triple click selection
        let isSelection = (dx > dragThreshold || dy > dragThreshold) || (clicks > 1)
        guard isSelection else { return }
        
        // Check if frontmost application is excluded (e.g. terminals that have auto-copy or where Cmd+C interrupts)
        if let frontApp = NSWorkspace.shared.frontmostApplication,
           let bundleID = frontApp.bundleIdentifier,
           excludedBundleIDs.contains(bundleID) {
            return
        }
        
        let delay = copyDelayMs
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: delay * 1_000_000)
            self.postCopyKeystroke()
        }
    }
    
    public func postCopyKeystroke() {
        let src = CGEventSource(stateID: .hidSystemState)
        let cKeyCode: CGKeyCode = 0x08 // 'C'
        
        guard let down = CGEvent(keyboardEventSource: src, virtualKey: cKeyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: src, virtualKey: cKeyCode, keyDown: false) else {
            return
        }
        
        down.flags = .maskCommand
        up.flags = .maskCommand
        
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}
