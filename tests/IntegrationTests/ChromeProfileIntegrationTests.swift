import Foundation
import Testing
@testable import AppEngine
import Cocoa

final class MockProcessProvider: @unchecked Sendable, ProcessProvider {
    var commandsRun: [(String, [String])] = []
    
    func runCommand(launchPath: String, arguments: [String]) throws {
        commandsRun.append((launchPath, arguments))
    }
}

final class MockWorkspaceProvider: @unchecked Sendable, WorkspaceProvider {
    var frontmostApplicationName: String? = nil
    var runningApps: [RunningAppProvider] = []
    var openedURLs: [URL] = []
    var fallbackNames: [String] = []
    
    func openApplication(at url: URL, configuration: NSWorkspace.OpenConfiguration) {
        openedURLs.append(url)
    }
    
    func fallbackOpen(nameOrCandidate: String) {
        fallbackNames.append(nameOrCandidate)
    }
}

extension SerializedTests {
    
    
    @Test @MainActor
    func profileDiscoveryAndLaunch() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        AppConfigManager.testOverrideDirectory = tempDir.path
        defer { AppConfigManager.testOverrideDirectory = nil }
        
        let localStateDict: [String: Any] = [
            "profile": [
                "info_cache": [
                    "Default": ["name": "Personal"],
                    "Profile 1": ["name": "Work"]
                ]
            ]
        ]
        
        let data = try JSONSerialization.data(withJSONObject: localStateDict)
        let localStatePath = tempDir.appendingPathComponent("Local State")
        try data.write(to: localStatePath)
        
        let process = MockProcessProvider()
        let workspace = MockWorkspaceProvider()
        
        let helper = ChromeProfileHelper(workspace: workspace, process: process)
        
        #expect(helper.profiles.count == 2)
        #expect(helper.profiles.first?.dir == "Default")
        #expect(helper.profiles.last?.dir == "Profile 1")
        
        helper.focusProfile(index: 2) // Should focus "Profile 1"
        
