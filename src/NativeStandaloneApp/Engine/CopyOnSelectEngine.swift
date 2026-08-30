import Cocoa

@MainActor
public final class CopyOnSelectEngine {
    public static let shared = CopyOnSelectEngine()
    
    private var startPosition: NSPoint?
    private var isMonitoring: Bool = false
    
    private init() {
        startMonitoring()
    }
    
    public func setEnabled(_ enabled: Bool) {
        AppConfigManager.shared.config.copyOnSelect.enabled = enabled
        AppConfigManager.shared.save()
    }
    
    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        // Global monitor for mouse down to record start position
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            guard let self = self else { return }
            let config = AppConfigManager.shared.config.copyOnSelect
            guard config.enabled else { return }
            self.startPosition = NSEvent.mouseLocation
        }
        
        // Global monitor for mouse up to trigger Cmd+C if dragged
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] event in
            guard let self = self else { return }
            let config = AppConfigManager.shared.config.copyOnSelect
            guard config.enabled, let startPos = self.startPosition else { return }
            
            let endPos = NSEvent.mouseLocation
            let dx = abs(endPos.x - startPos.x)
            let dy = abs(endPos.y - startPos.y)
            let clickCount = event.clickCount
            
            self.startPosition = nil
            
            // Check frontmost app against user-configurable excluded bundle IDs
            if let frontApp = NSWorkspace.shared.frontmostApplication,
               let bundleID = frontApp.bundleIdentifier {
                let lowerBundle = bundleID.lowercased()
                if config.excludedBundleIDs.contains(where: { $0.lowercased() == lowerBundle }) {
                    return
                }
            }
            
            // If dragged beyond threshold OR double/triple clicked -> copy selection
            let threshold = CGFloat(config.dragThreshold)
            if (dx > threshold || dy > threshold) || clickCount > 1 {
                let delay = Double(config.copyDelayMs) / 1000.0
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(delay))
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
