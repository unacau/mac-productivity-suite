import Foundation
import Testing
@testable import AppEngine
import Cocoa

extension SerializedTests {
    
    // MARK: - Edge Case 1: Identical Display Names With Distinct Emails (Disambiguation)
    @Test @MainActor
    func testEdgeCase1_IdenticalDisplayNamesWithDistinctEmails() throws {
        let p1 = DiscoveredChromeProfile(
            index: 1,
            dir: "Profile 1",
            name: "Work",
            email: "alice@company-a.com"
        )
        let p2 = DiscoveredChromeProfile(
            index: 2,
            dir: "Profile 2",
            name: "Work",
            email: "bob@company-b.com"
        )
        
        let profiles = [p1, p2]
        let helper = ChromeProfileHelper(workspace: MockWorkspaceProvider(), process: MockProcessProvider())
        
        // When Chrome disambiguates by appending the email
        let match1 = helper.profileMatchingMenuItemTitle("Work (alice@company-a.com)", among: profiles)
        let match2 = helper.profileMatchingMenuItemTitle("Work (bob@company-b.com)", among: profiles)
        
        #expect(match1?.dir == "Profile 1", "Must match Alice's profile directory")
        #expect(match2?.dir == "Profile 2", "Must match Bob's profile directory")
        #expect(match1?.dir != match2?.dir, "Must never resolve both to the same profile")
    }
    
    // MARK: - Edge Case 2: Identical GAIA Given Names with Custom Profile Names
    @Test @MainActor
    func testEdgeCase2_IdenticalGaiaGivenNamesWithCustomNames() throws {
        let pDefault = DiscoveredChromeProfile(
            index: 1,
            dir: "Default",
            name: "Igor",
            email: "igor@gmail.com",
            gaiaName: "Igor Ekishev",
            gaiaGivenName: "Igor"
        )
        let pEnterprise = DiscoveredChromeProfile(
            index: 2,
            dir: "Profile 2",
            name: "Enterprise",
            email: "igor@enterprise.com",
            gaiaName: "Igor Ekishev",
            gaiaGivenName: "Igor"
        )
        
        #expect(pDefault.expectedMenuTitle == "Igor")
        #expect(pEnterprise.expectedMenuTitle == "Igor (Enterprise)")
        
        let helper = ChromeProfileHelper(workspace: MockWorkspaceProvider(), process: MockProcessProvider())
        let profiles = [pDefault, pEnterprise]
        
        let match1 = helper.profileMatchingMenuItemTitle("Igor", among: profiles)
        let match2 = helper.profileMatchingMenuItemTitle("Igor (Enterprise)", among: profiles)
        
        #expect(match1?.dir == "Default")
        #expect(match2?.dir == "Profile 2")
    }
    
    // MARK: - Edge Case 3: Whitespace, Emojis, and Unicode Canonical Equivalence
    @Test @MainActor
    func testEdgeCase3_WhitespaceAndUnicodeCanonicalEquivalence() throws {
        // Test whitespace padding
        let pWhitespace = DiscoveredChromeProfile(
            index: 1,
            dir: "Profile 1",
            name: "   Staging Server   "
        )
        #expect(pWhitespace.effectiveName == "Staging Server")
        
        // Test Emoji and special characters
        let pEmoji = DiscoveredChromeProfile(
            index: 2,
            dir: "Profile 2",
            name: "Dev 🚀 [2026]"
        )
        #expect(pEmoji.effectiveName == "Dev 🚀 [2026]")
        
        // Test Unicode decomposed (NFD) vs precomposed (NFC) equivalence: "café"
        // 'e' + combining acute (U+0301) vs precomposed 'é' (U+00E9)
        let nfdName = "cafe\u{0301}"
        let nfcTitle = "caf\u{00E9}"
        
        let pAccent = DiscoveredChromeProfile(
            index: 3,
            dir: "Profile 3",
            name: nfdName
        )
        
        let helper = ChromeProfileHelper(workspace: MockWorkspaceProvider(), process: MockProcessProvider())
        let match = helper.profileMatchingMenuItemTitle(nfcTitle, among: [pAccent])
        #expect(match?.dir == "Profile 3", "Unicode canonical equivalence must resolve regardless of normalization form")
    }
    
    // MARK: - Edge Case 4: Ghost / Deleted Profile Graceful Fallback
    @Test @MainActor
    func testEdgeCase4_DeletedProfileGracefulFallback() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        AppConfigManager.testOverrideDirectory = tempDir.path
        defer { AppConfigManager.testOverrideDirectory = nil }
        
