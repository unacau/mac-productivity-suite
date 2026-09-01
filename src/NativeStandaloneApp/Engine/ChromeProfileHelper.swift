import Cocoa

public struct DiscoveredChromeProfile: Identifiable, Equatable {
    public var id: String { dir }
    public let index: Int
    public let dir: String
    public let name: String
    public let email: String?
    public let avatarImage: NSImage?
    
    public init(index: Int, dir: String, name: String, email: String? = nil, avatarImage: NSImage? = nil) {
        self.index = index
        self.dir = dir
        self.name = name
        self.email = email
        self.avatarImage = avatarImage
    }
}

@MainActor
public final class ChromeProfileHelper: ObservableObject {
    public static var shared = ChromeProfileHelper(
        workspace: SystemWorkspaceProvider(),
        process: SystemProcessProvider()
    )
    
    @Published public var profiles: [DiscoveredChromeProfile] = []
    @Published public var isChromeInstalled: Bool = false
    @Published public var browserBundleID: String = "com.google.Chrome"
    
    private var cachedIcons: [String: NSImage] = [:]
    
    public let workspace: WorkspaceProvider
    public let process: ProcessProvider
    
    public init(workspace: WorkspaceProvider, process: ProcessProvider) {
        self.workspace = workspace
        self.process = process
        refreshProfiles()
    }
    
    public func refreshProfiles() {
        let fileManager = FileManager.default
        let chromeAppPath = "/Applications/Google Chrome.app"
        self.isChromeInstalled = fileManager.fileExists(atPath: chromeAppPath)
        
        let localStatePaths: [String] = {
            if let testDir = ProcessInfo.processInfo.environment["MPS_TEST_CONFIG_DIR"] {
                return ["\(testDir)/Local State"]
            }
            return [
                "\(NSHomeDirectory())/Library/Application Support/Google/Chrome/Local State",
                "\(NSHomeDirectory())/Library/Application Support/BraveSoftware/Brave-Browser/Local State",
                "\(NSHomeDirectory())/Library/Application Support/Microsoft Edge/Local State",
                "\(NSHomeDirectory())/Library/Application Support/Chromium/Local State"
            ]
        }()
        
        var foundProfiles: [DiscoveredChromeProfile] = []
        var discoveredBundleID = "com.google.Chrome"
        
        for path in localStatePaths {
            guard fileManager.fileExists(atPath: path),
                  let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let profileObj = json["profile"] as? [String: Any],
                  let infoCache = profileObj["info_cache"] as? [String: [String: Any]] else {
                continue
            }
            
            let baseDir = (path as NSString).deletingLastPathComponent
            if path.contains("Brave-Browser") { discoveredBundleID = "com.brave.Browser" }
            else if path.contains("Microsoft Edge") { discoveredBundleID = "com.microsoft.edgemac" }
            else if path.contains("Chromium") { discoveredBundleID = "org.chromium.Chromium" }
            else { discoveredBundleID = "com.google.Chrome" }
            
            // Sort profile directory keys: "Default" first, then "Profile 1", "Profile 2", etc.
            let sortedKeys = infoCache.keys.sorted { k1, k2 in
                if k1 == "Default" { return true }
                if k2 == "Default" { return false }
                return k1.localizedStandardCompare(k2) == .orderedAscending
            }
            
            var index = 1
            for dirKey in sortedKeys {
                guard let info = infoCache[dirKey] else { continue }
                
                let name = (info["name"] as? String)
                    ?? (info["gaia_name"] as? String)
                    ?? (info["user_name"] as? String)
                    ?? (dirKey == "Default" ? "Personal" : dirKey)
                
                let email = (info["user_name"] as? String) ?? (info["email"] as? String)
                
                // Avatar resolution
                let avatar = self.resolveAvatar(baseDir: baseDir, dirKey: dirKey, info: info)
                
                let profile = DiscoveredChromeProfile(
                    index: index,
                    dir: dirKey,
                    name: name,
                    email: email,
                    avatarImage: avatar
                )
                foundProfiles.append(profile)
                index += 1
                
                // Limit to top 8 profiles
                if index > 8 { break }
            }
            
            if !foundProfiles.isEmpty {
                self.browserBundleID = discoveredBundleID
                break
            }
        }
        
        // If no profiles discovered or Chrome not found, create standard default profile
        if foundProfiles.isEmpty {
            self.browserBundleID = "com.google.Chrome"
            foundProfiles.append(
                DiscoveredChromeProfile(
                    index: 1,
                    dir: "Default",
                    name: "Default Profile",
                    email: nil,
                    avatarImage: AppDiscoveryService.shared.iconForApp(nameOrBundle: "Google Chrome")
                )
            )
        }
        
        self.profiles = foundProfiles
        AppLogger.getLogger(category: .browser).info("Discovered \(foundProfiles.count) browser profiles.")
    }
    
    private func resolveAvatar(baseDir: String, dirKey: String, info: [String: Any]) -> NSImage {
        if let cached = cachedIcons[dirKey] {
            return cached
        }
        
        let profileDir = (baseDir as NSString).appendingPathComponent(dirKey)
        let candidatePics = [
            (profileDir as NSString).appendingPathComponent("Google Profile Picture.png"),
            (profileDir as NSString).appendingPathComponent("Google Profile Picture.jpg"),
            (profileDir as NSString).appendingPathComponent("Google Profile Picture")
        ]
        
        for picPath in candidatePics {
            if FileManager.default.fileExists(atPath: picPath),
               let image = NSImage(contentsOfFile: picPath) {
                let circular = makeCircularImage(image: image)
                cachedIcons[dirKey] = circular
                return circular
            }
        }
        
        // Fallback: use Chrome app icon
        let fallback = AppDiscoveryService.shared.iconForApp(nameOrBundle: "Google Chrome")
        cachedIcons[dirKey] = fallback
        return fallback
    }
    
    private func makeCircularImage(image: NSImage) -> NSImage {
        let size = NSSize(width: 64, height: 64)
        let output = NSImage(size: size)
        output.lockFocus()
        
        let path = NSBezierPath(ovalIn: NSRect(origin: .zero, size: size))
        path.addClip()
        image.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .sourceOver, fraction: 1.0)
        
        output.unlockFocus()
        return output
    }
    
    public func focusProfile(index: Int) {
        guard let p = profiles.first(where: { $0.index == index }) else { return }
        focusProfile(dir: p.dir)
    }
    
    public func focusProfile(dir: String) {
        let bundleID = self.browserBundleID
        
        // Launch via command line argument --profile-directory
        try? process.runCommand(launchPath: "/usr/bin/open", arguments: ["-b", bundleID, "--args", "--profile-directory=\(dir)"])
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.1))
            let apps = workspace.runningApps
            if let chrome = apps.first(where: { $0.bundleIdentifier == bundleID }) {
                chrome.activateApp()
            }
        }
    }
}
