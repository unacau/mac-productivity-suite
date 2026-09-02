import Foundation
import Testing
@testable import AppEngine

final class MockHotkeyProvider: @unchecked Sendable, HotkeyProvider {
    var registeredKeys: [(UInt32, UInt32, @Sendable () -> Void)] = []
    
    func register(keyCode: UInt32, modifiers: UInt32, handler: @escaping @Sendable () -> Void) -> UInt32? {
        registeredKeys.append((keyCode, modifiers, handler))
        return UInt32(registeredKeys.count)
    }
    
    func unregister(id: UInt32) {}
    
    func unregisterAll() {
        registeredKeys.removeAll()
    }
    
    func simulateKeyPress(keyCode: UInt32) {
        if let match = registeredKeys.first(where: { $0.0 == keyCode }) {
            match.2()
        }
    }
}

@Suite(.serialized)
struct AppSwitcherIntegrationTests {
    
    @Test @MainActor
    func testAppCyclingAndLaunch() async throws {
        // Sleep to avoid race condition with ConfigIntegrationTests modifying the AppConfigManager singleton
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let workspace = MockWorkspaceProvider()
        let hotkeys = MockHotkeyProvider()
        
        let engine = AppSwitcherEngine(workspace: workspace, hotkeys: hotkeys)
        
        // Setup config
        AppConfigManager.shared.config.bindings = [
            "c": ["Cursor", "TestAppThatDoesNotExist"]
        ]
        engine.setupBindings()
        
        guard let cKeyCode = KeyCodes.keyCode(for: "c") else {
            Issue.record("Could not find keycode for c")
            return
        }
        
        // 1. Simulate first press
        hotkeys.simulateKeyPress(keyCode: cKeyCode)
        try await Task.sleep(nanoseconds: 50_000_000) // Give Task a moment to run
        
        #expect(engine.isVisible == true)
        #expect(engine.currentItems.count == 2)
        #expect(engine.selectedIndex == 0) // Selects first by default
        
        // 2. Simulate second press (cycle)
        hotkeys.simulateKeyPress(keyCode: cKeyCode)
        try await Task.sleep(nanoseconds: 50_000_000)
        
        #expect(engine.selectedIndex == 1) // Selects second
        
        // 3. Commit the selection
        engine.commitAndHide()
        
        #expect(engine.isVisible == false)
        
        if workspace.fallbackNames.count == 0 {
            Issue.record("Fallback names was empty! openedURLs: \(workspace.openedURLs)")
        }
        
        #expect(workspace.fallbackNames.count == 1)
        #expect(workspace.fallbackNames.first == "TestAppThatDoesNotExist")
    }
    
    @Test @MainActor
    func testSingleAppHUDLaunch() async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let workspace = MockWorkspaceProvider()
        let hotkeys = MockHotkeyProvider()
        
        let engine = AppSwitcherEngine(workspace: workspace, hotkeys: hotkeys)
        
        // Single app binding
        AppConfigManager.shared.config.bindings = [
            "n": ["Notes"]
        ]
        engine.setupBindings()
        
        guard let nKeyCode = KeyCodes.keyCode(for: "n") else {
            Issue.record("Could not find keycode for n")
            return
        }
        
        hotkeys.simulateKeyPress(keyCode: nKeyCode)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(engine.isVisible == true, "HUD should be visible for single app selection")
        #expect(engine.currentItems.count == 1)
        #expect(engine.currentItems.first?.displayName == "Notes")
        
        // Manually trigger dismissal
        engine.hideHUDOnly()
        #expect(engine.isVisible == false)
    }
    
    @Test @MainActor
    func testChromeProfileExpansion() async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let workspace = MockWorkspaceProvider()
        let hotkeys = MockHotkeyProvider()
        let engine = AppSwitcherEngine(workspace: workspace, hotkeys: hotkeys)
        
        // Sole Chrome binding
        AppConfigManager.shared.config.bindings = [
            "c": ["Google Chrome"]
        ]
        engine.setupBindings()
        
        guard let cKeyCode = KeyCodes.keyCode(for: "c") else {
            Issue.record("Could not find keycode for c")
            return
        }
        
        hotkeys.simulateKeyPress(keyCode: cKeyCode)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(engine.isVisible == true)
        #expect(engine.currentItems.count >= 1)
        if ChromeProfileHelper.shared.profiles.count > 1 {
            #expect(engine.currentItems.count == ChromeProfileHelper.shared.profiles.count)
            #expect(engine.currentItems.allSatisfy { $0.isChromeProfile })
        }
        
        engine.hideHUDOnly()
    }
    
    @Test @MainActor
    func testExplicitChromeProfileBindings() async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let workspace = MockWorkspaceProvider()
        let hotkeys = MockHotkeyProvider()
        let engine = AppSwitcherEngine(workspace: workspace, hotkeys: hotkeys)
        
        // Explicit profile targets with redundant Google Chrome
        AppConfigManager.shared.config.bindings = [
            "c": ["Google Chrome", "chrome-profile:Default", "chrome-profile:Profile 1"]
        ]
        engine.setupBindings()
        
        guard let cKeyCode = KeyCodes.keyCode(for: "c") else {
            Issue.record("Could not find keycode for c")
            return
        }
        
        hotkeys.simulateKeyPress(keyCode: cKeyCode)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(engine.isVisible == true)
        #expect(engine.currentItems.count == 2, "Redundant Google Chrome should be stripped when explicit profiles are present")
        #expect(engine.currentItems.allSatisfy { $0.isChromeProfile })
        #expect(engine.currentItems.allSatisfy { !$0.displayName.contains("chrome-profile:") })
        
        engine.hideHUDOnly()
    }
    
    @Test @MainActor
    func testNumberKeyNavigationInHUD() async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let workspace = MockWorkspaceProvider()
        let hotkeys = MockHotkeyProvider()
        let engine = AppSwitcherEngine(workspace: workspace, hotkeys: hotkeys)
        
        // Explicit profile targets
        AppConfigManager.shared.config.bindings = [
            "c": ["chrome-profile:Default", "chrome-profile:Profile 1", "chrome-profile:Profile 2"]
        ]
        AppConfigManager.shared.config.autoDiscoverChromeProfiles = true
        engine.setupBindings()
        
        guard let cKeyCode = KeyCodes.keyCode(for: "c"),
              let twoKeyCode = KeyCodes.keyCode(for: "2"),
              let threeKeyCode = KeyCodes.keyCode(for: "3") else {
            Issue.record("Could not find keycodes for c, 2, or 3")
            return
        }
        
        // 1. Open HUD
        hotkeys.simulateKeyPress(keyCode: cKeyCode)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(engine.isVisible == true)
        #expect(engine.currentItems.count == 3)
        #expect(engine.selectedIndex == 0) // Default selected first
        
        // 2. Press number key "2" while HUD is active -> should jump to item index 1
        hotkeys.simulateKeyPress(keyCode: twoKeyCode)
        try await Task.sleep(nanoseconds: 50_000_000)
        
        #expect(engine.selectedIndex == 1, "Pressing '2' should move selector to second profile")
        
        // 3. Press number key "3" while HUD is active -> should jump to item index 2
        hotkeys.simulateKeyPress(keyCode: threeKeyCode)
        try await Task.sleep(nanoseconds: 50_000_000)
        
        #expect(engine.selectedIndex == 2, "Pressing '3' should move selector to third profile")
        
        // 4. Also test pressing '1' via handleKeyPress delegation
        engine.handleKeyPress(key: "1")
        #expect(engine.selectedIndex == 0, "Pressing '1' should move selector back to first profile")
        
        engine.hideHUDOnly()
    }
}
