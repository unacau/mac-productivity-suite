import Foundation
import SwiftUI
import Combine

public enum ProductivityMode: String, CaseIterable, Codable {
    case classic = "classic"       // Standard ⌥⌘ (Cmd + Option)
    case hyper = "hyper"           // Caps Lock via Karabiner/EventTap
    case ctrlOpt = "ctrl_opt"     // ⌃⌥ (Control + Option)
    case cmdShift = "cmd_shift"   // ⌘⇧ (Command + Shift)
    
    public var displayName: String {
        switch self {
        case .classic: return "Classic (⌥⌘ Cmd + Option)"
        case .hyper: return "Hyper Key (Caps Lock)"
        case .ctrlOpt: return "Control + Option (⌃⌥)"
        case .cmdShift: return "Command + Shift (⌘⇧)"
        }
    }
    
    public var shortBadge: String {
        switch self {
        case .classic: return "⌥⌘"
        case .hyper: return "Caps Lock"
        case .ctrlOpt: return "⌃⌥"
        case .cmdShift: return "⌘⇧"
        }
    }
    
    public var carbonModifiers: UInt32 {
        switch self {
        case .classic:
            return KeyCodes.cmdOptModifiers
        case .hyper:
            return KeyCodes.hyperModifiers
        case .ctrlOpt:
            return KeyCodes.ctrlOptModifiers
        case .cmdShift:
            return KeyCodes.cmdShiftModifiers
        }
    }
}

public struct ChromeProfileConfig: Identifiable, Codable, Equatable {
    public var id: String { "\(dir)_\(index)" }
    public var index: Int
    public var dir: String
    public var name: String
    public var email: String?
    public var avatarPath: String?
    public var customName: String?
    
    public init(index: Int, dir: String, name: String, email: String? = nil, avatarPath: String? = nil, customName: String? = nil) {
        self.index = index
        self.dir = dir
        self.name = name
        self.email = email
        self.avatarPath = avatarPath
        self.customName = customName
    }
}

public struct CopyOnSelectConfig: Codable, Equatable {
    public var enabled: Bool
    public var dragThreshold: Double
    public var copyDelayMs: Int
    public var excludedBundleIDs: [String]
    
    public static var `default`: CopyOnSelectConfig {
        CopyOnSelectConfig(
            enabled: true,
            dragThreshold: 10.0,
            copyDelayMs: 150,
            excludedBundleIDs: [
                "com.apple.Terminal",
                "com.googlecode.iterm2",
                "com.mitchellh.ghostty",
                "dev.warp.Warp-Stable",
                "io.alacritty",
                "net.kovidgoyal.kitty",
                "com.apple.Console"
            ]
        )
    }
}

public struct ProductivityShortcutsConfig: Codable, Equatable {
    public var finderSplitEnabled: Bool
    public var quickNotesEnabled: Bool
    public var quickNotesDirectory: String
    
    public static var `default`: ProductivityShortcutsConfig {
        let defaultDir = (FileManager.default.homeDirectoryForCurrentUser.path as NSString).appendingPathComponent("Documents/Highlights")
        return ProductivityShortcutsConfig(
            finderSplitEnabled: true,
            quickNotesEnabled: true,
            quickNotesDirectory: defaultDir
        )
    }
}

public struct AppConfig: Codable, Equatable {
    public var version: String
    public var mode: ProductivityMode
    public var bindings: [String: [String]]
    public var chromeProfiles: [ChromeProfileConfig]
    public var autoDiscoverChromeProfiles: Bool
    public var copyOnSelect: CopyOnSelectConfig
    public var productivityShortcuts: ProductivityShortcutsConfig
    
    public static var `default`: AppConfig {
        AppConfig(
            version: "2.1.0",
            mode: .classic,
            bindings: [
                "i": ["Ghostty", "iTerm", "Terminal", "Warp", "Alacritty"],
                "b": ["Google Chrome", "Arc", "Safari", "Brave Browser", "Firefox"],
                "c": ["Google Chrome", "Calendar"],
                "e": ["Cursor", "Visual Studio Code", "Xcode", "Sublime Text", "IntelliJ IDEA"],
                "f": ["Finder", "Freeform"],
                "m": ["Activity Monitor", "Music", "Spotify"],
                "n": ["Notes", "Notion", "Obsidian", "Bear"],
                "p": ["Preview", "Photos", "Passwords"],
                "s": ["Spotify", "Apple Music", "SoundCloud", "System Settings"],
                "t": ["Slack", "Telegram", "Discord", "WhatsApp", "Messages"]
            ],
            chromeProfiles: [],
            autoDiscoverChromeProfiles: true,
            copyOnSelect: .default,
            productivityShortcuts: .default
        )
    }
}

public enum ConfigPreset: String, CaseIterable, Identifiable {
    case developer = "Developer"
    case everyday = "Everyday Mac"
    case creative = "Creative & Media"
    case minimalist = "Minimalist"
    
    public var id: String { rawValue }
    
    public var description: String {
        switch self {
        case .developer: return "Optimized for coding (Terminal, Editors, Chrome, Slack, Notes)"
        case .everyday: return "Standard macOS apps (Browser, Calendar, Music, Notes, Finder)"
        case .creative: return "Media & Design workflows (Figma, Photoshop, Photos, Music)"
        case .minimalist: return "Lightweight single-key shortcuts for core apps"
        }
    }
    
