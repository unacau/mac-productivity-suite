import Cocoa
import AppKit

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
    private var scriptCache: [String: NSAppleScript] = [:]
    
    public let workspace: WorkspaceProvider
    public let process: ProcessProvider
    
    public init(workspace: WorkspaceProvider, process: ProcessProvider) {
        self.workspace = workspace
        self.process = process
        refreshProfiles()
    }
    
    public func refreshProfiles() {
        cachedIcons.removeAll()
        let fileManager = FileManager.default
        let chromeAppPath = "/Applications/Google Chrome.app"
        self.isChromeInstalled = fileManager.fileExists(atPath: chromeAppPath)
        
        let localStatePaths: [String] = {
            if let testDir = AppConfigManager.testOverrideDirectory {
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
        
        let name = (info["name"] as? String) ?? (info["gaia_name"] as? String) ?? dirKey
        let profileDir = (baseDir as NSString).appendingPathComponent(dirKey)
        let useGaiaPicture: Bool = {
            if let b = info["use_gaia_picture"] as? Bool {
                return b
            }
            if let i = info["use_gaia_picture"] as? Int {
                return i != 0
            }
            return true
        }()
        
        var candidatePics: [String] = []
        
        // 1. Explicit GAIA or account picture filename (only if use_gaia_picture is enabled)
        if useGaiaPicture {
            if let gaiaName = info["gaia_picture_file_name"] as? String, !gaiaName.isEmpty {
                candidatePics.append((profileDir as NSString).appendingPathComponent(gaiaName))
            }
            candidatePics.append((profileDir as NSString).appendingPathComponent("Google Profile Picture.png"))
            candidatePics.append((profileDir as NSString).appendingPathComponent("Google Profile Picture.jpg"))
            candidatePics.append((profileDir as NSString).appendingPathComponent("Google Profile Picture"))
            candidatePics.append((profileDir as NSString).appendingPathComponent("Edge Profile Picture.png"))
            candidatePics.append((profileDir as NSString).appendingPathComponent("Brave Profile Picture.png"))
        }
        
        // 2. Avatar illustration files in Chrome Avatars directory or profile dir
        if let avatarIcon = info["avatar_icon"] as? String, !avatarIcon.isEmpty {
            let iconName = (avatarIcon as NSString).lastPathComponent
            candidatePics.append((profileDir as NSString).appendingPathComponent(iconName))
            candidatePics.append(((baseDir as NSString).appendingPathComponent("Avatars") as NSString).appendingPathComponent(iconName))
            candidatePics.append(((baseDir as NSString).appendingPathComponent("Avatars") as NSString).appendingPathComponent("\(iconName).png"))
        }
        
        // 3. Custom profile overrides in profile dir or config assets
        candidatePics.append((profileDir as NSString).appendingPathComponent("Custom Profile Picture.png"))
        candidatePics.append((profileDir as NSString).appendingPathComponent("Custom Profile Picture.jpg"))
        let home = NSHomeDirectory()
        candidatePics.append("\(home)/.config/mac-productivity-suite/assets/profiles/\(dirKey).png")
        candidatePics.append("\(home)/.config/mac-productivity-suite/assets/profiles/\(dirKey).jpg")
        
        for picPath in candidatePics {
            if FileManager.default.fileExists(atPath: picPath),
               let image = NSImage(contentsOfFile: picPath) {
                let circular = makeCircularImage(image: image)
                cachedIcons[dirKey] = circular
                return circular
            }
        }
        
        // Fallback: Generate an aesthetic monogram avatar from profile name and color seed
        let colorSeed = info["profile_color_seed"] as? Int
        let monogram = makeMonogramImage(name: name, colorSeed: colorSeed)
        cachedIcons[dirKey] = monogram
        return monogram
    }
    
    private func makeCircularImage(image: NSImage) -> NSImage {
        let size = NSSize(width: 128, height: 128)
        let output = NSImage(size: size)
        output.lockFocus()
        
        let rect = NSRect(origin: .zero, size: size)
        let path = NSBezierPath(ovalIn: rect)
        path.addClip()
        
        // Square center-crop so portrait/landscape avatars don't stretch
        let srcSize = image.size
        let minSide = min(srcSize.width, srcSize.height)
        let srcRect = NSRect(
            x: (srcSize.width - minSide) / 2,
            y: (srcSize.height - minSide) / 2,
            width: minSide,
            height: minSide
        )
        image.draw(in: rect, from: srcRect, operation: .sourceOver, fraction: 1.0)
        
        // Subtle outer ring
        let ring = NSBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1))
        NSColor.white.withAlphaComponent(0.25).setStroke()
        ring.lineWidth = 2
        ring.stroke()
        
        output.unlockFocus()
        return output
    }
    
    private func makeMonogramImage(name: String, colorSeed: Int? = nil) -> NSImage {
        let size = NSSize(width: 128, height: 128)
        let output = NSImage(size: size)
        output.lockFocus()
        
        let colors: [NSColor] = [
            NSColor(red: 0.22, green: 0.50, blue: 0.95, alpha: 1.0), // Blue
            NSColor(red: 0.58, green: 0.30, blue: 0.88, alpha: 1.0), // Purple
            NSColor(red: 0.95, green: 0.42, blue: 0.25, alpha: 1.0), // Coral
            NSColor(red: 0.18, green: 0.70, blue: 0.45, alpha: 1.0), // Green
            NSColor(red: 0.92, green: 0.65, blue: 0.15, alpha: 1.0), // Amber
            NSColor(red: 0.85, green: 0.25, blue: 0.55, alpha: 1.0)  // Rose
        ]
        
        let bgColor: NSColor
        if let seed = colorSeed {
            let r = CGFloat((seed >> 16) & 0xFF) / 255.0
            let g = CGFloat((seed >> 8) & 0xFF) / 255.0
            let b = CGFloat(seed & 0xFF) / 255.0
            if r > 0.1 || g > 0.1 || b > 0.1 {
                bgColor = NSColor(red: r, green: g, blue: b, alpha: 1.0)
            } else {
                let colorIndex = abs(seed) % colors.count
                bgColor = colors[colorIndex]
            }
        } else {
            let colorIndex = abs(name.hashValue) % colors.count
            bgColor = colors[colorIndex]
        }
        
        let rect = NSRect(origin: .zero, size: size)
        let path = NSBezierPath(ovalIn: rect)
        bgColor.setFill()
        path.fill()
        
        let letter = String(name.prefix(1)).uppercased()
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 58, weight: .heavy),
            .foregroundColor: NSColor.white
        ]
        let str = NSAttributedString(string: letter.isEmpty ? "C" : letter, attributes: attrs)
        let strSize = str.size()
        let strRect = NSRect(
            x: (size.width - strSize.width) / 2,
            y: (size.height - strSize.height) / 2 - 2,
            width: strSize.width,
            height: strSize.height
        )
        str.draw(in: strRect)
        
        output.unlockFocus()
        return output
    }
    
    public func focusProfile(index: Int) {
        guard let p = profiles.first(where: { $0.index == index }) else { return }
        focusProfile(dir: p.dir)
    }
    
    private func getCompiledAppleScript(for profileName: String, email: String) -> NSAppleScript? {
        let cacheKey = "\(profileName)::\(email)"
        if let cached = scriptCache[cacheKey] {
            return cached
        }
        let escapedName = profileName.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedEmail = email.replacingOccurrences(of: "\"", with: "\\\"")
        let scriptSource = """
        tell application "Google Chrome" to activate
        tell application "System Events"
            tell process "Google Chrome"
                if exists menu "Profiles" of menu bar 1 then
                    set pMenu to menu "Profiles" of menu bar 1
                    set targetName to "\(escapedName)"
                    set targetEmail to "\(escapedEmail)"
                    
                    -- Pass 1: exact match
                    if targetName is not "" and (exists menu item targetName of pMenu) then
                        click menu item targetName of pMenu
                        return "OK"
                    end if
                    
                    -- Pass 2: candidate scan (menu items matching profile name or email)
                    repeat with mi in (every menu item of pMenu)
                        set miName to name of mi
                        if miName is not missing value then
                            if (targetName is not "" and miName contains targetName) or (targetEmail is not "" and miName contains targetEmail) then
                                click mi
                                return "OK"
                            end if
                        end if
                    end repeat
                end if
            end tell
        end tell
        return "FALLBACK"
        """
        if let script = NSAppleScript(source: scriptSource) {
            var err: NSDictionary?
            _ = script.compileAndReturnError(&err)
            scriptCache[cacheKey] = script
            return script
        }
        return nil
    }
    
    public func focusProfile(dir: String) {
        let bundleID = self.browserBundleID
        let profile = profiles.first(where: { $0.dir == dir })
        let profileName = profile?.name ?? dir
        let profileEmail = profile?.email ?? ""
        
        // 1. If Chrome is already running, switch profile via compiled AppleScript (sub-millisecond execution)
        let isRunning = workspace.runningApps.contains(where: { $0.bundleIdentifier == bundleID })
        if isRunning {
            if let appleScript = getCompiledAppleScript(for: profileName, email: profileEmail) {
                var errorDict: NSDictionary?
                let result = appleScript.executeAndReturnError(&errorDict)
                if result.stringValue == "OK" {
                    return
                }
            }
        }
        
        // 2. Fallback / Cold start: Launch via command line argument --profile-directory
        try? process.runCommand(launchPath: "/usr/bin/open", arguments: ["-b", bundleID, "--args", "--profile-directory=\(dir)"])
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.15))
            let apps = workspace.runningApps
            if let chrome = apps.first(where: { $0.bundleIdentifier == bundleID }) {
                chrome.activateApp()
            }
        }
    }
}
