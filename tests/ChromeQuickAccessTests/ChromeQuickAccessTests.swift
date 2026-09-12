import Foundation
import Testing
import AppKit
@testable import ChromeQuickAccess

@Suite(.serialized)
struct ChromeQuickAccessUnitTests {
    
    @Test @MainActor
    func testKeyCodes() {
        #expect(KeyCodes.character(for: KeyCodes.kVK_ANSI_A) == "a")
        #expect(KeyCodes.character(for: KeyCodes.kVK_ANSI_C) == "c")
        #expect(KeyCodes.character(for: KeyCodes.kVK_ANSI_1) == "1")
        #expect(KeyCodes.character(for: KeyCodes.kVK_ANSI_2) == "2")
        #expect(KeyCodes.character(for: KeyCodes.kVK_ANSI_3) == "3")
        #expect(KeyCodes.character(for: KeyCodes.kVK_ANSI_4) == "4")
        #expect(KeyCodes.character(for: KeyCodes.kVK_Escape) == "escape")
        #expect(KeyCodes.character(for: 0xFFFF) == nil)
    }
    
    @Test @MainActor
    func testChromeProfileDiscoveryFromLocalState() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let localStateUrl = tempDir.appendingPathComponent("Local State")
        let mockJson = """
        {
            "profile": {
                "info_cache": {
                    "Default": {
                        "name": "Personal",
                        "user_name": "igor@example.com",
                        "gaia_name": "Igor Ekishev",
                        "gaia_given_name": "Igor"
                    },
                    "Profile 1": {
                        "name": "Work",
                        "user_name": "igor@company.com",
                        "gaia_name": "Igor Ekishev Work",
                        "gaia_given_name": "Igor"
                    },
                    "Profile 2": {
                        "name": "Side Project",
                        "user_name": "admin@sideproject.dev"
                    }
                }
            }
        }
        """
        try mockJson.write(to: localStateUrl, atomically: true, encoding: .utf8)
        
        ChromeProfileEngine.localStatePathOverride = localStateUrl.path
        defer { ChromeProfileEngine.localStatePathOverride = nil }
        
        let engine = ChromeProfileEngine()
        let profiles = engine.profiles
        
        #expect(profiles.count == 3)
        #expect(profiles[0].dir == "Default")
        #expect(profiles[0].effectiveName == "Personal")
        #expect(profiles[0].expectedMenuTitle == "Igor (Personal)")
        #expect(profiles[0].index == 1)
        
        #expect(profiles[1].dir == "Profile 1")
        #expect(profiles[1].effectiveName == "Work")
        #expect(profiles[1].expectedMenuTitle == "Igor (Work)")
        #expect(profiles[1].index == 2)
        
