import Foundation
import Cocoa

public struct DiscoveredApp: Identifiable, Hashable, Sendable {
    public let id: String // bundleID or path
    public let name: String
    public let bundleID: String
    public let path: String
    public let isRunning: Bool
    
    public init(name: String, bundleID: String, path: String, isRunning: Bool = false) {
        self.id = bundleID.isEmpty ? path : bundleID
        self.name = name
        self.bundleID = bundleID
        self.path = path
        self.isRunning = isRunning
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: DiscoveredApp, rhs: DiscoveredApp) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
public final class AppDiscoveryService: ObservableObject {
    public static let shared = AppDiscoveryService()
    
    @Published public var installedApps: [DiscoveredApp] = []
    @Published public var isScanning: Bool = false
    
    private var appCache: [String: DiscoveredApp] = [:]
    private var iconCache: [String: NSImage] = [:]
    
    private init() {
        refreshInstalledApps()
    }
    
    public func refreshInstalledApps() {
        isScanning = true
        
        Task.detached(priority: .userInitiated) {
            let apps = Self.performScan()
            
            await MainActor.run {
                self.installedApps = apps
                self.appCache.removeAll()
                for app in apps {
                    self.appCache[app.name.lowercased()] = app
                    if !app.bundleID.isEmpty {
                        self.appCache[app.bundleID.lowercased()] = app
                    }
                }
                self.isScanning = false
                AppLogger.getLogger(category: .discovery).info("Discovered \(apps.count) installed applications on Mac.")
            }
        }
    }
    
    nonisolated private static func performScan() -> [DiscoveredApp] {
        var discovered: [DiscoveredApp] = []
        var seenPaths = Set<String>()
        var seenBundleIDs = Set<String>()
        
        let searchDirs = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities",
            "\(NSHomeDirectory())/Applications",
            "\(NSHomeDirectory())/Applications/Chrome Apps.localized",
            "/Applications/Setapp"
        ]
        
        for dir in searchDirs {
            let dirURL = URL(fileURLWithPath: dir)
            guard let contents = try? FileManager.default.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else {
                continue
            }
            
            for fileURL in contents {
                let path = fileURL.path
                guard path.hasSuffix(".app"), !seenPaths.contains(path) else { continue }
                seenPaths.insert(path)
                
                let bundle = Bundle(url: fileURL)
                let name = (bundle?.infoDictionary?["CFBundleDisplayName"] as? String)
                    ?? (bundle?.infoDictionary?["CFBundleName"] as? String)
                    ?? fileURL.deletingPathExtension().lastPathComponent
                let bundleID = bundle?.bundleIdentifier ?? ""
                
                if !bundleID.isEmpty && seenBundleIDs.contains(bundleID) {
                    continue
                }
                if !bundleID.isEmpty {
                    seenBundleIDs.insert(bundleID)
                }
                
                let app = DiscoveredApp(
                    name: name,
                    bundleID: bundleID,
                    path: path,
                    isRunning: false
                )
                discovered.append(app)
            }
        }
        
        discovered.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        return discovered
    }
    
