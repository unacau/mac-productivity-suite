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
        isHammerspoonRunning = runningApps.contains { app in
            app.bundleIdentifier == "org.hammerspoon.Hammerspoon" ||
            app.localizedName?.lowercased().contains("hammerspoon") == true
        }
        
        let isAppRunning = runningApps.contains { app in
            let bundle = app.bundleIdentifier ?? ""
            let name = app.localizedName ?? ""
            return bundle.lowercased().contains("karabiner") ||
                   bundle.lowercased().contains("pqrs") ||
                   name.lowercased().contains("karabiner")
        }
        
        // Immediately set from running apps
        self.isKarabinerRunning = isAppRunning
        
        // Also verify background daemons asynchronously
        Task.detached {
            let isDaemonRunning = self.checkKarabinerDaemon()
            await MainActor.run {
                if isDaemonRunning {
                    self.isKarabinerRunning = true
                }
            }
        }
    }
    
    nonisolated private func checkKarabinerDaemon() -> Bool {
        let task = Process()
        task.launchPath = "/usr/bin/pgrep"
        task.arguments = ["-if", "karabiner"]
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
            let _ = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
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
        let configDir = home.appendingPathComponent(".config/karabiner")
        let assetDir = configDir.appendingPathComponent("assets/complex_modifications")
        let assetFile = assetDir.appendingPathComponent("hyper-key-mapping.json")
        let configFile = configDir.appendingPathComponent("karabiner.json")
        
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
        
        do {
            try fileManager.createDirectory(at: assetDir, withIntermediateDirectories: true)
            try ruleJson.write(to: assetFile, atomically: true, encoding: .utf8)
            
            // Inject directly into karabiner.json active profile
            let ruleDict: [String: Any] = [
                "description": "Caps Lock to Hyper Key (Held) and Escape (Tapped)",
                "manipulators": [
                    [
                        "type": "basic",
                        "from": [
                            "key_code": "caps_lock",
                            "modifiers": ["optional": ["any"]]
                        ],
                        "to": [
                            [
                                "key_code": "left_shift",
                                "modifiers": ["left_command", "left_control", "left_option"]
                            ]
                        ],
                        "to_if_alone": [
                            ["key_code": "escape"]
                        ]
                    ]
                ]
            ]
            
            var config: [String: Any] = [:]
            if fileManager.fileExists(atPath: configFile.path),
               let data = try? Data(contentsOf: configFile),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                config = json
            }
            
            var profiles = config["profiles"] as? [[String: Any]] ?? [
                [
                    "name": "Default profile",
                    "selected": true,
                    "complex_modifications": ["rules": []]
                ]
            ]
            
            var modified = false
            for i in 0..<profiles.count {
                if profiles[i]["selected"] as? Bool == true || profiles.count == 1 {
                    var complexMod = profiles[i]["complex_modifications"] as? [String: Any] ?? ["rules": []]
                    var rules = complexMod["rules"] as? [[String: Any]] ?? []
                    
                    let alreadyExists = rules.contains { rule in
                        (rule["description"] as? String)?.contains("Hyper Key") == true
                    }
                    
                    if !alreadyExists {
                        rules.append(ruleDict)
                        complexMod["rules"] = rules
                        profiles[i]["complex_modifications"] = complexMod
                        modified = true
                    }
                }
            }
            
            if modified || !fileManager.fileExists(atPath: configFile.path) {
                config["profiles"] = profiles
                let outputData = try JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted, .sortedKeys])
                try outputData.write(to: configFile)
                print("Injected Hyper Key rule into karabiner.json successfully.")
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
        guard isHammerspoonRunning else { return }
        Task.detached {
            let script = "tell application \"Hammerspoon\" to execute lua code \"\(lua)\""
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&error)
            }
        }
    }
}
