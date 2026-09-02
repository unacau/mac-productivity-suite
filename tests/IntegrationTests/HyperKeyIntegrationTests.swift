import Foundation
import Testing
@testable import AppEngine

extension SerializedTests {
    
    @Test @MainActor
    func testHIDMappingServiceArgSynthesis() throws {
        let mockProcess = MockProcessProvider()
        
        // 1. Test applying mapping
        let success = HIDMappingService.applyCapsLockToF18(processProvider: mockProcess)
        #expect(success == true)
        #expect(mockProcess.commandsRun.count == 1)
        
        let (cmd, args) = mockProcess.commandsRun[0]
        #expect(cmd == "/usr/bin/hidutil")
        #expect(args.contains("property"))
        #expect(args.contains("--set"))
        
        // Verify JSON content has CapsLock (0x700000039 = 30064771129) and F18 (0x70000006D = 30064771181)
        let jsonArg = args.last ?? ""
        #expect(jsonArg.contains("30064771129"), "Should contain HID usage for Caps Lock")
        #expect(jsonArg.contains("30064771181"), "Should contain HID usage for F18")
        
        // 2. Test restoring default mapping
        let restoreSuccess = HIDMappingService.restoreDefaultMapping(processProvider: mockProcess)
        #expect(restoreSuccess == true)
        #expect(mockProcess.commandsRun.count == 2)
        
        let (_, restoreArgs) = mockProcess.commandsRun[1]
        let restoreJson = restoreArgs.last ?? ""
        #expect(restoreJson.contains("\"UserKeyMapping\":[]"), "Should clear key mappings")
    }
    
    @Test @MainActor
    func testHyperKeyStateTransitions() {
        let mockProcess = MockProcessProvider()
        let engine = HyperKeyEngine(processProvider: mockProcess)
        
        #expect(engine.isHyperActive == false)
        #expect(engine.hyperUsedAsModifier == false)
        
        // 1. Simulate keyBindingHandler
        var triggeredKey: String? = nil
        engine.keyBindingHandler = { key in
            triggeredKey = key
            return key == "t"
        }
        
        #expect(engine.keyBindingHandler?("t") == true)
        #expect(triggeredKey == "t")
        #expect(engine.keyBindingHandler?("z") == false)
        
        // 2. Test stop restores default mapping
        engine.stop()
        #expect(mockProcess.commandsRun.contains(where: { $0.1.contains("{\"UserKeyMapping\":[]}") }))
    }
    
    @Test @MainActor
    func testCopyOnSelectConfiguration() {
        let engine = CopyOnSelectEngine.shared
        
        #expect(engine.excludedBundleIDs.contains("com.apple.Terminal"))
        #expect(engine.excludedBundleIDs.contains("com.googlecode.iterm2"))
        #expect(engine.excludedBundleIDs.contains("com.mitchellh.ghostty"))
        #expect(engine.dragThreshold == 10.0)
    }
    
    @Test @MainActor
    func testKeyCodeReverseLookup() {
        #expect(KeyCodes.character(for: KeyCodes.kVK_ANSI_A) == "a")
        #expect(KeyCodes.character(for: KeyCodes.kVK_ANSI_T) == "t")
        #expect(KeyCodes.character(for: KeyCodes.kVK_ANSI_1) == "1")
        #expect(KeyCodes.character(for: KeyCodes.kVK_Space) == "space")
        #expect(KeyCodes.kVK_F18 == 79)
    }
}
