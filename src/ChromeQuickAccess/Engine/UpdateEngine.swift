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
    
    public static let homebrewUpgradeCommand = "brew update && brew upgrade --cask xomsky"
    
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
    public static func runHomebrewUpgradeInTerminal(
        workspaceOpen: (URL) -> Bool = { NSWorkspace.shared.open($0) }
    ) -> Bool {
        // 1. Primary approach: Launch an executable .command script.
        // Opening a .command file executes directly in Terminal without requiring TCC AppleEvents permissions.
        let tempScriptUrl = FileManager.default.temporaryDirectory.appendingPathComponent("xomsky-upgrade.command")
        let scriptContent = """
        #!/bin/bash
        echo "=========================================="
        echo "       Upgrading Xomsky via Homebrew      "
        echo "=========================================="
        echo ""
        echo "==> Fetching latest tap recipes (brew update)..."
        brew update
        echo ""
        echo "==> Upgrading Xomsky cask..."
        if brew upgrade --cask xomsky; then
            echo ""
            echo "=========================================="
            echo "    Xomsky successfully upgraded!         "
            echo "    Restart Xomsky to apply changes.      "
            echo "=========================================="
        else
            echo ""
            echo "=========================================="
            echo "    Upgrade encountered an issue.         "
            echo "    Try running: brew reinstall --cask xomsky"
            echo "=========================================="
        fi
        echo ""
        read -n 1 -s -r -p "Press any key to close this terminal window..."
        echo ""
        """
        
        do {
            try scriptContent.write(to: tempScriptUrl, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tempScriptUrl.path)
            if workspaceOpen(tempScriptUrl) {
                logger.info("Successfully launched upgrade .command script in Terminal via LaunchServices.")
                return true
            }
        } catch {
            logger.error("Failed to write temporary .command script: \(error.localizedDescription)")
        }
        
        // 2. Secondary fallback: AppleScript (if .command launch is unavailable)
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
            logger.info("Successfully launched upgrade command via AppleScript.")
            return true
        }
        
        logger.error("Could not instantiate NSAppleScript for Terminal launch.")
        return false
    }
}