        #expect(profiles[2].dir == "Profile 2")
        #expect(profiles[2].effectiveName == "Side Project")
        #expect(profiles[2].index == 3)
    }
    
    @Test @MainActor
    func testMonogramAvatarRendering() {
        let engine = ChromeProfileEngine()
        let monogram = engine.makeMonogramImage(name: "Work Profile", colorSeed: 42)
        #expect(monogram.size.width == 96)
        #expect(monogram.size.height == 96)
    }
    
    @Test @MainActor
    func testHIDMappingConstants() {
        #expect(HIDMappingService.hidCapsLock == 0x700000039)
        #expect(HIDMappingService.hidF18 == 0x70000006D)
    }
    
    @Test @MainActor
    func testKeyCodesExtended() {
        #expect(KeyCodes.kVK_LeftArrow == 0x7B)
        #expect(KeyCodes.kVK_RightArrow == 0x7C)
        #expect(KeyCodes.kVK_DownArrow == 0x7D)
        #expect(KeyCodes.kVK_UpArrow == 0x7E)
        #expect(KeyCodes.kVK_Tab == 0x30)
    }
    
    @Test @MainActor
    func testSwitcherCyclingAndSelection() {
        let state = ChromeSwitcherState()
        let sampleProfiles = [
            ChromeProfile(index: 1, dir: "Default", name: "Personal"),
            ChromeProfile(index: 2, dir: "Profile 1", name: "Work"),
            ChromeProfile(index: 3, dir: "Profile 2", name: "Side Project"),
            ChromeProfile(index: 4, dir: "Profile 3", name: "Gaming")
        ]
        
        state.profiles = sampleProfiles
        state.selectedIndex = 0
        #expect(state.selectedProfile?.effectiveName == "Personal")
        
        // Cycle forward (like pressing C)
        state.selectNext()
        #expect(state.selectedIndex == 1)
        #expect(state.selectedProfile?.effectiveName == "Work")
        
        state.selectNext()
        #expect(state.selectedIndex == 2)
        #expect(state.selectedProfile?.effectiveName == "Side Project")
        
        state.selectNext()
        #expect(state.selectedIndex == 3)
        #expect(state.selectedProfile?.effectiveName == "Gaming")
        
        // Wrap-around forward
        state.selectNext()
        #expect(state.selectedIndex == 0)
        #expect(state.selectedProfile?.effectiveName == "Personal")
        
        // Cycle backward (like Left Arrow / Shift+Tab)
        state.selectPrevious()
        #expect(state.selectedIndex == 3)
        #expect(state.selectedProfile?.effectiveName == "Gaming")
        
        state.selectPrevious()
        #expect(state.selectedIndex == 2)
        #expect(state.selectedProfile?.effectiveName == "Side Project")
        
        // Direct jump via number key (e.g. index 2 = Side Project)
        state.selectIndex(1)
        #expect(state.selectedIndex == 1)
        #expect(state.selectedProfile?.effectiveName == "Work")
        
        // Boundary clamping
        state.selectIndex(99)
        #expect(state.selectedIndex == 3)
        state.selectIndex(-5)
        #expect(state.selectedIndex == 0)
    }
    
    @Test @MainActor
    func testChromeAppIconHelper() {
        let icon = ChromeAppIconHelper.chromeIcon()
        #expect(icon.size.width > 0)
        #expect(icon.size.height > 0)
    }
    
    @Test @MainActor
    func testAntigravityEngineDiscovery() {
        let engine = AntigravityEngine.shared
        engine.refreshItems()
        let items = engine.items
        #expect(items.count == 2)
        #expect(items[0].name == "Antigravity")
        #expect(items[0].bundleID == "com.google.antigravity")
        #expect(items[0].index == 1)
        #expect(items[1].name == "Antigravity IDE")
        #expect(items[1].bundleID == "com.google.antigravity-ide")
        #expect(items[1].index == 2)
        
        let monogram = engine.makeMonogramImage(name: "Antigravity")
        #expect(monogram.size.width == 64)
        #expect(monogram.size.height == 64)
    }
    
    @Test @MainActor
    func testAntigravitySwitcherCyclingAndSelection() {
        let state = ChromeSwitcherState()
        state.mode = .antigravity
        let dummyIcon = NSImage(size: NSSize(width: 32, height: 32))
        let items = [
            AntigravityItem(name: "Antigravity", bundleID: "com.google.antigravity", path: "/Applications/Antigravity.app", icon: dummyIcon, index: 1),
            AntigravityItem(name: "Antigravity IDE", bundleID: "com.google.antigravity-ide", path: "/Applications/Antigravity IDE.app", icon: dummyIcon, index: 2)
        ]
        state.antigravityItems = items
        state.selectedIndex = 0
        
        #expect(state.selectedAntigravityItem?.name == "Antigravity")
        
        // Cycle forward (pressing 'A')
        state.selectNext()
        #expect(state.selectedIndex == 1)
        #expect(state.selectedAntigravityItem?.name == "Antigravity IDE")
        
        // Wrap-around forward
        state.selectNext()
        #expect(state.selectedIndex == 0)
        #expect(state.selectedAntigravityItem?.name == "Antigravity")
        
        // Cycle backward (Left Arrow / Shift+Tab)
        state.selectPrevious()
        #expect(state.selectedIndex == 1)
        #expect(state.selectedAntigravityItem?.name == "Antigravity IDE")
        
        // Direct jump via number key (e.g. 1 -> index 0)
        state.selectIndex(0)
        #expect(state.selectedIndex == 0)
        #expect(state.selectedAntigravityItem?.name == "Antigravity")
        
        // Clamping
        state.selectIndex(10)
        #expect(state.selectedIndex == 1)
        state.selectIndex(-3)
        #expect(state.selectedIndex == 0)
    }
    
    @Test @MainActor
    func testAntigravityFrontmostAppToggleLogic() {
        let engine = AntigravityEngine.shared
        defer { AntigravityEngine.mockFrontmostBundleID = nil }
        
        // If Antigravity is frontmost, active index is 0
        AntigravityEngine.mockFrontmostBundleID = "com.google.antigravity"
        #expect(engine.getActiveAppIndex() == 0)
        
        // If Antigravity IDE is frontmost, active index is 1
        AntigravityEngine.mockFrontmostBundleID = "com.google.antigravity-ide"
        #expect(engine.getActiveAppIndex() == 1)
        
        // If another app (e.g. Finder) is frontmost, active index is nil
        AntigravityEngine.mockFrontmostBundleID = "com.apple.finder"
        #expect(engine.getActiveAppIndex() == nil)
    }
    
    @Test @MainActor
    func testCopyOnSelectDefaultParameters() {
        let engine = CopyOnSelectEngine()
        #expect(engine.isEnabled == true)
        #expect(engine.dragThreshold == 10.0)
        #expect(engine.copyDelayMs == 150)
    }
    
    @Test @MainActor
    func testCopyOnSelectDragDistanceTrigger() {
        let engine = CopyOnSelectEngine()
        
        // Horizontal drag exceeding threshold (dx = 15 > 10)
        #expect(engine.shouldTriggerCopy(start: CGPoint(x: 100, y: 100), end: CGPoint(x: 115, y: 100), clickCount: 1) == true)
        
        // Vertical drag exceeding threshold (dy = 12 > 10)
        #expect(engine.shouldTriggerCopy(start: CGPoint(x: 100, y: 100), end: CGPoint(x: 100, y: 112), clickCount: 1) == true)
        
        // Negative direction drag exceeding threshold (dx = 15 > 10)
        #expect(engine.shouldTriggerCopy(start: CGPoint(x: 100, y: 100), end: CGPoint(x: 85, y: 100), clickCount: 1) == true)
        
        // Sub-threshold movement (dx = 5 <= 10, dy = 5 <= 10)
        #expect(engine.shouldTriggerCopy(start: CGPoint(x: 100, y: 100), end: CGPoint(x: 105, y: 105), clickCount: 1) == false)
    }
    
    @Test @MainActor
    func testCopyOnSelectMultiClickTrigger() {
        let engine = CopyOnSelectEngine()
        
        // Double-click at same position (word selection)
        #expect(engine.shouldTriggerCopy(start: CGPoint(x: 100, y: 100), end: CGPoint(x: 100, y: 100), clickCount: 2) == true)
        
        // Triple-click at same position (paragraph selection)
        #expect(engine.shouldTriggerCopy(start: CGPoint(x: 100, y: 100), end: CGPoint(x: 100, y: 100), clickCount: 3) == true)
    }
    
    @Test @MainActor
    func testCopyOnSelectSingleClickNoTrigger() {
        let engine = CopyOnSelectEngine()
        
        // Normal single click with zero displacement
        #expect(engine.shouldTriggerCopy(start: CGPoint(x: 250, y: 300), end: CGPoint(x: 250, y: 300), clickCount: 1) == false)
    }
    
    @Test @MainActor
    func testCopyOnSelectDisabledState() {
        let engine = CopyOnSelectEngine()
        engine.isEnabled = false
        
        // Exceeding drag threshold must be ignored when disabled
        #expect(engine.shouldTriggerCopy(start: CGPoint(x: 100, y: 100), end: CGPoint(x: 200, y: 200), clickCount: 1) == false)
        
        // Multi-click must be ignored when disabled
        #expect(engine.shouldTriggerCopy(start: CGPoint(x: 100, y: 100), end: CGPoint(x: 100, y: 100), clickCount: 2) == false)
    }
    
    @Test @MainActor
    func testCopyOnSelectPostKeystrokeCallback() {
        let engine = CopyOnSelectEngine()
        var callbackFired = false
        engine.onCopyKeystrokePosted = {
            callbackFired = true
        }
        
        engine.postCopyKeystroke()
        #expect(callbackFired == true)
    }
    
    @Test @MainActor
    func testCopyOnSelectLifecycleAndToggle() {
        let engine = CopyOnSelectEngine()
        #expect(engine.isEnabled == true)
        
        engine.isEnabled.toggle()
        #expect(engine.isEnabled == false)
        
        engine.isEnabled.toggle()
        #expect(engine.isEnabled == true)
        
        engine.stop()
        #expect(engine.isStarted == false)
    }
    
    @Test @MainActor
    func testProfileEffectiveNameFallbackHierarchy() {
        let p1 = ChromeProfile(index: 1, dir: "Profile 1", name: "", gaiaName: "Igor Corporate")
        #expect(p1.effectiveName == "Igor Corporate")
        
        let p2 = ChromeProfile(index: 2, dir: "Profile 2", name: "   ", email: "support@almosteleven.com")
        #expect(p2.effectiveName == "support@almosteleven.com")
        
        let p3 = ChromeProfile(index: 3, dir: "Profile 3", name: "")
        #expect(p3.effectiveName == "Profile 3")
        
        let pDefault = ChromeProfile(index: 4, dir: "Default", name: "")
        #expect(pDefault.effectiveName == "Personal")
    }
    
    @Test @MainActor
    func testProfileExpectedMenuTitleAndDisambiguation() {
        let pDefault = ChromeProfile(
            index: 1,
            dir: "Default",
            name: "Igor",
            email: "igor@gmail.com",
            gaiaName: "Igor Ekishev",
            gaiaGivenName: "Igor"
        )
        let pWork = ChromeProfile(
            index: 2,
            dir: "Profile 1",
            name: "Work",
            email: "igor@company.com",
            gaiaName: "Igor Ekishev",
            gaiaGivenName: "Igor"
        )
        
        #expect(pDefault.expectedMenuTitle == "Igor")
        #expect(pWork.expectedMenuTitle == "Igor (Work)")
    }
    
    @Test @MainActor
    func testProfileWhitespaceAndUnicodeCanonicalEquivalence() {
        let pWhitespace = ChromeProfile(index: 1, dir: "Profile 1", name: "   Staging Server   ")
        #expect(pWhitespace.effectiveName == "Staging Server")
        
        let pEmoji = ChromeProfile(index: 2, dir: "Profile 2", name: "Dev 🚀 [2026]")
        #expect(pEmoji.effectiveName == "Dev 🚀 [2026]")
    }
    
    @Test @MainActor
    func testCorruptedLocalStateJsonFallback() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let localStateUrl = tempDir.appendingPathComponent("Local State")
        try "{ this is not valid json! }".write(to: localStateUrl, atomically: true, encoding: .utf8)
        
        ChromeProfileEngine.localStatePathOverride = localStateUrl.path
        defer { ChromeProfileEngine.localStatePathOverride = nil }
        
        let engine = ChromeProfileEngine()
        #expect(engine.profiles.count == 1)
        #expect(engine.profiles.first?.dir == "Default")
        #expect(engine.profiles.first?.name == "Default Profile")
    }
    
    @Test @MainActor
    func testActiveProfileDirWhenChromeNotRunning() {
        let engine = ChromeProfileEngine.shared
        // With a dummy bundle ID that is definitely not running
        engine.browserBundleID = "com.nonexistent.browser.test"
        #expect(engine.getActiveProfileDir() == nil)
        #expect(engine.getProfilesMenuItems(bundleID: "com.nonexistent.browser.test").isEmpty)
        // Restore standard bundle ID
        engine.browserBundleID = "com.google.Chrome"
    }
    
    @Test @MainActor
    func testCapsLockHoldingWithShiftFlagsDoesNotPrematurelyRelease() {
        let engine = CapsLockEngine()
        let proxy = unsafeBitCast(1, to: CGEventTapProxy.self)
        
        var modifierReleasedCalled = false
        engine.onModifierReleased = {
            modifierReleasedCalled = true
        }
        
        // 1. User holds CapsLock (F18 KeyDown)
        let f18Down = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(KeyCodes.kVK_F18), keyDown: true)!
        let resDown = engine.handleEvent(proxy: proxy, type: .keyDown, event: f18Down)
        #expect(resDown == nil) // F18 down swallowed
        #expect(engine.isCapsHeld == true)
        #expect(engine.capsUsedAsModifier == false)
        
        // 2. User presses Shift while holding CapsLock (e.g. preparing for Shift-Tab navigation)
        let shiftEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0x38, keyDown: true)!
        shiftEvent.flags = [.maskShift]
        let resShift = engine.handleEvent(proxy: proxy, type: .flagsChanged, event: shiftEvent)
        #expect(resShift != nil) // Shift passthrough
        
        // CRITICAL BUG VERIFICATION: Shift MUST NOT cause premature modifier release!
        #expect(engine.isCapsHeld == true)
        #expect(modifierReleasedCalled == false)
        
        // 3. User releases CapsLock (F18 KeyUp)
        let f18Up = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(KeyCodes.kVK_F18), keyDown: false)!
        let resUp = engine.handleEvent(proxy: proxy, type: .keyUp, event: f18Up)
        #expect(resUp == nil) // F18 up swallowed
        #expect(engine.isCapsHeld == false)
    }
    
    @Test @MainActor
    func testCapsLockChromeTriggerAndModifierReleased() {
        let engine = CapsLockEngine()
        let proxy = unsafeBitCast(1, to: CGEventTapProxy.self)
        
        var chromeTriggered = false
        var modifierReleased = false
        engine.onChromeTrigger = { chromeTriggered = true }
        engine.onModifierReleased = { modifierReleased = true }
        
        // Hold F18
        let f18Down = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(KeyCodes.kVK_F18), keyDown: true)!
        _ = engine.handleEvent(proxy: proxy, type: .keyDown, event: f18Down)
        #expect(engine.isCapsHeld == true)
        
        // Press 'C'
        let cDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(KeyCodes.kVK_ANSI_C), keyDown: true)!
        let resC = engine.handleEvent(proxy: proxy, type: .keyDown, event: cDown)
        #expect(resC == nil) // 'C' swallowed
        #expect(chromeTriggered == true)
        #expect(engine.capsUsedAsModifier == true)
        
        // Release F18
        let f18Up = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(KeyCodes.kVK_F18), keyDown: false)!
        _ = engine.handleEvent(proxy: proxy, type: .keyUp, event: f18Up)
        #expect(modifierReleased == true)
        #expect(engine.isCapsHeld == false)
    }
    
    @Test @MainActor
    func testCapsLockAntigravityTrigger() {
        let engine = CapsLockEngine()
        let proxy = unsafeBitCast(1, to: CGEventTapProxy.self)
        
        var antigravityTriggered = false
        engine.onAntigravityTrigger = { antigravityTriggered = true }
        
        // Hold F18
        let f18Down = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(KeyCodes.kVK_F18), keyDown: true)!
        _ = engine.handleEvent(proxy: proxy, type: .keyDown, event: f18Down)
        
        // Press 'A'
        let aDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(KeyCodes.kVK_ANSI_A), keyDown: true)!
        let resA = engine.handleEvent(proxy: proxy, type: .keyDown, event: aDown)
        #expect(resA == nil) // 'A' swallowed
        #expect(antigravityTriggered == true)
        #expect(engine.capsUsedAsModifier == true)
    }
    
    @Test @MainActor
    func testCapsLockProfileDigitAndNavigationTriggers() {
        let engine = CapsLockEngine()
        let proxy = unsafeBitCast(1, to: CGEventTapProxy.self)
        
        var selectedDigit = 0
        var navLeftCalled = false
        var navRightCalled = false
        var cancelCalled = false
        
        engine.onProfileTrigger = { digit in selectedDigit = digit }
        engine.onNavigateLeft = { navLeftCalled = true }
        engine.onNavigateRight = { navRightCalled = true }
        engine.onCancelTrigger = { cancelCalled = true }
        
        // Hold F18
        let f18Down = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(KeyCodes.kVK_F18), keyDown: true)!
        _ = engine.handleEvent(proxy: proxy, type: .keyDown, event: f18Down)
        
        // Press '3'
        let digit3Down = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(KeyCodes.kVK_ANSI_3), keyDown: true)!
        let resDigit = engine.handleEvent(proxy: proxy, type: .keyDown, event: digit3Down)
        #expect(resDigit == nil)
        #expect(selectedDigit == 3)
        
        // Press Right Arrow -> Navigate Right
        let rightDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(KeyCodes.kVK_RightArrow), keyDown: true)!
        let resRight = engine.handleEvent(proxy: proxy, type: .keyDown, event: rightDown)
        #expect(resRight == nil)
        #expect(navRightCalled == true)
        
        // Press Left Arrow -> Navigate Left
        let leftDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(KeyCodes.kVK_LeftArrow), keyDown: true)!
        let resLeft = engine.handleEvent(proxy: proxy, type: .keyDown, event: leftDown)
        #expect(resLeft == nil)
        #expect(navLeftCalled == true)
        
        // Press Escape -> Cancel HUD
        let escDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(KeyCodes.kVK_Escape), keyDown: true)!
        let resEsc = engine.handleEvent(proxy: proxy, type: .keyDown, event: escDown)
        #expect(resEsc == nil)
        #expect(cancelCalled == true)
    }
    
    @Test @MainActor
    func testCopyOnSelectIgnoresCommandOrControlDrags() {
        let engine = CopyOnSelectEngine()
        
        var copyPosted = false
        engine.onCopyKeystrokePosted = { copyPosted = true }
        
        // MouseDown with Command modifier held (e.g. moving background window)
        let cmdDown = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: CGPoint(x: 100, y: 100), mouseButton: .left)!
        cmdDown.flags = [.maskCommand]
        engine.handleTapEvent(type: .leftMouseDown, event: cmdDown)
        
        // MouseUp with Command modifier held
        let cmdUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: CGPoint(x: 300, y: 300), mouseButton: .left)!
        cmdUp.flags = [.maskCommand]
        engine.handleTapEvent(type: .leftMouseUp, event: cmdUp)
        
        #expect(copyPosted == false)
        
        // MouseDown with Control modifier held (e.g. connecting Xcode IBOutlet)
        let ctrlDown = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: CGPoint(x: 100, y: 100), mouseButton: .left)!
        ctrlDown.flags = [.maskControl]
        engine.handleTapEvent(type: .leftMouseDown, event: ctrlDown)
        
        let ctrlUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: CGPoint(x: 300, y: 300), mouseButton: .left)!
        ctrlUp.flags = [.maskControl]
        engine.handleTapEvent(type: .leftMouseUp, event: ctrlUp)
        
        #expect(copyPosted == false)
    }
    
    @Test @MainActor
    func testCopyOnSelectTapDisablementRecovery() {
        let engine = CopyOnSelectEngine()
        let dummy = CGEvent(source: nil)!
        
        // Must handle disabled by timeout without throwing or crashing
        engine.handleTapEvent(type: .tapDisabledByTimeout, event: dummy)
        engine.handleTapEvent(type: .tapDisabledByUserInput, event: dummy)
        #expect(engine.isEnabled == true)
    }
}
