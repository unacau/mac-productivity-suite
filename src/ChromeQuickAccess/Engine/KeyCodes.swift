import Foundation
import CoreGraphics

public enum KeyCodes {
    // Virtual Keycodes for macOS (Carbon / HIToolbox standard)
    public static let kVK_ANSI_A: UInt32 = 0x00
    public static let kVK_ANSI_C: UInt32 = 0x08
    public static let kVK_ANSI_1: UInt32 = 0x12
    public static let kVK_ANSI_2: UInt32 = 0x13
    public static let kVK_ANSI_3: UInt32 = 0x14
    public static let kVK_ANSI_4: UInt32 = 0x15
    public static let kVK_ANSI_5: UInt32 = 0x17
    public static let kVK_ANSI_6: UInt32 = 0x16
    public static let kVK_ANSI_7: UInt32 = 0x1A
    public static let kVK_ANSI_8: UInt32 = 0x1C
    public static let kVK_ANSI_9: UInt32 = 0x19
    public static let kVK_Escape: UInt32 = 0x35
    public static let kVK_F18: UInt32 = 0x4F // 79
    public static let kVK_CapsLock: UInt32 = 0x39 // 57
    
    /// Map keycode to character string
    public static func character(for keyCode: UInt32) -> String? {
        switch keyCode {
        case kVK_ANSI_C: return "c"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        case kVK_Escape: return "escape"
        default: return nil
        }
    }
}