        let localStateDict: [String: Any] = [
            "profile": [
                "info_cache": [
                    "Default": ["name": "Personal"]
                ]
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: localStateDict)
        try data.write(to: tempDir.appendingPathComponent("Local State"))
        
        let process = MockProcessProvider()
        let workspace = MockWorkspaceProvider()
        let helper = ChromeProfileHelper(workspace: workspace, process: process)
        
        // Attempting to focus a deleted profile "Profile 99" must not crash or throw
        helper.focusProfile(dir: "Profile 99")
        
        // Should gracefully attempt to launch the requested profile directory via CLI
        #expect(process.commandsRun.count == 1)
        #expect(process.commandsRun.first?.1.contains("--profile-directory=Profile 99") == true)
    }
    
    // MARK: - Edge Case 5: Cold Start Argument Synthesis with Spaces in Directory
    @Test @MainActor
    func testEdgeCase5_ColdStartArgumentSynthesis() throws {
        let process = MockProcessProvider()
        let workspace = MockWorkspaceProvider()
        let helper = ChromeProfileHelper(workspace: workspace, process: process)
        
        helper.focusProfile(dir: "Custom Profile With Spaces")
        
        #expect(process.commandsRun.count == 1)
        let args = process.commandsRun[0].1
        #expect(args.contains("-b"))
        #expect(args.contains("--args"))
        #expect(args.contains("--profile-directory=Custom Profile With Spaces"))
    }
    
    // MARK: - Edge Case 6: Corrupted or Empty Local State JSON
    @Test @MainActor
    func testEdgeCase6_CorruptedOrEmptyLocalStateJson() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        AppConfigManager.testOverrideDirectory = tempDir.path
        defer { AppConfigManager.testOverrideDirectory = nil }
        
        // Write completely malformed JSON
        let malformedData = "{ this is not valid json! }".data(using: .utf8)!
        try malformedData.write(to: tempDir.appendingPathComponent("Local State"))
        
        let helper = ChromeProfileHelper(workspace: MockWorkspaceProvider(), process: MockProcessProvider())
        