    public var bindings: [String: [String]] {
        switch self {
        case .developer:
            return [
                "i": ["Ghostty", "iTerm", "Terminal", "Warp", "Alacritty"],
                "c": ["Cursor", "Visual Studio Code", "Xcode", "Zed"],
                "b": ["Google Chrome", "Arc", "Safari", "Firefox"],
                "t": ["Slack", "Telegram", "Discord"],
                "n": ["Notes", "Obsidian", "Notion"],
                "f": ["Finder"],
                "m": ["Activity Monitor"],
                "s": ["Spotify", "Music", "System Settings"],
                "p": ["Preview", "Photos"]
            ]
        case .everyday:
            return [
                "b": ["Safari", "Google Chrome", "Arc"],
                "c": ["Calendar", "Google Chrome"],
                "f": ["Finder", "Freeform"],
                "i": ["Terminal", "iTerm"],
                "m": ["Music", "Spotify", "Messages"],
                "n": ["Notes", "Reminders"],
                "p": ["Photos", "Preview", "Passwords"],
                "s": ["System Settings", "Safari"],
                "t": ["Telegram", "Messages", "FaceTime"]
            ]
        case .creative:
            return [
                "d": ["Figma", "Sketch", "Adobe XD"],
                "p": ["Adobe Photoshop", "Pixelmator Pro", "Photos", "Preview"],
                "i": ["Adobe Illustrator", "Affinity Designer"],
                "b": ["Google Chrome", "Safari"],
                "m": ["Spotify", "Music", "YouTube Music"],
                "n": ["Notes", "Notion"],
                "f": ["Finder"],
                "s": ["System Settings"]
            ]
        case .minimalist:
            return [
                "t": ["Terminal"],
                "b": ["Safari", "Google Chrome"],
                "n": ["Notes"],
                "f": ["Finder"],
                "m": ["Music"]
            ]
        }
    }
}

@MainActor
public final class AppConfigManager: ObservableObject {
    public static let shared = AppConfigManager()
    
    @Published public var config: AppConfig
    
    public var configURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/mac-productivity-suite/config.json")
    }
    
    public var hammerspoonConfigURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".hammerspoon/config.json")
    }
    
    private init() {
        self.config = AppConfig.default
        self.load()
    }
    
    public func load() {
        let fileManager = FileManager.default
        var targetURL = configURL
        
        if !fileManager.fileExists(atPath: targetURL.path) && fileManager.fileExists(atPath: hammerspoonConfigURL.path) {
            targetURL = hammerspoonConfigURL
        }
        
        if fileManager.fileExists(atPath: targetURL.path) {
            do {
                let data = try Data(contentsOf: targetURL)
                let decoder = JSONDecoder()
                if let decoded = try? decoder.decode(AppConfig.self, from: data) {
                    self.config = decoded
                    AppLogger.getLogger(category: .config).info("Loaded configuration version \(decoded.version, privacy: .public)")
                    return
                } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // Legacy migration
                    var legacy = AppConfig.default
                    if let modeStr = json["mode"] as? String, let mode = ProductivityMode(rawValue: modeStr) {
                        legacy.mode = mode
                    }
                    self.config = legacy
                    self.save()
                    AppLogger.getLogger(category: .config).info("Migrated legacy configuration")
                    return
                }
            } catch {
                AppLogger.getLogger(category: .config).error("Error reading config: \(error.localizedDescription, privacy: .public)")
            }
        }
        
        // No existing config: initialize defaults and save
        self.config = AppConfig.default
        self.save()
    }
    
    public func save() {
        let fileManager = FileManager.default
        let configDir = configURL.deletingLastPathComponent()
        let hsDir = hammerspoonConfigURL.deletingLastPathComponent()
        
        do {
            try fileManager.createDirectory(at: configDir, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: hsDir, withIntermediateDirectories: true)
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            
            try data.write(to: configURL, options: .atomic)
            try data.write(to: hammerspoonConfigURL, options: .atomic)
            
            AppLogger.getLogger(category: .config).info("Saved config successfully to \(self.configURL.path, privacy: .public)")
            
            // Post notification for live reloading
            NotificationCenter.default.post(name: NSNotification.Name("AppConfigDidChangeNotification"), object: nil)
        } catch {
            AppLogger.getLogger(category: .config).error("Error saving config: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    public func applyPreset(_ preset: ConfigPreset) {
        config.bindings = preset.bindings
        save()
    }
    
    public func resetToDefaults() {
        config = AppConfig.default
        save()
    }
    
    public func setMode(_ mode: ProductivityMode) {
        config.mode = mode
        save()
    }
    
    public func updateBinding(key: String, apps: [String]) {
        let lowerKey = key.lowercased()
        if apps.isEmpty {
            config.bindings.removeValue(forKey: lowerKey)
        } else {
            config.bindings[lowerKey] = apps
        }
        save()
    }
    
    public func removeBinding(key: String) {
        config.bindings.removeValue(forKey: key.lowercased())
        save()
    }
    
    public func exportConfig(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: url)
    }
    
    public func importConfig(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let imported = try decoder.decode(AppConfig.self, from: data)
        self.config = imported
        self.save()
    }
}