        #expect(process.commandsRun.count == 1)
        let args = process.commandsRun[0].1
        #expect(args.contains("--profile-directory=Profile 1"))
    }
    
    @Test @MainActor
    func testAvatarResolutionWithDisabledGaiaFlag() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        AppConfigManager.testOverrideDirectory = tempDir.path
        defer { AppConfigManager.testOverrideDirectory = nil }
        
        let profileDir = tempDir.appendingPathComponent("Profile 5")
        try FileManager.default.createDirectory(at: profileDir, withIntermediateDirectories: true)
        
        // Create dummy PNG image in Profile 5
        let img = NSImage(size: NSSize(width: 32, height: 32))
        img.lockFocus()
        NSColor.red.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 32, height: 32)).fill()
        img.unlockFocus()
        if let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) {
            try png.write(to: profileDir.appendingPathComponent("Google Profile Picture.png"))
        }
        
        let localStateDict: [String: Any] = [
            "profile": [
                "info_cache": [
                    "Profile 5": [
                        "name": "Custom Profile",
                        "use_gaia_picture": 0,
                        "gaia_picture_file_name": "Google Profile Picture.png"
                    ]
                ]
            ]
        ]
        
        let data = try JSONSerialization.data(withJSONObject: localStateDict)
        let localStatePath = tempDir.appendingPathComponent("Local State")
        try data.write(to: localStatePath)
        
        let process = MockProcessProvider()
        let workspace = MockWorkspaceProvider()
        
        let helper = ChromeProfileHelper(workspace: workspace, process: process)
        
        #expect(helper.profiles.count == 1)
        #expect(helper.profiles.first?.dir == "Profile 5")
        #expect(helper.profiles.first?.avatarImage != nil)
        #expect(helper.profiles.first?.avatarImage?.size.width == 128)
    }
    
    @Test @MainActor
    func testProfileExpectedMenuTitleAndDisambiguation() throws {
        // 1. Name matches gaia_given_name -> expectedMenuTitle is simply name
        let p1 = DiscoveredChromeProfile(
            index: 1,
            dir: "Default",
            name: "Igor",
            email: "igor@gmail.com",
            gaiaName: "Igor Ekishev",
            gaiaGivenName: "Igor"
        )
        #expect(p1.expectedMenuTitle == "Igor")
        
        // 2. Custom profile name with shared GAIA first name -> expectedMenuTitle is "GaiaGivenName (ProfileName)"
        let p2 = DiscoveredChromeProfile(
            index: 2,
            dir: "Profile 2",
            name: "Al11",
            email: "igor@almosteleven.com",
            gaiaName: "Igor Ekishev",
            gaiaGivenName: "Igor"
        )
        #expect(p2.expectedMenuTitle == "Igor (Al11)")
        
        // 3. Another customized profile with shared GAIA first name
        let p3 = DiscoveredChromeProfile(
            index: 3,
            dir: "Profile 5",
            name: "GCP Free Trial",
            email: "igor729@gmail.com",
            gaiaName: "Igor Ekishev",
            gaiaGivenName: "Igor"
        )
        #expect(p3.expectedMenuTitle == "Igor (GCP Free Trial)")
        
        // 4. Distinct GAIA user
        let p4 = DiscoveredChromeProfile(
            index: 4,
            dir: "Profile 1",
            name: "Nastya",
            email: "nastya@gmail.com",
            gaiaName: "Nastya Muravyova",
            gaiaGivenName: "Nastya"
        )
        #expect(p4.expectedMenuTitle == "Nastya")
        
        // 5. Unauthenticated / local profile without GAIA info
        let p5 = DiscoveredChromeProfile(
            index: 5,
            dir: "Profile 3",
            name: "Dev Workspace"
        )
        #expect(p5.expectedMenuTitle == "Dev Workspace")
    }
    
    @Test @MainActor
    func testMultiProfileOrderingAndResolution() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        AppConfigManager.testOverrideDirectory = tempDir.path
        defer { AppConfigManager.testOverrideDirectory = nil }
        
        // Local State containing the exact setup causing the bug:
        // Default (Igor), Profile 1 (Nastya), Profile 2 (Al11), Profile 5 (GCP Free Trial)
        let localStateDict: [String: Any] = [
            "profile": [
                "info_cache": [
                    "Default": [
                        "name": "Igor",
                        "gaia_name": "Igor Ekishev",
                        "gaia_given_name": "Igor",
                        "user_name": "igorekishev92@gmail.com"
                    ],
                    "Profile 1": [
                        "name": "Nastya",
                        "gaia_name": "Nastya Muravyova",
                        "gaia_given_name": "Nastya",
                        "user_name": "nastya@gmail.com"
                    ],
                    "Profile 2": [
                        "name": "Al11",
                        "gaia_name": "Igor Ekishev",
                        "gaia_given_name": "Igor",
                        "user_name": "igor@almosteleven.com"
                    ],
                    "Profile 5": [
                        "name": "GCP Free Trial",
                        "gaia_name": "Igor Ekishev",
                        "gaia_given_name": "Igor",
                        "user_name": "igorekishev729@gmail.com"
                    ]
                ]
            ]
        ]
        
        let data = try JSONSerialization.data(withJSONObject: localStateDict)
        let localStatePath = tempDir.appendingPathComponent("Local State")
        try data.write(to: localStatePath)
        
        let process = MockProcessProvider()
        let workspace = MockWorkspaceProvider()
        let helper = ChromeProfileHelper(workspace: workspace, process: process)
        
        #expect(helper.profiles.count == 4)
        
        // Alphabetical sorting by expectedMenuTitle:
        // 1. "Igor" (Default)
        // 2. "Igor (Al11)" (Profile 2)
        // 3. "Igor (GCP Free Trial)" (Profile 5)
        // 4. "Nastya" (Profile 1)
        #expect(helper.profiles[0].dir == "Default")
        #expect(helper.profiles[0].index == 1)
        #expect(helper.profiles[0].expectedMenuTitle == "Igor")
        
        #expect(helper.profiles[1].dir == "Profile 2")
        #expect(helper.profiles[1].index == 2)
        #expect(helper.profiles[1].expectedMenuTitle == "Igor (Al11)")
        
        #expect(helper.profiles[2].dir == "Profile 5")
        #expect(helper.profiles[2].index == 3)
        #expect(helper.profiles[2].expectedMenuTitle == "Igor (GCP Free Trial)")
        
        #expect(helper.profiles[3].dir == "Profile 1")
        #expect(helper.profiles[3].index == 4)
        #expect(helper.profiles[3].expectedMenuTitle == "Nastya")
        
        // Test title matching helper
        let match1 = helper.profileMatchingMenuItemTitle("Igor", among: helper.profiles)
        #expect(match1?.dir == "Default")
        
        let match2 = helper.profileMatchingMenuItemTitle("Igor (Al11)", among: helper.profiles)
        #expect(match2?.dir == "Profile 2")
        
        let match3 = helper.profileMatchingMenuItemTitle("Igor (GCP Free Trial)", among: helper.profiles)
        #expect(match3?.dir == "Profile 5")
        
        let match4 = helper.profileMatchingMenuItemTitle("Nastya", among: helper.profiles)
        #expect(match4?.dir == "Profile 1")
        
        // Test focus by directory
        helper.focusProfile(dir: "Profile 1")
        #expect(process.commandsRun.count == 1)
        #expect(process.commandsRun.last?.1.contains("--profile-directory=Profile 1") == true)
        
        // Test focus by index: index 4 must focus Profile 1 (Nastya), NOT Profile 5
        helper.focusProfile(index: 4)
        #expect(process.commandsRun.count == 2)
        #expect(process.commandsRun.last?.1.contains("--profile-directory=Profile 1") == true)
        
        // Test focus by index: index 2 must focus Profile 2 (Al11)
        helper.focusProfile(index: 2)
        #expect(process.commandsRun.count == 3)
        #expect(process.commandsRun.last?.1.contains("--profile-directory=Profile 2") == true)
        
        // Test focus by index: index 3 must focus Profile 5 (GCP Free Trial)
        helper.focusProfile(index: 3)
        #expect(process.commandsRun.count == 4)
        #expect(process.commandsRun.last?.1.contains("--profile-directory=Profile 5") == true)
    }
}
