import Foundation
import Cocoa
import Testing
@testable import AppEngine

struct ProductivitySuiteTests {
    
    @Test @MainActor
    func configSerialization() throws {
        var config = AppConfig.default
        config.bindings["z"] = ["Zed", "Zoom", "chrome-profile:Default"]
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AppConfig.self, from: data)
        
        #expect(decoded.bindings["z"] == ["Zed", "Zoom", "chrome-profile:Default"])
    }
    
    @Test @MainActor
    func hotkeyKeycodeMapping() {
        let testKeys = ["a", "c", "i", "s", "t", "1", "9", "space", "return", "escape", "-"]
        for k in testKeys {
            let code = KeyCodes.keyCode(for: k)
            #expect(code != nil, "Failed to map key '\(k)' to Carbon virtual keycode")
        }
        
        #expect(KeyCodes.keyCode(for: "a") == KeyCodes.kVK_ANSI_A)
        #expect(KeyCodes.keyCode(for: "1") == KeyCodes.kVK_ANSI_1)
        #expect(KeyCodes.keyCode(for: "space") == KeyCodes.kVK_Space)
    }
    
    @Test @MainActor
    func appDiscoveryAndResolution() {
        let service = AppDiscoveryService.shared
        
        let finder = service.findApp(nameOrBundle: "Finder")
        #expect(finder != nil, "Finder should always be discovered on macOS")
        
        let smart = service.generateSmartBindings()
        #expect(!smart.isEmpty, "Smart bindings should not be empty")
    }
    
    @Test @MainActor
    func standardPresetBindings() {
        let standard = ConfigPreset.standard.bindings
        #expect(standard["f"] == ["Finder", "Freeform"])
        #expect(standard["p"] == ["Photos", "Passwords", "Preview"])
        #expect(standard["n"] == ["Notes"])
        #expect(standard["s"] == ["System Settings"])
        #expect(standard["c"]?.contains("Google Chrome") == true)
        #expect(standard["t"]?.contains("Telegram") == true)
        
        let defaultConfig = AppConfig.default
        #expect(defaultConfig.bindings["f"] == ["Finder", "Freeform"])
        #expect(defaultConfig.bindings["t"]?.contains("Telegram") == true)
        #expect(defaultConfig.bindings["p"] == ["Photos", "Passwords", "Preview"])
        #expect(defaultConfig.bindings["n"] == ["Notes"])
        #expect(defaultConfig.bindings["s"] == ["System Settings"])
        #expect(defaultConfig.hasCompletedOnboarding == false)
    }
    
    @Test @MainActor
    func chromeProfileParsing() {
        let helper = ChromeProfileHelper.shared
        helper.refreshProfiles()
        #expect(!helper.profiles.isEmpty, "Profiles list should never be empty")
    }
}
