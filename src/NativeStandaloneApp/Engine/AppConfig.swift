import Foundation
import SwiftUI
import Combine

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

public struct AppConfig: Codable, Equatable {
    public static var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.4.2"
    }
    public static var currentBuildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "7"
    }
    
    public var version: String
    public var bindings: [String: [String]]
    public var autoDiscoverChromeProfiles: Bool
    public var hasCompletedOnboarding: Bool
    public var favoriteChromeProfiles: [String]
    
    public init(
        version: String = AppConfig.currentAppVersion,
        bindings: [String: [String]],
        autoDiscoverChromeProfiles: Bool = true,
        hasCompletedOnboarding: Bool = false,
        favoriteChromeProfiles: [String] = []
    ) {
        self.version = version
        self.bindings = bindings
        self.autoDiscoverChromeProfiles = autoDiscoverChromeProfiles
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.favoriteChromeProfiles = favoriteChromeProfiles
    }
    
    public static var `default`: AppConfig {
        AppConfig(
            version: currentAppVersion,
            bindings: [
                "f": ["Finder", "Freeform"],
                "t": ["Telegram", "iTerm2", "iTerm", "Terminal"],
                "p": ["Photos", "Passwords", "Preview"],
                "n": ["Notes"],
                "c": ["Google Chrome"],
                "s": ["System Settings"]
            ],
            autoDiscoverChromeProfiles: true,
            hasCompletedOnboarding: false,
            favoriteChromeProfiles: []
        )
    }
    
    // Custom decoding for backward compatibility and auto-version migration
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Automatically synchronize version with current app version
        self.version = Self.currentAppVersion
        let decodedBindings = try container.decodeIfPresent([String: [String]].self, forKey: .bindings) ?? Self.default.bindings
        self.bindings = decodedBindings
        self.autoDiscoverChromeProfiles = try container.decodeIfPresent(Bool.self, forKey: .autoDiscoverChromeProfiles) ?? true
        
        // If hasCompletedOnboarding is not explicitly true, but the user already has custom bindings configured, mark onboarding complete
        let explicitOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding)
        if let explicit = explicitOnboarding {
            self.hasCompletedOnboarding = explicit
        } else {
            // Existing user with pre-existing config: do not nag with onboarding setup
            self.hasCompletedOnboarding = !decodedBindings.isEmpty
        }
        
        self.favoriteChromeProfiles = try container.decodeIfPresent([String].self, forKey: .favoriteChromeProfiles) ?? []
    }
}

public enum ConfigPreset: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case developer = "Developer"
    case everyday = "Everyday Mac"
    case creative = "Creative & Media"
    case minimalist = "Minimalist"
    
    public var id: String { rawValue }
    
    public var description: String {
        switch self {
        case .standard: return "Standard preset (Finder/Freeform, Telegram/Terminal, Photos/Passwords/Preview, Notes, Chrome, Settings)"
        case .developer: return "Optimized for coding (Terminal, Editors, Chrome, Slack, Notes)"
        case .everyday: return "Standard macOS apps (Browser, Calendar, Music, Notes, Finder)"
        case .creative: return "Media & Design workflows (Figma, Photoshop, Photos, Music)"
        case .minimalist: return "Lightweight single-key shortcuts for core apps"
        }
    }
    
    public var bindings: [String: [String]] {
        switch self {
        case .standard:
            return [
                "f": ["Finder", "Freeform"],
                "t": ["Telegram", "iTerm2", "iTerm", "Terminal"],
                "p": ["Photos", "Passwords", "Preview"],
                "n": ["Notes"],
                "c": ["Google Chrome"],
                "s": ["System Settings"]
            ]
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
    
    public static var testOverrideDirectory: String?
    
    public var configURL: URL {
        if let testDir = AppConfigManager.testOverrideDirectory {
            return URL(fileURLWithPath: testDir).appendingPathComponent("config.json")
        }
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/mac-productivity-suite/config.json")
    }
    
    public var hammerspoonConfigURL: URL {
        if let testDir = AppConfigManager.testOverrideDirectory {
            return URL(fileURLWithPath: testDir).appendingPathComponent("hs_config.json")
        }
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
                    if let bindings = json["bindings"] as? [String: [String]] {
                        legacy.bindings = bindings
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
