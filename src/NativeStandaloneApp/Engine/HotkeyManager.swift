import Foundation
import Cocoa
import Carbon

public final class HotkeyManager {
    public static let shared = HotkeyManager()
    
    private var hotkeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var eventHandler: EventHandlerRef?
    private var handlers: [UInt32: @Sendable () -> Void] = [:]
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
            AppLogger.getLogger(category: .hotkeys).error("Failed to install Carbon event handler: \(status, privacy: .public)")
        }
    }
    
    public func dispatchHotKey(id: UInt32) {
        Task { @MainActor in
            self.handlers[id]?()
        }
    }
    
    @discardableResult
    public func register(keyCode: UInt32, modifiers: UInt32, action: @escaping @Sendable () -> Void) -> UInt32? {
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
            let registeredID = currentID
            hotkeyRefs[registeredID] = ref
            handlers[registeredID] = action
            currentID += 1
            return registeredID
        } else {
            AppLogger.getLogger(category: .hotkeys).error("Failed to register hotkey for keyCode \(keyCode): \(status)")
            return nil
        }
    }
    
    public func unregister(id: UInt32) {
        if let ref = hotkeyRefs[id] {
            UnregisterEventHotKey(ref)
            hotkeyRefs.removeValue(forKey: id)
            handlers.removeValue(forKey: id)
        }
    }
    
    public func unregisterAll() {
        for (_, ref) in hotkeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotkeyRefs.removeAll()
        handlers.removeAll()
    }
}

// Keycodes and Modifiers
public enum KeyCodes {
    // Carbon Modifiers
    public static let cmdModifier: UInt32 = 0x0100       // cmdKey
    public static let shiftModifier: UInt32 = 0x0200     // shiftKey
    public static let optionModifier: UInt32 = 0x0800    // optionKey
    public static let controlModifier: UInt32 = 0x1000   // controlKey
    
    public static let cmdOptModifiers: UInt32 = cmdModifier | optionModifier
    public static let cmdOptCtrlModifiers: UInt32 = cmdModifier | optionModifier | controlModifier
    public static let cmdShiftModifiers: UInt32 = cmdModifier | shiftModifier
    public static let ctrlOptModifiers: UInt32 = controlModifier | optionModifier
    public static let hyperModifiers: UInt32 = cmdModifier | optionModifier | controlModifier | shiftModifier
    
