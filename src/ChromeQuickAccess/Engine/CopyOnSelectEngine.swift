import Foundation
import CoreGraphics
import AppKit
import Cocoa
import os

@MainActor
public final class CopyOnSelectEngine: @unchecked Sendable {
    public static let shared = CopyOnSelectEngine()
    
    public var isEnabled: Bool = false
    public var dragThreshold: CGFloat = 10.0
    public var copyDelayMs: UInt64 = 150
    
    public var onCopyKeystrokePosted: (@MainActor () -> Void)?
    
    private var eventTapPort: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var globalMouseDownMonitor: Any?
    private var globalMouseUpMonitor: Any?
    private var mouseDownLocation: CGPoint?
    private var pendingCopyTask: Task<Void, Never>?
    public private(set) var isStarted: Bool = false
    
    public var hasPendingCopy: Bool {
        guard let task = pendingCopyTask else { return false }
        return !task.isCancelled
    }
    
    public func cancelPendingCopy() {
        pendingCopyTask?.cancel()
        pendingCopyTask = nil
    }
    
    public var isInteractingWithXomskyWindow: Bool {
        if NSApp.isActive { return true }
        if let frontID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
           let myID = Bundle.main.bundleIdentifier,
           frontID == myID {
            return true
        }
        let mouseLoc = NSEvent.mouseLocation
        return NSApp.windows.contains { window in
            window.isVisible && !(window is CopyToastWindow) && !(window is MinimalHUDWindow) && NSPointInRect(mouseLoc, window.frame)
        }
    }
    
    private let logger = Logger(subsystem: "com.almosteleven.xomsky", category: "copy-on-select")
    
    public init() {}
    
