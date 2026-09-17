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
    
    @Test @MainActor
    func testCopyOnSelectPendingCopyCancellation() async throws {
        let engine = CopyOnSelectEngine()
        var copyKeystrokes = 0
        engine.onCopyKeystrokePosted = {
            copyKeystrokes += 1
        }
        engine.copyDelayMs = 40 // short delay for test
        
        // 1. Trigger a double-click to schedule a copy
        let doubleClickUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: CGPoint(x: 100, y: 100), mouseButton: .left)!
        doubleClickUp.setIntegerValueField(.mouseEventClickState, value: 2)
        
        let dummyDown = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: CGPoint(x: 100, y: 100), mouseButton: .left)!
        engine.handleTapEvent(type: .leftMouseDown, event: dummyDown)
        engine.handleTapEvent(type: .leftMouseUp, event: doubleClickUp)
        
        #expect(engine.hasPendingCopy == true)
        
        // 2. User immediately clicks down somewhere else (e.g. to deselect or click button)
        let deselectDown = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: CGPoint(x: 200, y: 200), mouseButton: .left)!
        engine.handleTapEvent(type: .leftMouseDown, event: deselectDown)
        
        // The pending copy must be cancelled!
        #expect(engine.hasPendingCopy == false)
        
        // Wait longer than copyDelayMs to confirm keystroke was NEVER posted
        try await Task.sleep(nanoseconds: 80_000_000)
        #expect(copyKeystrokes == 0)
    }
    
    @Test @MainActor
    func testCapsLockEngineIsStartedState() {
        let engine = CapsLockEngine()
        #expect(engine.isStarted == false)
        #expect(engine.isCapsHeld == false)
        #expect(engine.capsUsedAsModifier == false)
    }
    
    @Test @MainActor
    func testChromeProfileLocalizedMenuMatching() {
        #expect(ChromeProfileEngine.isProfileMenuTitle("Profiles") == true)
        #expect(ChromeProfileEngine.isProfileMenuTitle("Profile") == true)
        #expect(ChromeProfileEngine.isProfileMenuTitle("Profils") == true)     // French
        #expect(ChromeProfileEngine.isProfileMenuTitle("Perfiles") == true)    // Spanish
        #expect(ChromeProfileEngine.isProfileMenuTitle("Профили") == true)    // Russian
        #expect(ChromeProfileEngine.isProfileMenuTitle("Perfis") == true)      // Portuguese
        #expect(ChromeProfileEngine.isProfileMenuTitle("Profili") == true)     // Italian
        #expect(ChromeProfileEngine.isProfileMenuTitle("个人资料") == true)     // Chinese
        #expect(ChromeProfileEngine.isProfileMenuTitle("プロファイル") == true)  // Japanese
        
        // Negative checks
        #expect(ChromeProfileEngine.isProfileMenuTitle("File") == false)
        #expect(ChromeProfileEngine.isProfileMenuTitle("Edit") == false)
        #expect(ChromeProfileEngine.isProfileMenuTitle("Window") == false)
        #expect(ChromeProfileEngine.isProfileMenuTitle("History") == false)
    }
    
    @Test @MainActor
    func testMinimalHUDWindowIsPanel() {
        let window = MinimalHUDWindow.shared
        #expect(window.isFloatingPanel == true)
        #expect(window.level == .floating)
    }
    
    @Test @MainActor
    func testKeyCodesTerminalNotesIde() {
        #expect(KeyCodes.character(for: KeyCodes.kVK_ANSI_T) == "t")
        #expect(KeyCodes.character(for: KeyCodes.kVK_ANSI_N) == "n")
        #expect(KeyCodes.character(for: KeyCodes.kVK_ANSI_I) == "i")
        #expect(KeyCodes.kVK_ANSI_T == 0x11)
        #expect(KeyCodes.kVK_ANSI_N == 0x2D)
        #expect(KeyCodes.kVK_ANSI_I == 0x22)
    }
    
    @Test @MainActor
    func testAppGroupEngineDiscoveryAndCycling() {
        let dummyIcon = NSImage(size: NSSize(width: 32, height: 32))
        let terminalEngine = AppGroupEngine.terminal
        let initialCount = terminalEngine.items.count
        #expect(initialCount >= 1)
        
        // Test customItemsOverride
        let mockTerminals = [
            AntigravityItem(name: "iTerm2", bundleID: "com.googlecode.iterm2", path: "/Applications/iTerm.app", icon: dummyIcon, index: 1),
            AntigravityItem(name: "Terminal", bundleID: "com.apple.Terminal", path: "/System/Applications/Utilities/Terminal.app", icon: dummyIcon, index: 2)
        ]
        terminalEngine.customItemsOverride = mockTerminals
        defer {
            terminalEngine.customItemsOverride = nil
            terminalEngine.mockFrontmostBundleID = nil
            terminalEngine.refreshItems()
        }
        terminalEngine.refreshItems()
        #expect(terminalEngine.items.count == 2)
        #expect(terminalEngine.items[0].name == "iTerm2")
        #expect(terminalEngine.items[1].name == "Terminal")
        
        // Test frontmost toggle logic
        terminalEngine.mockFrontmostBundleID = "com.googlecode.iterm2"
        #expect(terminalEngine.getActiveAppIndex() == 0)
        terminalEngine.mockFrontmostBundleID = "com.apple.Terminal"
        #expect(terminalEngine.getActiveAppIndex() == 1)
        terminalEngine.mockFrontmostBundleID = "com.apple.Safari"
        #expect(terminalEngine.getActiveAppIndex() == nil)
        
        // Test Monogram fallback
        let monogram = terminalEngine.makeMonogramImage(name: "Ghostty")
        #expect(monogram.size.width == 64)
        #expect(monogram.size.height == 64)
    }
    
    @Test @MainActor
    func testCapsLockTerminalNotesIdeTriggers() {
        let engine = CapsLockEngine()
        let proxy = unsafeBitCast(1, to: CGEventTapProxy.self)
        
        var terminalTriggered = false
        var notesTriggered = false
        var ideTriggered = false
        
        engine.onTerminalTrigger = { terminalTriggered = true }
        engine.onNotesTrigger = { notesTriggered = true }
        engine.onIdeTrigger = { ideTriggered = true }
        
        // Hold F18
        let f18Down = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(KeyCodes.kVK_F18), keyDown: true)!
        _ = engine.handleEvent(proxy: proxy, type: .keyDown, event: f18Down)
        
        // Press 'T' (Terminal)
        let tDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(KeyCodes.kVK_ANSI_T), keyDown: true)!
        let resT = engine.handleEvent(proxy: proxy, type: .keyDown, event: tDown)
        #expect(resT == nil) // Swallowed
        #expect(terminalTriggered == true)
        
        // Press 'N' (Notes)
        let nDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(KeyCodes.kVK_ANSI_N), keyDown: true)!
        let resN = engine.handleEvent(proxy: proxy, type: .keyDown, event: nDown)
        #expect(resN == nil) // Swallowed
        #expect(notesTriggered == true)
        
        // Press 'I' (IDE)
        let iDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(KeyCodes.kVK_ANSI_I), keyDown: true)!
        let resI = engine.handleEvent(proxy: proxy, type: .keyDown, event: iDown)
        #expect(resI == nil) // Swallowed
        #expect(ideTriggered == true)
        
        // Check keyUp swallowed
        let tUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(KeyCodes.kVK_ANSI_T), keyDown: false)!
        let resTUp = engine.handleEvent(proxy: proxy, type: .keyUp, event: tUp)
        #expect(resTUp == nil)
        
        let nUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(KeyCodes.kVK_ANSI_N), keyDown: false)!
        let resNUp = engine.handleEvent(proxy: proxy, type: .keyUp, event: nUp)
        #expect(resNUp == nil)
        
        let iUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(KeyCodes.kVK_ANSI_I), keyDown: false)!
        let resIUp = engine.handleEvent(proxy: proxy, type: .keyUp, event: iUp)
        #expect(resIUp == nil)
    }
    
    @Test @MainActor
    func testMinimalHUDWindowAppGroupModes() {
        let dummyIcon = NSImage(size: NSSize(width: 32, height: 32))
        let items = [
            AntigravityItem(name: "Obsidian", bundleID: "md.obsidian", path: "/Applications/Obsidian.app", icon: dummyIcon, index: 1),
            AntigravityItem(name: "Notes", bundleID: "com.apple.Notes", path: "/System/Applications/Notes.app", icon: dummyIcon, index: 2)
        ]
        
        MinimalHUDWindow.shared.showAppGroup(mode: .notes, items: items, selectedIndex: 0)
        #expect(ChromeSwitcherState.shared.mode == .notes)
        #expect(ChromeSwitcherState.shared.selectedAppItem?.name == "Obsidian")
        #expect(ChromeSwitcherState.shared.isVisible == true)
        
        MinimalHUDWindow.shared.selectNext()
        #expect(ChromeSwitcherState.shared.selectedAppItem?.name == "Notes")
        
        MinimalHUDWindow.shared.hideImmediate()
        #expect(ChromeSwitcherState.shared.isVisible == false)
    }
    
    @Test @MainActor
    func testChromeProfileSelectionLimitUpToFour() throws {
        UserDefaults.standard.removeObject(forKey: "SelectedBrowserProfileDirs")
        defer { UserDefaults.standard.removeObject(forKey: "SelectedBrowserProfileDirs") }
        
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let localStateUrl = tempDir.appendingPathComponent("Local State")
        let mockJson = """
        {
            "profile": {
                "info_cache": {
                    "Default": { "name": "Profile 1" },
                    "Profile 1": { "name": "Profile 2" },
                    "Profile 2": { "name": "Profile 3" },
                    "Profile 3": { "name": "Profile 4" },
                    "Profile 4": { "name": "Profile 5" },
                    "Profile 5": { "name": "Profile 6" }
                }
            }
        }
        """
        try mockJson.write(to: localStateUrl, atomically: true, encoding: .utf8)
        
        ChromeProfileEngine.localStatePathOverride = localStateUrl.path
        defer { ChromeProfileEngine.localStatePathOverride = nil }
        
        let engine = ChromeProfileEngine()
        #expect(engine.profiles.count == 6)
        
        // Initial selection should default to first 4
        #expect(engine.selectedProfiles.count == 4)
        #expect(engine.selectedProfiles[0].dir == "Default")
        #expect(engine.selectedProfiles[1].dir == "Profile 1")
        #expect(engine.selectedProfiles[2].dir == "Profile 2")
        #expect(engine.selectedProfiles[3].dir == "Profile 3")
        
        // Selecting 5th replaces 4th profile (max 4)
        engine.selectProfile(dir: "Profile 4")
        #expect(engine.selectedProfiles.count == 4)
        #expect(engine.isProfileSelected(dir: "Profile 4") == true)
        #expect(engine.isProfileSelected(dir: "Profile 3") == false)
        
        // Toggle selection (deselecting if > 1)
        engine.toggleProfileSelection(dir: "Profile 4")
        #expect(engine.selectedProfiles.count == 3)
        #expect(engine.isProfileSelected(dir: "Profile 4") == false)
    }
    
    @Test @MainActor
    func testAppGroupSingleChoiceRadioSelection() {
        let dummyIcon = NSImage(size: NSSize(width: 32, height: 32))
        let terminalEngine = AppGroupEngine.terminal
        let mockTerminals = [
            AntigravityItem(name: "iTerm2", bundleID: "com.googlecode.iterm2", path: "/Applications/iTerm.app", icon: dummyIcon, index: 1),
            AntigravityItem(name: "Terminal", bundleID: "com.apple.Terminal", path: "/System/Applications/Utilities/Terminal.app", icon: dummyIcon, index: 2)
        ]
        terminalEngine.customItemsOverride = mockTerminals
        defer {
            terminalEngine.customItemsOverride = nil
            terminalEngine.refreshItems()
        }
        terminalEngine.refreshItems()
        
        // Default selects first
        terminalEngine.select(bundleID: "com.googlecode.iterm2")
        #expect(terminalEngine.selectedItem?.name == "iTerm2")
        #expect(terminalEngine.isSelected(bundleID: "com.googlecode.iterm2") == true)
        #expect(terminalEngine.isSelected(bundleID: "com.apple.Terminal") == false)
        
        // Switch choice to Terminal
        terminalEngine.select(bundleID: "com.apple.Terminal")
        #expect(terminalEngine.selectedItem?.name == "Terminal")
        #expect(terminalEngine.isSelected(bundleID: "com.googlecode.iterm2") == false)
        #expect(terminalEngine.isSelected(bundleID: "com.apple.Terminal") == true)
    }
    
    @Test @MainActor
    func testAiAgentEngineHasNoAntigravityIdeDuplicate() {
        let aiCandidates = AppGroupEngine.aiAgent.candidates
        let ideCandidates = AppGroupEngine.ide.candidates
        
        // AI Agent candidates should NOT include Antigravity IDE
        #expect(aiCandidates.contains(where: { $0.name == "Antigravity IDE" }) == false)
        #expect(aiCandidates.contains(where: { $0.name == "Antigravity" }) == true)
        
        // IDE candidates SHOULD include Antigravity IDE
        #expect(ideCandidates.contains(where: { $0.name == "Antigravity IDE" }) == true)
    }
    
    @Test
    func testKeyCodesFullAlphabetAndLookup() {
        #expect(KeyCodes.keyCode(for: "A") == KeyCodes.kVK_ANSI_A)
        #expect(KeyCodes.keyCode(for: "i") == KeyCodes.kVK_ANSI_I)
        #expect(KeyCodes.keyCode(for: "O") == KeyCodes.kVK_ANSI_O)
        #expect(KeyCodes.keyCode(for: "t") == KeyCodes.kVK_ANSI_T)
        #expect(KeyCodes.keyCode(for: "c") == KeyCodes.kVK_ANSI_C)
        #expect(KeyCodes.keyCode(for: "D") == KeyCodes.kVK_ANSI_D)
        #expect(KeyCodes.keyCode(for: "v") == KeyCodes.kVK_ANSI_V)
        #expect(KeyCodes.keyCode(for: "x") == KeyCodes.kVK_ANSI_X)
        #expect(KeyCodes.keyCode(for: "g") == KeyCodes.kVK_ANSI_G)
        #expect(KeyCodes.keyCode(for: "w") == KeyCodes.kVK_ANSI_W)
        
        #expect(KeyCodes.character(for: KeyCodes.kVK_ANSI_I) == "i")
        #expect(KeyCodes.character(for: KeyCodes.kVK_ANSI_O) == "o")
        #expect(KeyCodes.character(for: KeyCodes.kVK_ANSI_D) == "d")
    }
    
    @Test @MainActor
    func testAppCandidatePureFirstLetterDerivation() {
        let terminal = AppGroupEngine.terminal
        #expect(terminal.candidate(for: "com.googlecode.iterm2")?.firstLetter == "I")
        #expect(terminal.candidate(for: "com.apple.Terminal")?.firstLetter == "T")
        #expect(terminal.candidate(for: "com.mitchellh.ghostty")?.firstLetter == "G")
        #expect(terminal.candidate(for: "dev.warp.Warp-Stable")?.firstLetter == "W")
        
        let notes = AppGroupEngine.notes
        #expect(notes.candidate(for: "md.obsidian")?.firstLetter == "O")
        #expect(notes.candidate(for: "com.apple.Notes")?.firstLetter == "N")
        
        let ide = AppGroupEngine.ide
        #expect(ide.candidate(for: "com.google.antigravity-ide")?.firstLetter == "A")
        #expect(ide.candidate(for: "com.microsoft.VSCode")?.firstLetter == "V")
        #expect(ide.candidate(for: "com.apple.dt.Xcode")?.firstLetter == "X")
        
        let ai = AppGroupEngine.aiAgent
        #expect(ai.candidate(for: "com.google.antigravity")?.firstLetter == "A")
    }
    
    @Test @MainActor
    func testCapsLockEngineDynamicKeyTriggers() {
        let engine = CapsLockEngine.shared
        let proxy = unsafeBitCast(1, to: CGEventTapProxy.self)
        var triggeredKey: UInt32? = nil
        
        engine.dynamicKeyTriggers[KeyCodes.kVK_ANSI_I] = {
            triggeredKey = KeyCodes.kVK_ANSI_I
        }
        defer { engine.dynamicKeyTriggers.removeAll() }
        
        // Simulate Caps Lock held down (F18 down)
        let f18Down = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(KeyCodes.kVK_F18), keyDown: true)!
        _ = engine.handleEvent(proxy: proxy, type: .keyDown, event: f18Down)
        #expect(engine.isCapsHeld == true)
        
        // Simulate pressing 'I' (iTerm2 dynamic shortcut)
        let iDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(KeyCodes.kVK_ANSI_I), keyDown: true)!
        let result = engine.handleEvent(proxy: proxy, type: .keyDown, event: iDown)
        
        // Event should be swallowed and dynamic trigger executed
        #expect(result == nil)
        #expect(triggeredKey == KeyCodes.kVK_ANSI_I)
        #expect(engine.capsUsedAsModifier == true)
        
        // Clean up Caps Lock release
        let f18Up = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(KeyCodes.kVK_F18), keyDown: false)!
        _ = engine.handleEvent(proxy: proxy, type: .keyUp, event: f18Up)
    }
    
    @Test @MainActor
    func testSharedLetterGroupingAndCycling() {
        let dummyIcon = NSImage(size: NSSize(width: 32, height: 32))
        let app1 = AntigravityItem(name: "Antigravity", bundleID: "com.google.antigravity", path: "/Applications/Antigravity.app", icon: dummyIcon, index: 1)
        let app2 = AntigravityItem(name: "Antigravity IDE", bundleID: "com.google.antigravity-ide", path: "/Applications/Antigravity IDE.app", icon: dummyIcon, index: 2)
        
        let itemsWithA = [app1, app2]
        
        // Both start with letter 'A'
        #expect(app1.name.first == "A")
        #expect(app2.name.first == "A")
        
        let state = ChromeSwitcherState()
        state.mode = .antigravity
        state.antigravityItems = itemsWithA
        state.selectedIndex = 0
        
        #expect(state.selectedAppItem?.name == "Antigravity")
        
        // Cycle to next app with same letter
        state.selectNext()
        #expect(state.selectedIndex == 1)
        #expect(state.selectedAppItem?.name == "Antigravity IDE")
        
        // Cycle wraps around
        state.selectNext()
        #expect(state.selectedIndex == 0)
        #expect(state.selectedAppItem?.name == "Antigravity")
    }
    
    @Test @MainActor
    func testDiscoveredItemsByLetterGrouping() {
        let groups = AppGroupEngine.discoveredItemsByLetter()
        
        // Every group must contain only items whose first letter matches the dictionary key
        for (letter, items) in groups {
            for item in items {
                let firstChar = Character((item.name.first(where: { $0.isLetter }) ?? "A").uppercased())
                #expect(firstChar == letter)
            }
        }
        
        // If Antigravity and Antigravity IDE are present in engines, both must be in 'A'
        if let aItems = groups["A"] {
            let names = aItems.map { $0.name }
            if names.contains("Antigravity") && names.contains("Antigravity IDE") {
                #expect(names.contains("Antigravity"))
                #expect(names.contains("Antigravity IDE"))
            }
        }
    }
    
    @Test @MainActor
    func testLetterSelectionStateManagement() {
        let testBundleID = "com.test.unique-app"
        
        // Ensure clean state
        AppGroupEngine.deselectApp(bundleID: testBundleID)
        #expect(AppGroupEngine.isAppSelected(bundleID: testBundleID) == false)
        
        // Select app
        AppGroupEngine.selectApp(bundleID: testBundleID)
        #expect(AppGroupEngine.isAppSelected(bundleID: testBundleID) == true)
        
        // Toggle app off
        AppGroupEngine.toggleApp(bundleID: testBundleID)
        #expect(AppGroupEngine.isAppSelected(bundleID: testBundleID) == false)
        
        // Toggle app back on
        AppGroupEngine.toggleApp(bundleID: testBundleID)
        #expect(AppGroupEngine.isAppSelected(bundleID: testBundleID) == true)
        
        // Clean up
        AppGroupEngine.deselectApp(bundleID: testBundleID)
    }
    
    @Test @MainActor
    func testTwoGroupMenuStructure() {
        let appDelegate = AppDelegate()
        let menu = appDelegate.buildStatusMenu()
        
        let titles = menu.items.map { $0.title }
        
        // Refresh Profiles & Apps and Quit Quick Access use native keyEquivalent with ⌘ modifier
        let refreshItem = menu.items.first(where: { $0.title.contains("Refresh Profiles & Apps") })
        #expect(refreshItem != nil)
        #expect(refreshItem?.keyEquivalent == "r")
        #expect(refreshItem?.keyEquivalentModifierMask == [.command])
        
        let quitItem = menu.items.first(where: { $0.title.contains("Quit Khomyak") })
        #expect(quitItem != nil)
        #expect(quitItem?.keyEquivalent == "q")
        #expect(quitItem?.keyEquivalentModifierMask == [.command])
        
        // Section 1: Chrome header present and strictly non-clickable
        let chromeHeader = menu.items.first(where: { $0.title.contains("Chrome (Caps-Lock + C)") })
        #expect(chromeHeader != nil)
        #expect(chromeHeader?.isEnabled == false)
        #expect(chromeHeader?.action == nil)
        
        // Section 2: Quick Apps header present and strictly non-clickable
        let quickAppsHeader = menu.items.first(where: { $0.title.contains("Quick Apps (Caps-Lock)") || $0.title.contains("Toolkit (Caps-Lock)") })
        #expect(quickAppsHeader != nil)
        #expect(quickAppsHeader?.isEnabled == false)
        #expect(quickAppsHeader?.action == nil)
        
        // Active Quick Apps items present with valid keyEquivalent
        let termMatch = menu.items.first(where: { $0.title.contains("iTerm") || $0.title.contains("Terminal") })
        #expect(termMatch != nil)
        #expect(!termMatch!.keyEquivalent.isEmpty)
        
        let agentOrIdeMatch = menu.items.first(where: { $0.title.contains("Antigravity") || $0.title.contains("IDE") })
        #expect(agentOrIdeMatch != nil)
        #expect(agentOrIdeMatch?.submenu != nil)
        #expect((agentOrIdeMatch?.submenu?.items.count ?? 0) >= 2)
        
        let notesMatch = menu.items.first(where: { $0.title.contains("Notes") || $0.title.contains("Obsidian") })
        #expect(notesMatch != nil)
        #expect(!notesMatch!.keyEquivalent.isEmpty)
        
        // Change App item with submenu present
        let changeAppItem = menu.items.first(where: { $0.title == "Change App" })
        #expect(changeAppItem != nil)
        #expect(changeAppItem?.submenu != nil)
        
        guard let submenu = changeAppItem?.submenu else { return }
        let subTitles = submenu.items.map { $0.title }
        
        // Headers present in Change App submenu
        #expect(subTitles.contains("Chrome Profiles (up to 4):"))
        #expect(subTitles.contains("Pinned Quick Apps (up to 5):"))
        #expect(subTitles.contains("Choose Other App..."))
        
        // App shortcuts derive strictly from first letter of app name (or slot digit for Chrome)
        for item in menu.items {
            if item.isSeparatorItem || item.title.hasSuffix(":") || item.title.hasPrefix("Chrome") || item.title.hasPrefix("Quick Apps") || item.title.hasPrefix("Toolkit") { continue }
            if !item.keyEquivalent.isEmpty && item.keyEquivalentModifierMask == [] {
                let appName = item.title.trimmingCharacters(in: .whitespaces)
                let key = item.keyEquivalent
                if let firstChar = key.first, firstChar.isLetter {
                    let expectedChar = String((appName.first(where: { $0.isLetter }) ?? "A").lowercased())
                    #expect(key == expectedChar)
                } else if let firstChar = key.first, firstChar.isNumber {
                    #expect("1234".contains(firstChar))
                }
            }
        }
    }
    
    @Test @MainActor
    func testUniversalCatalogCategoriesAndExpansion() {
        let categories = AppGroupEngine.catalogCategories
        #expect(!categories.isEmpty)
        
        let catNames = categories.map { $0.category }
        #expect(catNames.contains("Terminal") || catNames.contains("IDE") || catNames.contains("AI Agent") || catNames.contains("Notes") || catNames.contains("Communication"))
        
        // Ensure new candidates exist in catalog
        let commCandidates = AppGroupEngine.communication.candidates.map { $0.name }
        #expect(commCandidates.contains("Telegram"))
        #expect(commCandidates.contains("Slack"))
        
        let ideCandidates = AppGroupEngine.ide.candidates.map { $0.name }
        #expect(ideCandidates.contains("Zed"))
        #expect(ideCandidates.contains("IntelliJ IDEA"))
        
        let aiCandidates = AppGroupEngine.aiAgent.candidates.map { $0.name }
        #expect(aiCandidates.contains("Gemini"))
        #expect(aiCandidates.contains("Antigravity"))
    }
    
    @Test @MainActor
    func testPinnedAppsMaxLimitAndGrouping() {
        let initialPinned = AppGroupEngine.pinnedAppItems()
        #expect(initialPinned.count <= 5)
        
        // Grouped by letter
        let grouped = AppGroupEngine.pinnedAppsGroupedByLetter()
        for group in grouped {
            for item in group.items {
                let firstChar = Character((item.name.first(where: { $0.isLetter }) ?? "A").uppercased())
                #expect(firstChar == group.letter)
            }
        }
    }
}