    public func search(query: String) -> [DiscoveredApp] {
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            return installedApps
        }
        let q = query.lowercased()
        return installedApps.filter { app in
            app.name.lowercased().contains(q) ||
            app.bundleID.lowercased().contains(q)
        }
    }
    
    public func findApp(nameOrBundle: String) -> DiscoveredApp? {
        let key = nameOrBundle.lowercased()
        if let cached = appCache[key] {
            return cached
        }
        
        // Search in running applications
        let running = NSWorkspace.shared.runningApplications
        if let r = running.first(where: {
            $0.localizedName?.lowercased() == key ||
            $0.bundleIdentifier?.lowercased() == key ||
            $0.bundleIdentifier?.lowercased().contains(key) == true
        }) {
            let name = r.localizedName ?? nameOrBundle
            let bundleID = r.bundleIdentifier ?? ""
            return DiscoveredApp(name: name, bundleID: bundleID, path: r.bundleURL?.path ?? "", isRunning: true)
        }
        
        // Search installed apps by substring match
        if let found = installedApps.first(where: {
            $0.name.lowercased() == key ||
            $0.name.lowercased().contains(key) ||
            $0.bundleID.lowercased() == key
        }) {
            return found
        }
        
        return nil
    }
    
    public func iconForApp(nameOrBundle: String) -> NSImage {
        let key = nameOrBundle.lowercased()
        if let cached = iconCache[key] {
            return cached
        }
        
        if let app = findApp(nameOrBundle: nameOrBundle) {
            let icon: NSImage
            if !app.path.isEmpty && FileManager.default.fileExists(atPath: app.path) {
                icon = NSWorkspace.shared.icon(forFile: app.path)
            } else if let running = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == app.bundleID }), let img = running.icon {
                icon = img
            } else {
                icon = NSWorkspace.shared.icon(forFile: "/System/Library/CoreServices/Finder.app")
            }
            icon.size = NSSize(width: 64, height: 64)
            iconCache[key] = icon
            return icon
        }
        
        let generic = NSWorkspace.shared.icon(forFile: "/System/Library/CoreServices/Finder.app")
        generic.size = NSSize(width: 64, height: 64)
        iconCache[key] = generic
        return generic
    }
    
    public func generateSmartBindings() -> [String: [String]] {
        var bindings: [String: [String]] = [:]
        
        func resolveCandidates(_ candidates: [String]) -> [String] {
            var found: [String] = []
            for candidate in candidates {
                if let app = findApp(nameOrBundle: candidate) {
                    if !found.contains(app.name) {
                        found.append(app.name)
                    }
                }
            }
            return found.isEmpty ? [candidates.first ?? ""] : found
        }
        
        // 1. Terminal / Shell (i)
        let terminals = resolveCandidates(["Ghostty", "iTerm", "iTerm2", "Warp", "Alacritty", "kitty", "Terminal"])
        if !terminals.isEmpty { bindings["i"] = terminals }
        
        // 2. Code / IDE / Editor (c)
        let editors = resolveCandidates(["Cursor", "Visual Studio Code", "Xcode", "Zed", "Sublime Text", "IntelliJ IDEA", "PyCharm", "WebStorm", "Nova"])
        if !editors.isEmpty { bindings["c"] = editors }
        
        // 3. Web Browsers (b)
        let browsers = resolveCandidates(["Google Chrome", "Arc", "Safari", "Brave Browser", "Firefox", "Microsoft Edge", "Orion"])
        if !browsers.isEmpty { bindings["b"] = browsers }
        
        // 4. Communication & Chat (t)
        let chats = resolveCandidates(["Slack", "Telegram", "Discord", "WhatsApp", "Messages", "Microsoft Teams", "Zoom"])
        if !chats.isEmpty { bindings["t"] = chats }
        
        // 5. Notes & Knowledge (n)
        let notes = resolveCandidates(["Notes", "Notion", "Obsidian", "Bear", "Craft", "Logseq", "Reminders"])
        if !notes.isEmpty { bindings["n"] = notes }
        
        // 6. Audio / Music (s)
        let music = resolveCandidates(["Spotify", "Music", "YouTube Music", "SoundCloud", "Podcasts"])
        if !music.isEmpty { bindings["s"] = music }
        
        // 7. System / Files (f)
        let files = resolveCandidates(["Finder", "Freeform"])
        if !files.isEmpty { bindings["f"] = files }
        
        // 8. Monitor / Utility (m)
        let monitor = resolveCandidates(["Activity Monitor", "Stats", "CleanMyMac X"])
        if !monitor.isEmpty { bindings["m"] = monitor }
        
        // 9. Documents / Preview (p)
        let preview = resolveCandidates(["Preview", "Photos", "Passwords", "Books"])
        if !preview.isEmpty { bindings["p"] = preview }
        
        return bindings
    }
}