    public static let kVK_ANSI_A: UInt32 = 0x00
    public static let kVK_ANSI_S: UInt32 = 0x01
    public static let kVK_ANSI_D: UInt32 = 0x02
    public static let kVK_ANSI_F: UInt32 = 0x03
    public static let kVK_ANSI_H: UInt32 = 0x04
    public static let kVK_ANSI_G: UInt32 = 0x05
    public static let kVK_ANSI_Z: UInt32 = 0x06
    public static let kVK_ANSI_X: UInt32 = 0x07
    public static let kVK_ANSI_C: UInt32 = 0x08
    public static let kVK_ANSI_V: UInt32 = 0x09
    public static let kVK_ANSI_B: UInt32 = 0x0B
    public static let kVK_ANSI_Q: UInt32 = 0x0C
    public static let kVK_ANSI_W: UInt32 = 0x0D
    public static let kVK_ANSI_E: UInt32 = 0x0E
    public static let kVK_ANSI_R: UInt32 = 0x0F
    public static let kVK_ANSI_Y: UInt32 = 0x10
    public static let kVK_ANSI_T: UInt32 = 0x11
    public static let kVK_ANSI_1: UInt32 = 0x12
    public static let kVK_ANSI_2: UInt32 = 0x13
    public static let kVK_ANSI_3: UInt32 = 0x14
    public static let kVK_ANSI_4: UInt32 = 0x15
    public static let kVK_ANSI_6: UInt32 = 0x16
    public static let kVK_ANSI_5: UInt32 = 0x17
    public static let kVK_ANSI_Equal: UInt32 = 0x18
    public static let kVK_ANSI_9: UInt32 = 0x19
    public static let kVK_ANSI_7: UInt32 = 0x1A
    public static let kVK_ANSI_Minus: UInt32 = 0x1B
    public static let kVK_ANSI_8: UInt32 = 0x1C
    public static let kVK_ANSI_0: UInt32 = 0x1D
    public static let kVK_ANSI_RightBracket: UInt32 = 0x1E
    public static let kVK_ANSI_O: UInt32 = 0x1F
    public static let kVK_ANSI_U: UInt32 = 0x20
    public static let kVK_ANSI_LeftBracket: UInt32 = 0x21
    public static let kVK_ANSI_I: UInt32 = 0x22
    public static let kVK_ANSI_P: UInt32 = 0x23
    public static let kVK_ANSI_L: UInt32 = 0x25
    public static let kVK_ANSI_J: UInt32 = 0x26
    public static let kVK_ANSI_Quote: UInt32 = 0x27
    public static let kVK_ANSI_K: UInt32 = 0x28
    public static let kVK_ANSI_Semicolon: UInt32 = 0x29
    public static let kVK_ANSI_Backslash: UInt32 = 0x2A
    public static let kVK_ANSI_Comma: UInt32 = 0x2B
    public static let kVK_ANSI_Slash: UInt32 = 0x2C
    public static let kVK_ANSI_N: UInt32 = 0x2D
    public static let kVK_ANSI_M: UInt32 = 0x2E
    public static let kVK_ANSI_Period: UInt32 = 0x2F
    public static let kVK_Space: UInt32 = 0x31
    public static let kVK_Return: UInt32 = 0x24
    public static let kVK_Tab: UInt32 = 0x30
    public static let kVK_Escape: UInt32 = 0x35
    
    private static let charToKeyCodeMap: [String: UInt32] = [
        "a": kVK_ANSI_A, "b": kVK_ANSI_B, "c": kVK_ANSI_C, "d": kVK_ANSI_D,
        "e": kVK_ANSI_E, "f": kVK_ANSI_F, "g": kVK_ANSI_G, "h": kVK_ANSI_H,
        "i": kVK_ANSI_I, "j": kVK_ANSI_J, "k": kVK_ANSI_K, "l": kVK_ANSI_L,
        "m": kVK_ANSI_M, "n": kVK_ANSI_N, "o": kVK_ANSI_O, "p": kVK_ANSI_P,
        "q": kVK_ANSI_Q, "r": kVK_ANSI_R, "s": kVK_ANSI_S, "t": kVK_ANSI_T,
        "u": kVK_ANSI_U, "v": kVK_ANSI_V, "w": kVK_ANSI_W, "x": kVK_ANSI_X,
        "y": kVK_ANSI_Y, "z": kVK_ANSI_Z,
        "1": kVK_ANSI_1, "2": kVK_ANSI_2, "3": kVK_ANSI_3, "4": kVK_ANSI_4,
        "5": kVK_ANSI_5, "6": kVK_ANSI_6, "7": kVK_ANSI_7, "8": kVK_ANSI_8,
        "9": kVK_ANSI_9, "0": kVK_ANSI_0,
        "-": kVK_ANSI_Minus, "=": kVK_ANSI_Equal, "[": kVK_ANSI_LeftBracket, "]": kVK_ANSI_RightBracket,
        ";": kVK_ANSI_Semicolon, "'": kVK_ANSI_Quote, "\\": kVK_ANSI_Backslash,
        ",": kVK_ANSI_Comma, ".": kVK_ANSI_Period, "/": kVK_ANSI_Slash,
        "space": kVK_Space, "return": kVK_Return, "tab": kVK_Tab, "escape": kVK_Escape
    ]
    
    public static func keyCode(for character: String) -> UInt32? {
        charToKeyCodeMap[character.lowercased()]
    }
}
