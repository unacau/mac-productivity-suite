import Foundation
import Cocoa
import Testing
@testable import AppEngine
// We define our tests in a struct/class for the Testing framework
struct ProductivitySuiteTests {
    
    @Test @MainActor
    func configSerialization() throws {
        var config = AppConfig.default
        config.mode = .ctrlOpt
        config.bindings["z"] = ["Zed", "Zoom"]
        config.copyOnSelect.dragThreshold = 18.0
        config.copyOnSelect.excludedBundleIDs.append("com.example.testapp")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AppConfig.self, from: data)
        
        #expect(decoded.mode == .ctrlOpt)
        #expect(decoded.bindings["z"] == ["Zed", "Zoom"])
        #expect(decoded.copyOnSelect.dragThreshold == 18.0)
        #expect(decoded.copyOnSelect.excludedBundleIDs.contains("com.example.testapp"))
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
    func chromeProfileParsing() {
        let helper = ChromeProfileHelper.shared
        helper.refreshProfiles()
        #expect(!helper.profiles.isEmpty, "Profiles list should never be empty")
    }
    
    @Test @MainActor
    func copyOnSelectExclusions() {
        let exclusions = CopyOnSelectConfig.default.excludedBundleIDs
        #expect(exclusions.contains("com.apple.Terminal"))
        #expect(exclusions.contains("com.mitchellh.ghostty"))
        #expect(exclusions.contains("dev.warp.Warp-Stable"))
    }
}

