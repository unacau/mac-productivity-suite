import Foundation
import AppKit

enum ProductivityMode: String, CaseIterable, Codable {
    case classic = "classic"
    case hyper = "hyper"
    
    var displayName: String {
        switch self {
        case .classic: return "Classic (Cmd + Option)"
        case .hyper: return "Hyper Key (Caps Lock)"
        }
    }
    
    var description: String {
        switch self {
        case .classic: return "Uses standard Command + Option with Hammerspoon only (no driver required)"
        case .hyper: return "Uses Caps Lock as Hyper Key via Karabiner-Elements"
        }
    }
    
    var keyCombinationHint: String {
        switch self {
        case .classic: return "⌥⌘ + Key"
        case .hyper: return "Caps Lock + Key"
        }
    }
}

struct AppConfig: Codable {
    var mode: ProductivityMode
    var autoReloadHammerspoon: Bool
    
    static var `default`: AppConfig {
        AppConfig(mode: .classic, autoReloadHammerspoon: true)
    }
}

@MainActor
final class ModeManager: ObservableObject {
    static let shared = ModeManager()
    
    @Published var currentMode: ProductivityMode = .classic
    @Published var isHammerspoonRunning: Bool = false
    @Published var isKarabinerRunning: Bool = false
    @Published var isHammerspoonInstalled: Bool = false
    @Published var isKarabinerInstalled: Bool = false
    @Published var isInstallingKarabiner: Bool = false
    @Published var statusMessage: String = ""
    
