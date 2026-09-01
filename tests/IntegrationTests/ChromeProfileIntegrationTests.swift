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
}