        // Must recover safely and provide a fallback default profile
        #expect(helper.profiles.count == 1)
        #expect(helper.profiles.first?.dir == "Default")
        #expect(helper.profiles.first?.name == "Default Profile")
    }
    
    // MARK: - Edge Case 7: Effective Name Fallback Hierarchy When Name is Blank
    @Test @MainActor
    func testEdgeCase7_EffectiveNameFallbackHierarchy() throws {
        // Profile with blank name but valid gaia_name
        let p1 = DiscoveredChromeProfile(
            index: 1,
            dir: "Profile 1",
            name: "",
            gaiaName: "Igor Corporate"
        )
        #expect(p1.effectiveName == "Igor Corporate")
        
        // Profile with blank name and gaia, but valid user_name / email
        let p2 = DiscoveredChromeProfile(
            index: 2,
            dir: "Profile 2",
            name: "   ",
            email: "support@almosteleven.com"
        )
        #expect(p2.effectiveName == "support@almosteleven.com")
        
        // Profile with absolutely no names at all
        let p3 = DiscoveredChromeProfile(
            index: 3,
            dir: "Profile 3",
            name: ""
        )
        #expect(p3.effectiveName == "Profile 3")
        
        let pDefault = DiscoveredChromeProfile(
            index: 4,
            dir: "Default",
            name: ""
        )
        #expect(pDefault.effectiveName == "Personal")
    }
    
    // MARK: - Edge Case 8: Incognito or Guest Window Detection
    @Test @MainActor
    func testEdgeCase8_IncognitoOrGuestWindowNoCheckmark() throws {
        let helper = ChromeProfileHelper(workspace: MockWorkspaceProvider(), process: MockProcessProvider())
        
        // When browser is not running or no checkmark is present, active profile returns nil cleanly
        let activeDir = helper.detectActiveProfileDir(bundleID: "com.google.Chrome")
        let activeIdx = helper.detectActiveProfileIndex(bundleID: "com.google.Chrome")
        
        #expect(activeDir == nil)
        #expect(activeIdx == nil)
    }
    
    // MARK: - Edge Case 9: Sequential HUD Index Assignment for Custom Bindings
    @Test @MainActor
    func testEdgeCase9_SequentialHUDIndexAssignmentForCustomBindings() throws {
        let workspace = MockWorkspaceProvider()
        let process = MockProcessProvider()
        let hotkeys = MockHotkeyProvider()
        let chromeHelper = ChromeProfileHelper(workspace: workspace, process: process)
        let engine = AppSwitcherEngine(workspace: workspace, hotkeys: hotkeys, chromeHelper: chromeHelper)
        
        let customApps = [
            "chrome-profile:Profile 5",
            "chrome-profile:Default",
            "chrome-profile:Profile 2"
        ]
        
        let items = engine.buildSwitcherItems(for: customApps)
        
        #expect(items.count == 3)
        #expect(items[0].profileDir == "Profile 5")
        #expect(items[0].profileIndex == 1, "First card must have profileIndex 1")
        
        #expect(items[1].profileDir == "Default")
        #expect(items[1].profileIndex == 2, "Second card must have profileIndex 2")
        
        #expect(items[2].profileDir == "Profile 2")
        #expect(items[2].profileIndex == 3, "Third card must have profileIndex 3")
    }
    
    // MARK: - Edge Case 10: Closed-HUD Direct Hotkey Prioritizes Config Order
    @Test @MainActor
    func testEdgeCase10_DirectClosedHUDHotkeyPrioritizesConfigOrder() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        AppConfigManager.testOverrideDirectory = tempDir.path
        defer { AppConfigManager.testOverrideDirectory = nil }
        
        // Configure custom bindings where key 'c' defines Profile 5 first, then Default
        var config = AppConfig.default
        config.bindings["c"] = [
            "chrome-profile:Profile 5",
            "chrome-profile:Default"
        ]
        AppConfigManager.shared.config = config
        AppConfigManager.shared.save()
        
        let workspace = MockWorkspaceProvider()
        let process = MockProcessProvider()
        let hotkeys = MockHotkeyProvider()
        let chromeHelper = ChromeProfileHelper(workspace: workspace, process: process)
        let engine = AppSwitcherEngine(workspace: workspace, hotkeys: hotkeys, chromeHelper: chromeHelper)
        
        // Simulating direct Hyper + 1 when HUD is closed
        engine.handleNumberPress(profileIndex: 1)
        
        // Must target Profile 5 (the first explicitly configured profile)
        #expect(process.commandsRun.count == 1)
        #expect(process.commandsRun.first?.1.contains("--profile-directory=Profile 5") == true)
        
        // Simulating direct Hyper + 2 when HUD is closed
        engine.handleNumberPress(profileIndex: 2)
        #expect(process.commandsRun.count == 2)
        #expect(process.commandsRun.last?.1.contains("--profile-directory=Default") == true)
    }
    
    @Test @MainActor
    func testEdgeCase11_IdenticalExpectedTitlesTierShadowing() async throws {
        // Simulates the exact bug where renaming a profile causes expectedMenuTitle to match another profile,
        // and Chrome appends the email to disambiguate. If Tiers are not ordered correctly, the exact name
        // match (Tier 1 previously) shadows the email-disambiguated match (Tier 1.5 previously).
        
        let p1 = DiscoveredChromeProfile(index: 1, dir: "Default", name: "Igor", email: "igorekishev92@gmail.com", gaiaName: "Igor Ekishev", gaiaGivenName: "Igor")
        let p2 = DiscoveredChromeProfile(index: 2, dir: "Profile 2", name: "Igor", email: "igor@almosteleven.com", gaiaName: "Igor Ekishev", gaiaGivenName: "Igor")
        
        // expectedMenuTitle for BOTH is "Igor".
        #expect(p1.expectedMenuTitle == "Igor")
        #expect(p2.expectedMenuTitle == "Igor")
        
        let helper = ChromeProfileHelper(workspace: MockWorkspaceProvider(), process: MockProcessProvider())
        
        // Prior to the fix, passing "Igor (igor@almosteleven.com)" would wrongly match p1 
        // because Tier 1 blindly matched "Igor".
        
        let matchedP1 = helper.profileMatchingMenuItemTitle("Igor", among: [p1, p2])
        #expect(matchedP1?.dir == "Default")
        
        let matchedP2 = helper.profileMatchingMenuItemTitle("Igor (igor@almosteleven.com)", among: [p1, p2])
        #expect(matchedP2?.dir == "Profile 2")
    }
}
