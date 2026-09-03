import Cocoa
import AppKit
import ApplicationServices

public struct DiscoveredChromeProfile: Identifiable, Equatable {
    public var id: String { dir }
    public let index: Int
    public let dir: String
    public let name: String
    public let email: String?
    public let gaiaName: String?
    public let gaiaGivenName: String?
    public let avatarImage: NSImage?
    
    public var effectiveName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        if let g = gaiaGivenName?.trimmingCharacters(in: .whitespacesAndNewlines), !g.isEmpty { return g }
        if let gn = gaiaName?.trimmingCharacters(in: .whitespacesAndNewlines), !gn.isEmpty { return gn }
        if let u = email?.trimmingCharacters(in: .whitespacesAndNewlines), !u.isEmpty { return u }
        return dir == "Default" ? "Personal" : dir
    }
    
    public var expectedMenuTitle: String {
        let cleanName = effectiveName
        if let given = gaiaGivenName?.trimmingCharacters(in: .whitespacesAndNewlines), !given.isEmpty {
            if cleanName.lowercased() != given.lowercased() {
                return "\(given) (\(cleanName))"
            }
        }
        return cleanName
    }
    
    public var disambiguatedEmailTitle: String? {
        guard let e = email?.trimmingCharacters(in: .whitespacesAndNewlines), !e.isEmpty else { return nil }
        return "\(effectiveName) (\(e))"
    }
    
    public static func normalizeForMenuMatch(_ str: String) -> String {
        return str.precomposedStringWithCanonicalMapping
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
    
    public init(
        index: Int,
        dir: String,
        name: String,
        email: String? = nil,
        gaiaName: String? = nil,
        gaiaGivenName: String? = nil,
        avatarImage: NSImage? = nil
    ) {
        self.index = index
        self.dir = dir
        self.name = name
        self.email = email
        self.gaiaName = gaiaName
        self.gaiaGivenName = gaiaGivenName
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
    @Published public var rawDiscoveredProfiles: [DiscoveredChromeProfile] = []
    @Published public var isChromeInstalled: Bool = false
    @Published public var browserBundleID: String = "com.google.Chrome"
    
    private var cachedIcons: [String: NSImage] = [:]
    private var lastLocalStateModDates: [String: Date] = [:]

    public var localStatePaths: [String] {
        if let testDir = AppConfigManager.testOverrideDirectory {
            return ["\(testDir)/Local State"]
        }
        return [
            "\(NSHomeDirectory())/Library/Application Support/Google/Chrome/Local State",
            "\(NSHomeDirectory())/Library/Application Support/BraveSoftware/Brave-Browser/Local State",
            "\(NSHomeDirectory())/Library/Application Support/Microsoft Edge/Local State",
            "\(NSHomeDirectory())/Library/Application Support/Chromium/Local State"
        ]
    }
    
    public let workspace: WorkspaceProvider
    public let process: ProcessProvider
    
    public init(workspace: WorkspaceProvider, process: ProcessProvider) {
        self.workspace = workspace
        self.process = process
        refreshProfiles()
    }
    
    @discardableResult
    public func refreshProfilesIfNeeded() -> Bool {
        var needsRefresh = profiles.isEmpty
        let fileManager = FileManager.default
        
        for path in localStatePaths {
            guard fileManager.fileExists(atPath: path) else { continue }
            if let attrs = try? fileManager.attributesOfItem(atPath: path),
               let modDate = attrs[.modificationDate] as? Date {
                if let last = lastLocalStateModDates[path] {
                    if modDate > last {
                        needsRefresh = true
                        break
                    }
                } else {
                    needsRefresh = true
                    break
                }
            }
        }
        
        if needsRefresh {
            refreshProfiles()
            return true
        }
        return false
    }
    
    public func refreshProfiles() {
        cachedIcons.removeAll()
        let fileManager = FileManager.default
        let chromeAppPath = "/Applications/Google Chrome.app"
        self.isChromeInstalled = fileManager.fileExists(atPath: chromeAppPath)
        
        // Update modification dates tracker
        for path in localStatePaths {
            if let attrs = try? fileManager.attributesOfItem(atPath: path),
               let modDate = attrs[.modificationDate] as? Date {
                lastLocalStateModDates[path] = modDate
            }
        }
        
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
            
            for dirKey in infoCache.keys {
                guard let info = infoCache[dirKey] else { continue }
                
                let name = (info["name"] as? String)
                    ?? (info["gaia_name"] as? String)
                    ?? (info["user_name"] as? String)
                    ?? (dirKey == "Default" ? "Personal" : dirKey)
                
                let email = (info["user_name"] as? String) ?? (info["email"] as? String)
                let gaiaName = info["gaia_name"] as? String
                let gaiaGivenName = info["gaia_given_name"] as? String
                
                // Avatar resolution
                let avatar = self.resolveAvatar(baseDir: baseDir, dirKey: dirKey, info: info)
                
                let profile = DiscoveredChromeProfile(
                    index: 0,
                    dir: dirKey,
                    name: name,
                    email: email,
                    gaiaName: gaiaName,
                    gaiaGivenName: gaiaGivenName,
                    avatarImage: avatar
                )
                foundProfiles.append(profile)
            }
            
            if !foundProfiles.isEmpty {
                self.browserBundleID = discoveredBundleID
                self.rawDiscoveredProfiles = foundProfiles
                
                // Sort profiles to match Chrome's native menu order
                let runningMenuItems = getProfilesMenuItems(bundleID: discoveredBundleID)
                if !runningMenuItems.isEmpty {
                    // When browser is running, sort strictly by appearance in the native Profiles menu
                    foundProfiles.sort { p1, p2 in
                        let idx1 = findMenuItemIndex(for: p1, in: runningMenuItems) ?? Int.max
                        let idx2 = findMenuItemIndex(for: p2, in: runningMenuItems) ?? Int.max
                        if idx1 != idx2 {
                            return idx1 < idx2
                        }
                        return p1.expectedMenuTitle.localizedStandardCompare(p2.expectedMenuTitle) == .orderedAscending
                    }
                } else {
                    // When browser is not running, sort alphabetically by expectedMenuTitle (matching Chromium AvatarMenu order)
                    foundProfiles.sort { p1, p2 in
                        p1.expectedMenuTitle.localizedStandardCompare(p2.expectedMenuTitle) == .orderedAscending
                    }
                }
                
                // Apply custom user-configured profile order from AppConfig if present
                let customOrder = AppConfigManager.shared.config.chromeProfileOrder
                if !customOrder.isEmpty {
                    var ordered: [DiscoveredChromeProfile] = []
                    for dir in customOrder {
                        if let match = foundProfiles.first(where: { $0.dir == dir }) {
                            ordered.append(match)
                        }
                    }
                    for p in foundProfiles {
                        if !ordered.contains(where: { $0.dir == p.dir }) {
                            ordered.append(p)
                        }
                    }
                    foundProfiles = ordered
                }
                
                // Limit to top 8 profiles and assign 1-based sequential indices
                let topProfiles = Array(foundProfiles.prefix(8))
                foundProfiles = topProfiles.enumerated().map { (offset, p) in
                    DiscoveredChromeProfile(
                        index: offset + 1,
                        dir: p.dir,
                        name: p.name,
                        email: p.email,
                        gaiaName: p.gaiaName,
                        gaiaGivenName: p.gaiaGivenName,
                        avatarImage: p.avatarImage
                    )
                }
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
                    gaiaName: nil,
                    gaiaGivenName: nil,
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
    
    public func findMenuItemIndex(for profile: DiscoveredChromeProfile, in menuItems: [AXUIElement]) -> Int? {
        guard !menuItems.isEmpty else { return nil }
        
        let pNameNorm = DiscoveredChromeProfile.normalizeForMenuMatch(profile.effectiveName)
        let expectedNorm = DiscoveredChromeProfile.normalizeForMenuMatch(profile.expectedMenuTitle)
        let emailNorm = profile.email.map { DiscoveredChromeProfile.normalizeForMenuMatch($0) }
        let dirNorm = DiscoveredChromeProfile.normalizeForMenuMatch(profile.dir)
        let disambiguatedEmailNorm = profile.disambiguatedEmailTitle.map { DiscoveredChromeProfile.normalizeForMenuMatch($0) }
        
        var normTitles: [String] = []
        for item in menuItems {
            var titleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(item, kAXTitleAttribute as CFString, &titleRef)
            let title = (titleRef as? String ?? "")
            normTitles.append(DiscoveredChromeProfile.normalizeForMenuMatch(title))
        }
        
        // Tier 1: Exact match with expectedMenuTitle (e.g. "Igor (Al11)", "Igor (GCP Free Trial)", "Igor", "Nastya")
        for (idx, normTitle) in normTitles.enumerated() {
            if !normTitle.isEmpty && normTitle == expectedNorm {
                return idx
            }
        }
        
        // Tier 1.5: Exact match with email-disambiguated title (e.g. "Work (alice@company.com)")
        if let disambiguatedEmailNorm = disambiguatedEmailNorm {
            for (idx, normTitle) in normTitles.enumerated() {
                if !normTitle.isEmpty && normTitle == disambiguatedEmailNorm {
                    return idx
                }
            }
        }
        
        // Tier 2: Exact match with effective profile name (e.g. "Nastya", "Personal")
        for (idx, normTitle) in normTitles.enumerated() {
            if !normTitle.isEmpty && normTitle == pNameNorm {
                return idx
            }
        }
        
        // Tier 3: Disambiguated profile name in parentheses (e.g. title ends with or contains "(Al11)")
        for (idx, normTitle) in normTitles.enumerated() {
            if !pNameNorm.isEmpty && (normTitle.hasSuffix("(\(pNameNorm))") || normTitle.contains("(\(pNameNorm))")) {
                return idx
            }
        }
        
        // Tier 4: Email match if email exists and non-empty
        if let emailNorm = emailNorm, !emailNorm.isEmpty {
            for (idx, normTitle) in normTitles.enumerated() {
                if normTitle.contains(emailNorm) {
                    return idx
                }
            }
        }
        
        // Tier 5: Directory name match (e.g. "(Profile 1)")
        for (idx, normTitle) in normTitles.enumerated() {
            if normTitle.contains("(\(dirNorm))") {
                return idx
            }
        }
        
        return nil
    }
    
    public func findMenuItem(for profile: DiscoveredChromeProfile, in menuItems: [AXUIElement]) -> AXUIElement? {
        if let idx = findMenuItemIndex(for: profile, in: menuItems), menuItems.indices.contains(idx) {
            return menuItems[idx]
        }
        return nil
    }
    
    public func profileMatchingMenuItemTitle(_ title: String, among profiles: [DiscoveredChromeProfile]) -> DiscoveredChromeProfile? {
        let tNorm = DiscoveredChromeProfile.normalizeForMenuMatch(title)
        guard !tNorm.isEmpty else { return nil }
        
        // Tier 1: Exact match with expectedMenuTitle
        if let match = profiles.first(where: { DiscoveredChromeProfile.normalizeForMenuMatch($0.expectedMenuTitle) == tNorm }) {
            return match
        }
        
        // Tier 1.5: Exact match with disambiguatedEmailTitle
        if let match = profiles.first(where: {
            guard let de = $0.disambiguatedEmailTitle else { return false }
            return DiscoveredChromeProfile.normalizeForMenuMatch(de) == tNorm
        }) {
            return match
        }
        
        // Tier 2: Exact match with effectiveName
        if let match = profiles.first(where: { DiscoveredChromeProfile.normalizeForMenuMatch($0.effectiveName) == tNorm }) {
            return match
        }
        
        // Tier 3: Disambiguated profile name in parentheses
        if let match = profiles.first(where: {
            let pNorm = DiscoveredChromeProfile.normalizeForMenuMatch($0.effectiveName)
            return !pNorm.isEmpty && (tNorm.hasSuffix("(\(pNorm))") || tNorm.contains("(\(pNorm))"))
        }) {
            return match
        }
        
        // Tier 4: Email match
        if let match = profiles.first(where: {
            if let e = $0.email {
                let eNorm = DiscoveredChromeProfile.normalizeForMenuMatch(e)
                if !eNorm.isEmpty {
                    return tNorm.contains(eNorm)
                }
            }
            return false
        }) {
            return match
        }
        
        // Tier 5: Directory match
        if let match = profiles.first(where: {
            let dNorm = DiscoveredChromeProfile.normalizeForMenuMatch($0.dir)
            return tNorm.contains("(\(dNorm))")
        }) {
            return match
        }
        
        return nil
    }
    
    public func sortedProfilesByMenuAppearance() -> [DiscoveredChromeProfile] {
        let list = rawDiscoveredProfiles.isEmpty ? profiles : rawDiscoveredProfiles
        return list.sorted { p1, p2 in
            p1.expectedMenuTitle.localizedStandardCompare(p2.expectedMenuTitle) == .orderedAscending
        }
    }
    
    public func focusProfile(index: Int) {
        if let p = profiles.first(where: { $0.index == index }) {
            focusProfile(dir: p.dir)
            return
        }
        if let first = profiles.first {
            launchBrowserColdStart(bundleID: browserBundleID, dir: first.dir)
        }
    }
    
    public func focusProfile(dir: String) {
        let bundleID = self.browserBundleID
        
        if let profile = profiles.first(where: { $0.dir == dir }) ?? rawDiscoveredProfiles.first(where: { $0.dir == dir }) {
            let menuItems = getProfilesMenuItems(bundleID: bundleID)
            if !menuItems.isEmpty {
                // Tier 1: Target by visual index in sorted menu appearance
                let menuProfiles = sortedProfilesByMenuAppearance()
                var targetItem: AXUIElement?
                if let visualIdx = menuProfiles.firstIndex(where: { $0.dir == dir }),
                   menuItems.indices.contains(visualIdx) {
                    targetItem = menuItems[visualIdx]
                }
                
                // Tier 2: Fallback to attribute match if index out of range or not found
                if targetItem == nil {
                    targetItem = findMenuItem(for: profile, in: menuItems)
                }
                
                if let targetItem = targetItem {
                    var titleRef: CFTypeRef?
                    AXUIElementCopyAttributeValue(targetItem, kAXTitleAttribute as CFString, &titleRef)
                    AppLogger.getLogger(category: .browser).info("focusProfile(dir: \(dir)): Selecting matched menu item '\(titleRef as? String ?? "", privacy: .public)' for profile '\(profile.name, privacy: .public)'")
                    
                    let res = AXUIElementPerformAction(targetItem, kAXPressAction as CFString)
                    if res == .success {
                        let runningApps = NSWorkspace.shared.runningApplications
                        if let chromeApp = runningApps.first(where: { $0.bundleIdentifier == bundleID }) {
                            chromeApp.activate()
                            unminimizeWindowsIfNeeded(for: chromeApp.processIdentifier)
                        }
                        let task = Process()
                        task.launchPath = "/usr/bin/open"
                        task.arguments = ["-b", bundleID]
                        try? task.run()
                        task.waitUntilExit()
                        return
                    }
                }
            }
            
            // Name/Email-based match as secondary attempt
            if selectProfileViaMenuBar(bundleID: bundleID, profile: profile) {
                return
            }
        } else {
            // Profile directory not found in cache (e.g. cold launch or unindexed profile).
            AppLogger.getLogger(category: .browser).info("focusProfile(dir: \(dir)): Profile not found in cache. Cold-starting profile '\(dir, privacy: .public)'...")
            refreshProfiles()
            launchBrowserColdStart(bundleID: bundleID, dir: dir)
            return
        }
        
        // Priority 2: Cold start browser with profile directory
        launchBrowserColdStart(bundleID: bundleID, dir: dir)
    }
    
    public func unminimizeWindowsIfNeeded(for pid: pid_t) {
        let appRef = AXUIElementCreateApplication(pid)
        var windowsRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let windows = windowsRef as? [AXUIElement] else { return }
        
        for win in windows {
            var isMinimizedRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(win, kAXMinimizedAttribute as CFString, &isMinimizedRef) == .success,
               let isMin = isMinimizedRef as? Bool, isMin {
                AXUIElementSetAttributeValue(win, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
            }
            AXUIElementPerformAction(win, kAXRaiseAction as CFString)
        }
    }
    
    private func launchBrowserColdStart(bundleID: String, dir: String) {
        AppLogger.getLogger(category: .browser).info("Cold-starting browser with profile '\(dir, privacy: .public)' via /usr/bin/open.")
        try? process.runCommand(launchPath: "/usr/bin/open", arguments: ["-b", bundleID, "--args", "--profile-directory=\(dir)"])
    }
    
    public func getProfilesMenuItems(bundleID: String) -> [AXUIElement] {
        let running = workspace.runningApps
        guard let chrome = running.first(where: { $0.bundleIdentifier == bundleID }) else { return [] }
        
        let appRef = AXUIElementCreateApplication(chrome.processIdentifier)
        var menuBarRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appRef, kAXMenuBarAttribute as CFString, &menuBarRef) == .success,
              let menuBar = menuBarRef else { return [] }
        
        var childrenRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(menuBar as! AXUIElement, kAXChildrenAttribute as CFString, &childrenRef) == .success,
              let mbItems = childrenRef as? [AXUIElement] else { return [] }
        
        let knownProfilesTitles: Set<String> = [
            "profiles", "профили", "profile", "perfiles", "profils", "profili", "perfis", "profielen", "профілі", "个人资料", "プロフィール", "프로필"
        ]
        
        for mbItem in mbItems {
            var titleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(mbItem, kAXTitleAttribute as CFString, &titleRef)
            let title = (titleRef as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            guard knownProfilesTitles.contains(title) else { continue }
            
            var subMenuRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(mbItem, kAXChildrenAttribute as CFString, &subMenuRef) == .success,
                  let subMenus = subMenuRef as? [AXUIElement], let subMenu = subMenus.first else { continue }
            
            var itemsRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(subMenu, kAXChildrenAttribute as CFString, &itemsRef) == .success,
                  let mis = itemsRef as? [AXUIElement] else { continue }
            
            var profileItems: [AXUIElement] = []
            for mi in mis {
                var miTitleRef: CFTypeRef?
                AXUIElementCopyAttributeValue(mi, kAXTitleAttribute as CFString, &miTitleRef)
                let miTitle = miTitleRef as? String ?? ""
                // The profile list ends at the first separator (empty title)
                if miTitle.isEmpty { break }
                profileItems.append(mi)
            }
            return profileItems
        }
        return []
    }
    
    public func detectActiveProfileIndex(bundleID: String) -> Int? {
        if let dir = detectActiveProfileDir(bundleID: bundleID) {
            if let p = profiles.first(where: { $0.dir == dir }) {
                return p.index
            }
        }
        return nil
    }
    
    @discardableResult
    public func selectProfileViaMenuBar(bundleID: String, profile: DiscoveredChromeProfile) -> Bool {
        let menuItems = getProfilesMenuItems(bundleID: bundleID)
        guard !menuItems.isEmpty else { return false }
        
        let pNameLower = profile.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let pEmailLower = profile.email?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let dirLower = profile.dir.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        for item in menuItems {
            var titleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(item, kAXTitleAttribute as CFString, &titleRef)
            guard let title = titleRef as? String, !title.isEmpty else { continue }
            let titleLower = title.lowercased()
            
            let matches = titleLower == pNameLower ||
                          titleLower.hasSuffix("(\(pNameLower))") ||
                          titleLower.contains("(\(pNameLower))") ||
                          (pEmailLower != nil && !pEmailLower!.isEmpty && titleLower.contains(pEmailLower!)) ||
                          (titleLower.contains("(\(dirLower))"))
            
            if matches {
                AppLogger.getLogger(category: .browser).info("selectProfileViaMenuBar: Found match '\(title, privacy: .public)' for profile '\(profile.name, privacy: .public)'")
                let res = AXUIElementPerformAction(item, kAXPressAction as CFString)
                if res == .success {
                    let runningApps = NSWorkspace.shared.runningApplications
                    runningApps.first(where: { $0.bundleIdentifier == bundleID })?.activate()
                    let task = Process()
                    task.launchPath = "/usr/bin/open"
                    task.arguments = ["-b", bundleID]
                    try? task.run()
                    task.waitUntilExit()
                    return true
                }
            }
        }
        return false
    }
    
    public func detectActiveProfileDir(bundleID: String) -> String? {
        let menuItems = getProfilesMenuItems(bundleID: bundleID)
        guard !menuItems.isEmpty else { return nil }
        
        let menuProfiles = sortedProfilesByMenuAppearance()
        for (idx, mi) in menuItems.enumerated() {
            var markRef: CFTypeRef?
            AXUIElementCopyAttributeValue(mi, "AXMenuItemMarkChar" as CFString, &markRef)
            if let m = markRef as? String, !m.isEmpty {
                if menuProfiles.indices.contains(idx) {
                    return menuProfiles[idx].dir
                }
                
                var titleRef: CFTypeRef?
                AXUIElementCopyAttributeValue(mi, kAXTitleAttribute as CFString, &titleRef)
                let title = titleRef as? String ?? ""
                
                if let matched = profileMatchingMenuItemTitle(title, among: profiles) {
                    return matched.dir
                }
                
                if profiles.indices.contains(idx) {
                    return profiles[idx].dir
                }
            }
        }
        return nil
    }
    
    public func resolveBrowserExecutablePath(bundleID: String) -> String? {
        if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
           let execPath = Bundle(url: appUrl)?.executablePath,
           FileManager.default.fileExists(atPath: execPath) {
            return execPath
        }
        
        let commonPaths = [
            "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
            "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser",
            "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
            "/Applications/Chromium.app/Contents/MacOS/Chromium"
        ]
        return commonPaths.first { FileManager.default.fileExists(atPath: $0) }
    }
}
