import Cocoa

final class CopyOnSelectEngine {
    static let shared = CopyOnSelectEngine()
    
    private var isEnabled: Bool = true
    private var startPosition: NSPoint?
    private var globalMonitor: Any?
    private let dragThreshold: CGFloat = 12.0
    
    // Ignore terminal apps that already implement native select-to-copy
    private let excludedBundleIDs: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "com.apple.Console"
    ]
    
    private init() {
        startMonitoring()
    }
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
    
    func startMonitoring() {
        // Global monitor for mouse down to record start position
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            guard let self = self, self.isEnabled else { return }
            self.startPosition = NSEvent.mouseLocation
        }
        
        // Global monitor for mouse up to trigger Cmd+C if dragged
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] event in
            guard let self = self, self.isEnabled, let startPos = self.startPosition else { return }
            
            let endPos = NSEvent.mouseLocation
            let dx = abs(endPos.x - startPos.x)
            let dy = abs(endPos.y - startPos.y)
            let clickCount = event.clickCount
            
            self.startPosition = nil
            
            // Check frontmost app bundle ID
            if let frontApp = NSWorkspace.shared.frontmostApplication,
               let bundleID = frontApp.bundleIdentifier,
               self.excludedBundleIDs.contains(bundleID) {
                return
            }
            
            // If dragged beyond threshold OR double/triple clicked -> copy selection
            if (dx > self.dragThreshold || dy > self.dragThreshold) || clickCount > 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    self.synthesizeCopyKeystroke()
                }
            }
        }
    }
    
    private func synthesizeCopyKeystroke() {
        let src = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: src, virtualKey: 0x08, keyDown: true) // 'c'
        keyDown?.flags = .maskCommand
        let keyUp = CGEvent(keyboardEventSource: src, virtualKey: 0x08, keyDown: false)
        keyUp?.flags = .maskCommand
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
