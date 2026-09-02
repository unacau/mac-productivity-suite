import Foundation
import CoreGraphics
import Cocoa

// MARK: - HID Mapping Service
public enum HIDMappingService {
    public static let hidCapsLock: UInt64 = 0x700000039
    public static let hidF18: UInt64 = 0x70000006D
    
    @discardableResult
    public static func applyCapsLockToF18(processProvider: ProcessProvider = SystemProcessProvider()) -> Bool {
        let json = "{\"UserKeyMapping\":[{\"HIDKeyboardModifierMappingSrc\":\(hidCapsLock),\"HIDKeyboardModifierMappingDst\":\(hidF18)}]}"
        do {
            try processProvider.runCommand(launchPath: "/usr/bin/hidutil", arguments: ["property", "--set", json])
            AppLogger.getLogger(category: .engine).info("Applied Caps Lock -> F18 mapping via hidutil.")
            return true
        } catch {
            AppLogger.getLogger(category: .engine).error("Failed to set hidutil mapping: \(error.localizedDescription)")
            return false
        }
    }
    
    @discardableResult
    public static func restoreDefaultMapping(processProvider: ProcessProvider = SystemProcessProvider()) -> Bool {
        do {
            try processProvider.runCommand(launchPath: "/usr/bin/hidutil", arguments: ["property", "--set", "{\"UserKeyMapping\":[]}"])
            AppLogger.getLogger(category: .engine).info("Restored default HID key mapping.")
            return true
        } catch {
            AppLogger.getLogger(category: .engine).error("Failed to restore hidutil mapping: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - HyperKey Engine
@MainActor
public final class HyperKeyEngine: @unchecked Sendable {
    public static let shared = HyperKeyEngine()
    
    public static let f18KeyCode: Int64 = Int64(KeyCodes.kVK_F18) // 79 (0x4F)
    public static let escKeyCode: CGKeyCode = CGKeyCode(KeyCodes.kVK_Escape) // 53 (0x35)
    public static let capsLockKeyCode: Int64 = 57 // Fallback virtual keycode
    public static let syntheticMarker: Int64 = 0x4D505354 // "MPST"
    
    private var eventTapPort: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isStarted = false
    
    public var isHyperActive: Bool = false
    public var hyperUsedAsModifier: Bool = false
    public var escapeOnTapEnabled: Bool = true
    
    public var processProvider: ProcessProvider = SystemProcessProvider()
    
    /// Optional handler to check if a character key is handled by the app switcher
    public var keyBindingHandler: (@MainActor (String) -> Bool)?
    
    public init(processProvider: ProcessProvider = SystemProcessProvider()) {
        self.processProvider = processProvider
        setupWakeNotification()
    }
    
    public func start() {
        guard !isStarted else { return }
        
        // 1. Accessibility check
        guard AXIsProcessTrusted() else {
            AppLogger.getLogger(category: .engine).warning("Accessibility permission missing. Global event tap cannot be registered.")
            return
        }
        
        // 2. Apply driver-level Caps Lock -> F18 remapping
        HIDMappingService.applyCapsLockToF18(processProvider: processProvider)
        
        // 3. Register CoreGraphics Head-Insert Event Tap
        let eventMask: CGEventMask = (
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)
        )
        
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { proxy, type, event, refcon in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let engine = Unmanaged<HyperKeyEngine>.fromOpaque(refcon).takeUnretainedValue()
                return engine.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: selfPtr
        ) else {
            AppLogger.getLogger(category: .engine).error("Failed to create CGEventTap for HyperKeyEngine.")
            Task { @MainActor in
                let alert = NSAlert()
                alert.messageText = "macOS Accessibility Bug Detected"
                alert.informativeText = "Mac Productivity Suite has Accessibility permission, but macOS denied the global event tap. This usually happens when the app is updated and macOS caches the old signature.\n\nPlease go to System Settings > Privacy & Security > Accessibility, remove the app with the '-' button, and add it back with the '+' button."
                alert.alertStyle = .critical
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
            return
        }
        
        eventTapPort = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isStarted = true
        
        AppLogger.getLogger(category: .engine).info("HyperKeyEngine event tap started successfully.")
    }
    
    public func stop() {
        if let tap = eventTapPort {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            }
            eventTapPort = nil
            runLoopSource = nil
        }
        HIDMappingService.restoreDefaultMapping(processProvider: processProvider)
        isStarted = false
        isHyperActive = false
        hyperUsedAsModifier = false
    }
    
    private func setupWakeNotification() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let engine = self else { return }
                AppLogger.getLogger(category: .engine).info("System woke from sleep: Re-applying HID Caps Lock mapping.")
                HIDMappingService.applyCapsLockToF18(processProvider: engine.processProvider)
                if let port = engine.eventTapPort {
                    CGEvent.tapEnable(tap: port, enable: true)
                }
            }
        }
    }
    
