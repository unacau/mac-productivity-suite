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

struct ChromeProfileIntegrationTests {
    
    @Test @MainActor
    func profileDiscoveryAndLaunch() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        setenv("MPS_TEST_CONFIG_DIR", tempDir.path, 1)
        defer { unsetenv("MPS_TEST_CONFIG_DIR") }
        
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
        
        setenv("MPS_TEST_CONFIG_DIR", tempDir.path, 1)
        defer { unsetenv("MPS_TEST_CONFIG_DIR") }
        
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
}