    public func start() {
        guard !isStarted else { return }
        
        guard AXIsProcessTrusted() else {
            logger.warning("Accessibility permission missing. CopyOnSelectEngine tap cannot be registered.")
            return
        }
        
        let eventMask: CGEventMask = (
            (1 << CGEventType.leftMouseDown.rawValue) |
            (1 << CGEventType.leftMouseUp.rawValue)
        )
        
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        if let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: { proxy, type, event, refcon in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let engine = Unmanaged<CopyOnSelectEngine>.fromOpaque(refcon).takeUnretainedValue()
                engine.handleTapEvent(type: type, event: event)
                return Unmanaged.passUnretained(event)
            },
            userInfo: selfPtr
        ) {
            eventTapPort = tap
            let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            runLoopSource = source
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            isStarted = true
            logger.info("CopyOnSelectEngine started with CGEventTap (.listenOnly).")
            TelemetryBuffer.shared.append(category: "copy-on-select", level: "INFO", message: "CopyOnSelectEngine started with CGEventTap.")
        } else {
            logger.warning("CGEventTap creation failed. Falling back to NSEvent global monitors.")
            installNSEventMonitors()
        }
    }
    
    public func stop() {
        cancelPendingCopy()
        if let tap = eventTapPort {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            }
            eventTapPort = nil
            runLoopSource = nil
        }
        if let monitor = globalMouseDownMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseDownMonitor = nil
        }
        if let monitor = globalMouseUpMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseUpMonitor = nil
        }
        mouseDownLocation = nil
        isStarted = false
        logger.info("CopyOnSelectEngine stopped.")
        TelemetryBuffer.shared.append(category: "copy-on-select", level: "INFO", message: "CopyOnSelectEngine stopped.")
    }
    
    private func installNSEventMonitors() {
        guard globalMouseDownMonitor == nil else { return }
        globalMouseDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let engine = self, engine.isEnabled else { return }
                guard !engine.isInteractingWithXomskyWindow else {
                    engine.mouseDownLocation = nil
                    return
                }
                engine.cancelPendingCopy()
                let flags = NSEvent.modifierFlags
                if flags.contains(.command) || flags.contains(.control) {
                    engine.mouseDownLocation = nil
                    return
                }
                engine.mouseDownLocation = NSEvent.mouseLocation
            }
        }
        globalMouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
            Task { @MainActor [weak self] in
                guard let engine = self, engine.isEnabled else { return }
                guard !engine.isInteractingWithXomskyWindow else {
                    engine.mouseDownLocation = nil
                    return
                }
                let flags = event.modifierFlags
                if flags.contains(.command) || flags.contains(.control) {
                    engine.mouseDownLocation = nil
                    return
                }
                let start = engine.mouseDownLocation ?? NSEvent.mouseLocation
                engine.mouseDownLocation = nil
                let end = NSEvent.mouseLocation
                let clicks = event.clickCount
                if engine.shouldTriggerCopy(start: start, end: end, clickCount: clicks) {
                    engine.scheduleCopy()
                }
            }
        }
        isStarted = true
        logger.info("CopyOnSelectEngine started with NSEvent global monitors.")
        TelemetryBuffer.shared.append(category: "copy-on-select", level: "INFO", message: "CopyOnSelectEngine started with NSEvent monitors.")
    }
    
    public func handleTapEvent(type: CGEventType, event: CGEvent) {
        // Auto-recover tap if disabled by system timeout or user input
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let port = eventTapPort {
                CGEvent.tapEnable(tap: port, enable: true)
                logger.info("Auto-recovered disabled event tap in CopyOnSelectEngine.")
            }
            return
        }
        
        guard isEnabled else { return }
        
        if isInteractingWithXomskyWindow {
            cancelPendingCopy()
            mouseDownLocation = nil
            return
        }
        
        // Ignore drags with Command or Control held (e.g. Cmd-drag windows, Ctrl-drag Xcode outlets)
        if event.flags.contains(.maskCommand) || event.flags.contains(.maskControl) {
            cancelPendingCopy()
            mouseDownLocation = nil
            return
        }
        
        if type == .leftMouseDown {
            cancelPendingCopy()
            mouseDownLocation = event.location
        } else if type == .leftMouseUp {
            guard let start = mouseDownLocation else { return }
            mouseDownLocation = nil
            let end = event.location
            let clicks = Int(event.getIntegerValueField(.mouseEventClickState))
            if shouldTriggerCopy(start: start, end: end, clickCount: clicks) {
                scheduleCopy()
            }
        }
    }
    
    public func shouldTriggerCopy(start: CGPoint, end: CGPoint, clickCount: Int) -> Bool {
        guard isEnabled else { return false }
        if isInteractingWithXomskyWindow { return false }
        if clickCount > 1 {
            return true
        }
        let dx = abs(end.x - start.x)
        let dy = abs(end.y - start.y)
        return dx > dragThreshold || dy > dragThreshold
    }
    
    public func scheduleCopy() {
        cancelPendingCopy()
        let delay = copyDelayMs
        TelemetryBuffer.shared.append(
            category: "copy-on-select",
            level: "INFO",
            message: "Text selection detected; scheduling Cmd+C in \(delay)ms."
        )
        pendingCopyTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: delay * 1_000_000)
            guard !Task.isCancelled else { return }
            guard let engine = self, engine.isEnabled && engine.isStarted else { return }
            guard !engine.isInteractingWithXomskyWindow else { return }
            engine.postCopyKeystroke()
        }
    }
    
    public func postCopyKeystroke() {
        let initialChangeCount = NSPasteboard.general.changeCount
        
        let src = CGEventSource(stateID: .hidSystemState)
        let cKeyCode: CGKeyCode = CGKeyCode(KeyCodes.kVK_ANSI_C)
        guard let down = CGEvent(keyboardEventSource: src, virtualKey: cKeyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: src, virtualKey: cKeyCode, keyDown: false) else {
            return
        }
        down.flags = .maskCommand
        up.flags = .maskCommand
        down.setIntegerValueField(.eventSourceUserData, value: CapsLockEngine.syntheticMarker)
        up.setIntegerValueField(.eventSourceUserData, value: CapsLockEngine.syntheticMarker)
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        logger.debug("Synthesized Cmd+C copy keystroke.")
        onCopyKeystrokePosted?()
        
        let mousePos = NSEvent.mouseLocation
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            // Wait 50ms for target application to process Cmd+C keystroke
            try? await Task.sleep(nanoseconds: 50_000_000)
            guard self.isEnabled && self.isStarted else { return }
            
            var newCount = NSPasteboard.general.changeCount
            if newCount == initialChangeCount {
                // Poll once more after another 70ms for heavier applications (e.g. Chromium, Electron)
                try? await Task.sleep(nanoseconds: 70_000_000)
                guard self.isEnabled && self.isStarted else { return }
                newCount = NSPasteboard.general.changeCount
            }
            
            let didChange = newCount != initialChangeCount
            TelemetryBuffer.shared.append(
                category: "copy-on-select",
                level: "INFO",
                message: "Cmd+C evaluated: changeCount \(initialChangeCount) -> \(newCount) (copied: \(didChange))"
            )
            
            if didChange {
                CopyToastWindow.shared.show(at: mousePos)
                TelemetryBuffer.shared.append(
                    category: "copy-on-select",
                    level: "INFO",
                    message: "Toast 'Copied!' displayed at (\(Int(mousePos.x)), \(Int(mousePos.y)))"
                )
            } else {
                self.logger.debug("Pasteboard unchanged after Cmd+C; suppressing false Copied toast.")
            }
        }
    }
}