    // MARK: - Event Tap Processing
    public func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // 1. Auto-recover tap if disabled under heavy system load
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let port = eventTapPort {
                CGEvent.tapEnable(tap: port, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }
        
        // 2. Ignore synthetic events generated by our own engine to prevent loops
        if event.getIntegerValueField(.eventSourceUserData) == Self.syntheticMarker {
            return Unmanaged.passUnretained(event)
        }
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        
        // 3. F18 KeyDown: Caps Lock held down (remapped by hidutil)
        if type == .keyDown && keyCode == Self.f18KeyCode {
            if !isHyperActive {
                isHyperActive = true
                hyperUsedAsModifier = false
            }
            return nil // Swallow F18 down
        }
        
        // 4. F18 KeyUp: Caps Lock released
        if type == .keyUp && keyCode == Self.f18KeyCode {
            let wasUsed = hyperUsedAsModifier
            isHyperActive = false
            hyperUsedAsModifier = false
            
            // Dual-role check: If released without any modifier use, emit Escape!
            if !wasUsed && escapeOnTapEnabled {
                postSyntheticEscape()
            } else if wasUsed {
                AppSwitcherEngine.shared.commitAndHide()
            }
            return nil // Swallow F18 up
        }
        
        // 5. Fallback for unremapped Caps Lock (flagsChanged on keycode 57)
        if type == .flagsChanged && keyCode == Self.capsLockKeyCode {
            let isDown = event.flags.contains(.maskAlphaShift)
            if isDown {
                isHyperActive = true
                hyperUsedAsModifier = false
            } else {
                let wasUsed = hyperUsedAsModifier
                isHyperActive = false
                hyperUsedAsModifier = false
                if !wasUsed && escapeOnTapEnabled {
                    postSyntheticEscape()
                }
            }
            return nil
        }
        
        // 6. Any other key while Hyper is held down
        if isHyperActive && (type == .keyDown || type == .keyUp) {
            hyperUsedAsModifier = true
            
            // If the key is mapped to an internal shortcut, trigger it and swallow
            if let char = KeyCodes.character(for: UInt32(keyCode)) {
                if let handler = keyBindingHandler, handler(char) {
                    return nil // Swallowed: application handled this shortcut
                }
            }
            
            // Unmapped key: inject Hyper modifier flags (Cmd + Opt + Ctrl + Shift) for third-party hotkeys
            let hyperFlags: CGEventFlags = [
                .maskCommand, .maskAlternate, .maskControl, .maskShift
            ]
            event.flags = CGEventFlags(rawValue: event.flags.rawValue | hyperFlags.rawValue)
            return Unmanaged.passUnretained(event)
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    public func postSyntheticEscape() {
        let src = CGEventSource(stateID: .hidSystemState)
        guard let down = CGEvent(keyboardEventSource: src, virtualKey: Self.escKeyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: src, virtualKey: Self.escKeyCode, keyDown: false) else {
            return
        }
        
        down.setIntegerValueField(.eventSourceUserData, value: Self.syntheticMarker)
        up.setIntegerValueField(.eventSourceUserData, value: Self.syntheticMarker)
        
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}
