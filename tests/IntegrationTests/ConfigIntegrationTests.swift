import Foundation
import Testing
@testable import AppEngine

extension SerializedTests {
    
    
    @Test @MainActor
    func legacyMigration() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        // Set env variable
        AppConfigManager.testOverrideDirectory = tempDir.path
        defer { AppConfigManager.testOverrideDirectory = nil }
        
        // Write legacy config
        let legacyJSON = """
        {
            "bindings": { "x": ["Xcode"] }
        }
        """
        
        let configPath = tempDir.appendingPathComponent("config.json")
        try legacyJSON.write(to: configPath, atomically: true, encoding: .utf8)
        
        let manager = AppConfigManager.shared
        manager.load()
        
        #expect(manager.config.bindings["x"] == ["Xcode"])
        #expect(manager.config.version == AppConfig.default.version) // Should be upgraded
    }
}
