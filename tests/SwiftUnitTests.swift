import Foundation
import Cocoa

// Standalone automated test harness for Mac Productivity Suite

@MainActor
func runAllTests() {
    print("==================================================")
    print(" Running Mac Productivity Suite Automated Test Suite")
    print("==================================================")
    
    testConfigSerialization()
    testHotkeyKeycodeMapping()
    testAppDiscoveryAndResolution()
    testChromeProfileParsing()
    testCopyOnSelectExclusions()
    
    print("==================================================")
    print(" ✅ ALL TESTS PASSED SUCCESSFULLY!                ")
    print("==================================================")
}

@MainActor
func testConfigSerialization() {
    print("[*] Testing AppConfig JSON Serialization & Deserialization...")
    var config = AppConfig.default
    config.mode = .ctrlOpt
    config.bindings["z"] = ["Zed", "Zoom"]
    config.copyOnSelect.dragThreshold = 18.0
    config.copyOnSelect.excludedBundleIDs.append("com.example.testapp")
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    guard let data = try? encoder.encode(config) else {
        fatalError("❌ Failed to encode AppConfig")
    }
    
    let decoder = JSONDecoder()
    guard let decoded = try? decoder.decode(AppConfig.self, from: data) else {
        fatalError("❌ Failed to decode AppConfig")
    }
    
    assert(decoded.mode == .ctrlOpt, "Mode mismatch")
    assert(decoded.bindings["z"] == ["Zed", "Zoom"], "Binding mismatch")
    assert(decoded.copyOnSelect.dragThreshold == 18.0, "Drag threshold mismatch")
    assert(decoded.copyOnSelect.excludedBundleIDs.contains("com.example.testapp"), "Exclusion mismatch")
    print("  ✅ AppConfig Serialization: PASS")
}

@MainActor
func testHotkeyKeycodeMapping() {
    print("[*] Testing KeyCodes and Character Mapping...")
    let testKeys = ["a", "c", "i", "s", "t", "1", "9", "space", "return", "escape", "-"]
    for k in testKeys {
        let code = KeyCodes.keyCode(for: k)
        assert(code != nil, "Failed to map key '\(k)' to Carbon virtual keycode")
    }
    
    assert(KeyCodes.keyCode(for: "a") == KeyCodes.kVK_ANSI_A, "Keycode mapping for 'a' failed")
    assert(KeyCodes.keyCode(for: "1") == KeyCodes.kVK_ANSI_1, "Keycode mapping for '1' failed")
    assert(KeyCodes.keyCode(for: "space") == KeyCodes.kVK_Space, "Keycode mapping for 'space' failed")
    print("  ✅ KeyCodes Mapping: PASS")
}

@MainActor
func testAppDiscoveryAndResolution() {
    print("[*] Testing AppDiscoveryService and Smart Bindings Generation...")
    let service = AppDiscoveryService.shared
    
    let finder = service.findApp(nameOrBundle: "Finder")
    assert(finder != nil, "Finder should always be discovered on macOS")
    
    let smart = service.generateSmartBindings()
    assert(!smart.isEmpty, "Smart bindings should not be empty")
    print("  ✅ App Discovery & Smart Generation: PASS (Generated \(smart.count) smart groups)")
}

@MainActor
func testChromeProfileParsing() {
    print("[*] Testing ChromeProfileHelper dynamic discovery...")
    let helper = ChromeProfileHelper.shared
    helper.refreshProfiles()
    assert(!helper.profiles.isEmpty, "Profiles list should never be empty (falls back to default profile)")
    print("  ✅ Browser Profiles Helper: PASS (Discovered \(helper.profiles.count) profiles)")
}

@MainActor
func testCopyOnSelectExclusions() {
    print("[*] Testing CopyOnSelect Exclusion Logic...")
    let exclusions = CopyOnSelectConfig.default.excludedBundleIDs
    assert(exclusions.contains("com.apple.Terminal"), "Terminal must be excluded by default")
    assert(exclusions.contains("com.mitchellh.ghostty"), "Ghostty must be excluded by default")
    assert(exclusions.contains("dev.warp.Warp-Stable"), "Warp must be excluded by default")
    print("  ✅ CopyOnSelect Exclusions: PASS")
}

@main
struct TestRunner {
    @MainActor
    static func main() {
        _ = NSApplication.shared
        runAllTests()
    }
}