    private let fileManager = FileManager.default
    private var configURL: URL {
        let home = fileManager.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".hammerspoon/config.json")
    }
    
    private init() {
        loadConfig()
        checkEnvironment()
    }
    
    func checkEnvironment() {
        isHammerspoonInstalled = fileManager.fileExists(atPath: "/Applications/Hammerspoon.app")
        isKarabinerInstalled = fileManager.fileExists(atPath: "/Applications/Karabiner-Elements.app")
        
        let runningApps = NSWorkspace.shared.runningApplications
        isHammerspoonRunning = runningApps.contains { $0.bundleIdentifier == "org.hammerspoon.Hammerspoon" }
        isKarabinerRunning = runningApps.contains { 
            $0.bundleIdentifier?.contains("Karabiner") == true || $0.localizedName?.contains("Karabiner") == true 
        } || isKarabinerDaemonRunning()
    }
    
    private func isKarabinerDaemonRunning() -> Bool {
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["ax"]
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.contains("Karabiner-Core-Service") || output.contains("Karabiner-Console-User-Server")
            }
        } catch {}
        return false
    }
    
    func loadConfig() {
        if fileManager.fileExists(atPath: configURL.path) {
            do {
                let data = try Data(contentsOf: configURL)
                let config = try JSONDecoder().decode(AppConfig.self, from: data)
                self.currentMode = config.mode
            } catch {
                print("Failed to decode config: \(error)")
            }
        }
    }
    
    func saveConfig() {
        let config = AppConfig(mode: currentMode, autoReloadHammerspoon: true)
        do {
            let hsDir = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".hammerspoon")
            try fileManager.createDirectory(at: hsDir, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(config)
            try data.write(to: configURL)
        } catch {
            print("Failed to save config: \(error)")
        }
    }
    
    func switchMode(to newMode: ProductivityMode) {
        currentMode = newMode
        saveConfig()
        
        if newMode == .hyper {
            handleHyperModeRequirements()
        }
        
        applyToHammerspoon()
        checkEnvironment()
    }
    
    func handleHyperModeRequirements() {
        installKarabinerRuleIfNeeded()
        
        if !isKarabinerInstalled {
            statusMessage = "Karabiner-Elements is required for Hyper Key mode."
            promptInstallKarabiner()
        } else if !isKarabinerRunning {
            launchKarabiner()
        }
    }
    
    func promptInstallKarabiner() {
        let alert = NSAlert()
        alert.messageText = "Install Karabiner-Elements?"
        alert.informativeText = "Hyper Key mode requires Karabiner-Elements to map Caps Lock to Cmd+Opt+Ctrl+Shift. Would you like to install it now?"
        alert.addButton(withTitle: "Install Karabiner-Elements")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .informational
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            installKarabiner()
        } else {
            // Revert back to classic mode
            currentMode = .classic
            saveConfig()
            applyToHammerspoon()
        }
    }
    
    func installKarabiner() {
        isInstallingKarabiner = true
        statusMessage = "Installing Karabiner-Elements..."
        
        Task.detached {
            let script = """
            do shell script "curl -L -s -o /tmp/Karabiner.dmg https://github.com/pqrs-org/Karabiner-Elements/releases/download/v16.2.0/Karabiner-Elements-16.2.0.dmg && hdiutil attach /tmp/Karabiner.dmg -nobrowse -mountpoint /tmp/KarabinerMount && installer -pkg /tmp/KarabinerMount/*.pkg -target / && hdiutil detach /tmp/KarabinerMount -force && rm -f /tmp/Karabiner.dmg" with administrator privileges
            """
            
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&error)
            }
            
            await MainActor.run {
                self.isInstallingKarabiner = false
                self.checkEnvironment()
                if self.isKarabinerInstalled {
                    self.launchKarabiner()
                    self.statusMessage = "Karabiner-Elements installed successfully."
                } else {
                    self.statusMessage = "Failed to install Karabiner-Elements."
                }
            }
        }
    }
    
    func installKarabinerRuleIfNeeded() {
        let home = fileManager.homeDirectoryForCurrentUser
        let targetDir = home.appendingPathComponent(".config/karabiner/assets/complex_modifications")
        let targetFile = targetDir.appendingPathComponent("hyper-key-mapping.json")
        
        do {
            try fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)
            if !fileManager.fileExists(atPath: targetFile.path) {
                let ruleJson = """
                {
                  "title": "Hyper Key mapping for Mac Productivity Suite",
                  "rules": [
                    {
                      "description": "Caps Lock to Hyper Key (Held) and Escape (Tapped)",
                      "manipulators": [
                        {
                          "type": "basic",
                          "from": {
                            "key_code": "caps_lock",
                            "modifiers": { "optional": ["any"] }
                          },
                          "to": [
                            {
                              "key_code": "left_shift",
                              "modifiers": ["left_command", "left_control", "left_option"]
                            }
                          ],
                          "to_if_alone": [{ "key_code": "escape" }]
                        }
                      ]
                    }
                  ]
                }
                """
                try ruleJson.write(to: targetFile, atomically: true, encoding: .utf8)
            }
        } catch {
            print("Error writing Karabiner rule: \(error)")
        }
    }
    
    func launchKarabiner() {
        if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "org.pqrs.Karabiner-Elements") {
            NSWorkspace.shared.openApplication(at: appUrl, configuration: NSWorkspace.OpenConfiguration()) { _, _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.checkEnvironment()
                }
            }
        }
    }
    
    func launchHammerspoon() {
        if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "org.hammerspoon.Hammerspoon") {
            NSWorkspace.shared.openApplication(at: appUrl, configuration: NSWorkspace.OpenConfiguration()) { _, _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.checkEnvironment()
                    self.applyToHammerspoon()
                }
            }
        }
    }
    
    func applyToHammerspoon() {
        let luaCode = "if setProductivityMode then setProductivityMode('\(currentMode.rawValue)') else hs.reload() end"
        executeHammerspoonLua(luaCode)
    }
    
    func reloadHammerspoonConfig() {
        executeHammerspoonLua("hs.reload()")
    }
    
    private func executeHammerspoonLua(_ lua: String) {
        let script = "tell application \"Hammerspoon\" to execute lua code \"\(lua)\""
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            if error == nil { return }
        }
        
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "if which hs >/dev/null; then hs -c \"\(lua)\"; fi"]
        try? task.run()
    }
}
