import Foundation
import Cocoa
import Carbon

final class HotkeyManager {
    static let shared = HotkeyManager()
    
    private var hotkeyRefs: [EventHotKeyRef] = []
    private var eventHandler: EventHandlerRef?
    private var handlers: [UInt32: () -> Void] = [:]
    private var currentID: UInt32 = 1
    
    private init() {
        setupCarbonEventHandler()
    }
    
    private func setupCarbonEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        let status = InstallEventHandler(GetEventDispatcherTarget(), { (handlerCallRef, eventRef, userData) -> OSStatus in
            guard let eventRef = eventRef else { return noErr }
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                eventRef,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            
            if status == noErr {
                HotkeyManager.shared.dispatchHotKey(id: hotKeyID.id)
            }
            return noErr
        }, 1, &eventType, nil, &eventHandler)
        
        if status != noErr {
            print("Failed to install Carbon event handler: \(status)")
        }
    }
    
    func dispatchHotKey(id: UInt32) {
        DispatchQueue.main.async {
            self.handlers[id]?()
        }
    }
    
    @discardableResult
    func register(keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) -> UInt32? {
        let hotKeyID = EventHotKeyID(signature: OSType(0x4D505354), id: currentID) // 'MPST'
        var hotKeyRef: EventHotKeyRef?
        
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr, let ref = hotKeyRef {
            hotkeyRefs.append(ref)
            handlers[currentID] = action
            let registeredID = currentID
            currentID += 1
            return registeredID
        } else {
            print("Failed to register hotkey for keyCode \(keyCode): \(status)")
            return nil
        }
    }
    
    func unregisterAll() {
        for ref in hotkeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotkeyRefs.removeAll()
        handlers.removeAll()
    }
}

// Common Keycodes and Modifiers
enum KeyCodes {
    // Carbon Modifiers
    static let cmdModifier: UInt32 = 0x0100       // cmdKey
    static let shiftModifier: UInt32 = 0x0200     // shiftKey
    static let optionModifier: UInt32 = 0x0800    // optionKey
    static let controlModifier: UInt32 = 0x1000   // controlKey
    
    static let cmdOptModifiers: UInt32 = cmdModifier | optionModifier
    static let cmdOptCtrlModifiers: UInt32 = cmdModifier | optionModifier | controlModifier
    static let cmdShiftModifiers: UInt32 = cmdModifier | shiftModifier
    
    static let kVK_ANSI_A: UInt32 = 0x00
    static let kVK_ANSI_S: UInt32 = 0x01
    static let kVK_ANSI_D: UInt32 = 0x02
    static let kVK_ANSI_F: UInt32 = 0x03
    static let kVK_ANSI_H: UInt32 = 0x04
    static let kVK_ANSI_G: UInt32 = 0x05
    static let kVK_ANSI_Z: UInt32 = 0x06
    static let kVK_ANSI_X: UInt32 = 0x07
    static let kVK_ANSI_C: UInt32 = 0x08
    static let kVK_ANSI_V: UInt32 = 0x09
    static let kVK_ANSI_B: UInt32 = 0x0B
    static let kVK_ANSI_Q: UInt32 = 0x0C
    static let kVK_ANSI_W: UInt32 = 0x0D
    static let kVK_ANSI_E: UInt32 = 0x0E
    static let kVK_ANSI_R: UInt32 = 0x0F
    static let kVK_ANSI_Y: UInt32 = 0x10
    static let kVK_ANSI_T: UInt32 = 0x11
    static let kVK_ANSI_1: UInt32 = 0x12
    static let kVK_ANSI_2: UInt32 = 0x13
    static let kVK_ANSI_3: UInt32 = 0x14
    static let kVK_ANSI_4: UInt32 = 0x15
    static let kVK_ANSI_6: UInt32 = 0x16
    static let kVK_ANSI_5: UInt32 = 0x17
    static let kVK_ANSI_Equal: UInt32 = 0x18
    static let kVK_ANSI_9: UInt32 = 0x19
    static let kVK_ANSI_7: UInt32 = 0x1A
    static let kVK_ANSI_Minus: UInt32 = 0x1B
    static let kVK_ANSI_8: UInt32 = 0x1C
    static let kVK_ANSI_0: UInt32 = 0x1D
    static let kVK_ANSI_O: UInt32 = 0x1F
    static let kVK_ANSI_U: UInt32 = 0x20
    static let kVK_ANSI_I: UInt32 = 0x22
    static let kVK_ANSI_P: UInt32 = 0x23
    static let kVK_ANSI_L: UInt32 = 0x25
    static let kVK_ANSI_J: UInt32 = 0x26
    static let kVK_ANSI_K: UInt32 = 0x28
    static let kVK_ANSI_N: UInt32 = 0x2D
    static let kVK_ANSI_M: UInt32 = 0x2E
}
