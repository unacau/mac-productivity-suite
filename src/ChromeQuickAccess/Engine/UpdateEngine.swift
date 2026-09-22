import Foundation
import AppKit
import os

public enum InstallationSource: String, Sendable, Equatable {
    case homebrew
    case directDownload
}

public final class UpdateEngine: Sendable {
    private static let logger = Logger(subsystem: "com.almosteleven.xomsky", category: "update-engine")
    
    public static let directDmgDownloadUrl = URL(string: "https://github.com/unacau/mac-productivity-suite/releases/latest/download/Xomsky.dmg")!
    
    public static let homebrewUpgradeCommand = "brew upgrade xomsky"
    
    public static func detectInstallationSource(
        bundlePath: String = Bundle.main.bundlePath,
        fileExists: (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }
    ) -> InstallationSource {
        // 1. Running directly out of Caskroom
        if bundlePath.contains("Caskroom/xomsky") {
            return .homebrew
        }
        
        // 2. Common Homebrew Cask metadata locations on Apple Silicon and Intel Macs
        let commonCaskPaths = [
            "/opt/homebrew/Caskroom/xomsky",
            "/usr/local/Caskroom/xomsky"
        ]
        if commonCaskPaths.contains(where: { fileExists($0) }) {
            return .homebrew
        }
        
        return .directDownload
    }
    
    @discardableResult
    public static func runHomebrewUpgradeInTerminal(pasteboard: NSPasteboard = .general) -> Bool {
        // Copy command as a fallback for the user
        pasteboard.clearContents()
        pasteboard.setString(homebrewUpgradeCommand, forType: .string)
        
        // Execute command in Terminal.app
        let scriptSource = """
        tell application "Terminal"
            activate
            do script "\(homebrewUpgradeCommand)"
        end tell
        """
        
        if let appleScript = NSAppleScript(source: scriptSource) {
            var errorInfo: NSDictionary?
            appleScript.executeAndReturnError(&errorInfo)
            if let error = errorInfo {
                logger.error("Failed to execute AppleScript for Terminal: \(String(describing: error))")
                return false
            }
            logger.info("Successfully launched 'brew upgrade xomsky' in Terminal.")
            return true
        }
        
        logger.error("Could not instantiate NSAppleScript for Terminal launch.")
        return false
    }
}
