import Foundation
import Cocoa
import AppKit
import ApplicationServices
import os

// MARK: - Chrome Profile Model
public struct ChromeProfile: Identifiable, Equatable {
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

// MARK: - Chrome Profile Engine
@MainActor
public final class ChromeProfileEngine: ObservableObject {
    public static let shared = ChromeProfileEngine()
    
    @Published public private(set) var profiles: [ChromeProfile] = []
    public var browserBundleID: String = "com.google.Chrome"
    
    /// Optional override for isolated unit testing
    public static var localStatePathOverride: String? = nil
    
    private var cachedAvatars: [String: NSImage] = [:]
    private let logger = Logger(subsystem: "com.unacau.chromequickaccess", category: "profiles")
    
    public init() {
        refreshProfiles()
    }
    
    public var candidateLocalStatePaths: [String] {
        if let overridePath = Self.localStatePathOverride {
            return [overridePath]
        }
        let home = NSHomeDirectory()
        return [
            "\(home)/Library/Application Support/Google/Chrome/Local State",
            "\(home)/Library/Application Support/BraveSoftware/Brave-Browser/Local State",
            "\(home)/Library/Application Support/Microsoft Edge/Local State",
            "\(home)/Library/Application Support/Chromium/Local State"
        ]
    }
    
    public func refreshProfiles() {
        cachedAvatars.removeAll()
        let fileManager = FileManager.default
        let chromeAppPath = "/Applications/Google Chrome.app"
        
        var foundProfiles: [ChromeProfile] = []
        var discoveredBundleID = "com.google.Chrome"
        
        for path in candidateLocalStatePaths {
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
            
            var dirKeys = Array(infoCache.keys)
            // Sort: Default first, then alphanumeric
            dirKeys.sort { a, b in
                if a == "Default" { return true }
                if b == "Default" { return false }
                return a < b
            }
            
            for (offset, dirKey) in dirKeys.enumerated() {
                guard let info = infoCache[dirKey] else { continue }
                
                let name = (info["name"] as? String)
                    ?? (info["gaia_name"] as? String)
                    ?? (info["user_name"] as? String)
                    ?? (dirKey == "Default" ? "Personal" : dirKey)
                
                let email = (info["user_name"] as? String) ?? (info["email"] as? String)
                let gaiaName = info["gaia_name"] as? String
                let gaiaGivenName = info["gaia_given_name"] as? String
                let avatar = resolveAvatar(baseDir: baseDir, dirKey: dirKey, info: info)
                
                let profile = ChromeProfile(
                    index: offset + 1,
                    dir: dirKey,
                    name: name,
                    email: email,
                    gaiaName: gaiaName,
                    gaiaGivenName: gaiaGivenName,
                    avatarImage: avatar
                )
                foundProfiles.append(profile)
                if foundProfiles.count >= 8 { break }
            }
            
            if !foundProfiles.isEmpty {
                self.browserBundleID = discoveredBundleID
                break
            }
        }
        
        // Fallback default profile if none found
        if foundProfiles.isEmpty {
            self.browserBundleID = "com.google.Chrome"
            foundProfiles.append(
                ChromeProfile(
                    index: 1,
                    dir: "Default",
                    name: "Default Profile",
                    email: nil,
                    gaiaName: nil,
                    gaiaGivenName: nil,
                    avatarImage: makeMonogramImage(name: "Chrome")
                )
            )
        }
        
        self.profiles = foundProfiles
        logger.info("Discovered \(foundProfiles.count) browser profiles.")
    }
    
    // MARK: - Profile Focus & Activation
    public func focusChrome() {
        let runningApps = NSWorkspace.shared.runningApplications
        if runningApps.contains(where: { $0.bundleIdentifier == self.browserBundleID }) {
            let targetDir = getActiveProfileDir() ?? profiles.first?.dir ?? "Default"
            focusProfile(dir: targetDir)
        } else {
            launchColdStart(profileDir: profiles.first?.dir ?? "Default")
        }
    }
    
    public func getActiveProfileDir() -> String? {
        let menuItems = getProfilesMenuItems(bundleID: self.browserBundleID)
        for item in menuItems {
            var markRef: CFTypeRef?
            AXUIElementCopyAttributeValue(item, ("AXMenuItemMarkChar" as NSString) as CFString, &markRef)
            if let mark = markRef as? String, mark == "✓" {
                var titleRef: CFTypeRef?
                AXUIElementCopyAttributeValue(item, kAXTitleAttribute as CFString, &titleRef)
                if let title = titleRef as? String {
                    let norm = title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    if let match = profiles.first(where: {
                        let eff = $0.effectiveName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                        let exp = $0.expectedMenuTitle.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                        return norm == eff || norm == exp || norm.contains("(\(eff))")
                    }) {
                        return match.dir
                    }
                }
            }
        }
        return nil
    }
    
    public func focusProfile(dir: String) {
        let bundleID = self.browserBundleID
        guard let profile = profiles.first(where: { $0.dir == dir }) else {
            focusChrome()
            return
        }
        
        let runningApps = NSWorkspace.shared.runningApplications
        guard let chromeApp = runningApps.first(where: { $0.bundleIdentifier == bundleID }) else {
            launchColdStart(profileDir: profile.dir)
            return
        }
        
        let appElement = AXUIElementCreateApplication(chromeApp.processIdentifier)
        
        func scanProfileWindows() -> (open: [AXUIElement], minimized: [AXUIElement]) {
            var windowsRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef) == .success,
                  let windows = windowsRef as? [AXUIElement] else {
                return ([], [])
            }
            
            let expected = profile.expectedMenuTitle.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let effective = profile.effectiveName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let isOnlyProfile = self.profiles.count <= 1
            
            let matching = windows.filter { window in
                if isOnlyProfile { return true }
                var titleRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef) == .success,
                   let title = titleRef as? String {
                    let lowerTitle = title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    return lowerTitle.hasSuffix(expected) || lowerTitle.hasSuffix(effective)
                }
                return false
            }
            
            var opens: [AXUIElement] = []
            var mins: [AXUIElement] = []
            for w in matching {
                var isMinRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(w, kAXMinimizedAttribute as CFString, &isMinRef) == .success,
                   let isMin = isMinRef as? Bool, isMin {
                    mins.append(w)
                } else {
                    var titleRef: CFTypeRef?
                    if AXUIElementCopyAttributeValue(w, kAXTitleAttribute as CFString, &titleRef) == .success,
                       let title = titleRef as? String, !title.isEmpty {
                        opens.append(w)
                    }
                }
            }
            return (opens, mins)
        }
        
        // 1. Immediate check: if open window already visible on current Space, focus instantly
        let initial = scanProfileWindows()
        if let targetWindow = initial.open.first {
            AXUIElementPerformAction(targetWindow, kAXRaiseAction as CFString)
            AXUIElementSetAttributeValue(targetWindow, kAXMainAttribute as CFString, true as CFTypeRef)
            chromeApp.activate()
            logger.info("Focused existing open window for profile '\(profile.name)'.")
            return
        }
        
        // 2. No open window found on current Space.
        // We cannot see windows on other Spaces, so we rely on Chrome's Profiles menu to find and focus them.
        let minimizedBefore = initial.minimized
        let menuItems = self.getProfilesMenuItems(bundleID: bundleID)
        
        if !menuItems.isEmpty, let targetItem = self.findMenuItem(for: profile, in: menuItems) {
            let res = AXUIElementPerformAction(targetItem, kAXPressAction as CFString)
            if res == .success {
                chromeApp.activate()
                self.logger.info("Switched to profile '\(profile.name)' via Accessibility menu.")
                
                // 3. Post-Menu Cleanup: Chrome natively unminimizes a profile's minimized window when selected from the menu,
                // even if an open window existed on another Space. We revert this to respect the user's explicit preference.
                if !minimizedBefore.isEmpty {
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        // Poll for up to 1.5s (15 iterations x 100ms) to catch the space transition and unminimize animation
                        for _ in 0..<15 {
                            try? await Task.sleep(nanoseconds: 100_000_000)
                            let postState = scanProfileWindows()
                            let openNow = postState.open
                            
                            var newlyUnminimized: AXUIElement? = nil
                            for openWin in openNow {
                                for minWin in minimizedBefore {
                                    if CFEqual(openWin, minWin) {
                                        newlyUnminimized = openWin
                                        break
                                    }
                                }
                                if newlyUnminimized != nil { break }
                            }
                            
                            if let unmin = newlyUnminimized {
                                // It was unminimized! Are there OTHER open windows for this profile on this space?
                                if openNow.count > 1 {
                                    AXUIElementSetAttributeValue(unmin, kAXMinimizedAttribute as CFString, true as CFTypeRef)
                                    self.logger.info("Re-minimized window that was auto-unminimized by Chrome.")
                                    // Ensure another open window gets focus
                                    if let other = openNow.first(where: { !CFEqual($0, unmin) }) {
                                        AXUIElementPerformAction(other, kAXRaiseAction as CFString)
                                        AXUIElementSetAttributeValue(other, kAXMainAttribute as CFString, true as CFTypeRef)
                                    }
                                }
                                break
                            }
                        }
                    }
                }
                return
            }
        }
        
        // 4. Fallback: Launch via /usr/bin/open CLI
        self.launchColdStart(profileDir: profile.dir)
    }
    
    private func launchColdStart(profileDir: String) {
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-b", self.browserBundleID, "--args", "--profile-directory=\(profileDir)"]
        do {
            try task.run()
            task.waitUntilExit()
            logger.info("Launched Chrome with profile-directory '\(profileDir)' via open.")
        } catch {
            logger.error("Failed to launch Chrome via open: \(error.localizedDescription)")
        }
    }
    
    // MARK: - macOS Accessibility Menu Bar Traversal
    public func getProfilesMenuItems(bundleID: String) -> [AXUIElement] {
        let runningApps = NSWorkspace.shared.runningApplications
        guard let chromeApp = runningApps.first(where: { $0.bundleIdentifier == bundleID }) else {
            return []
        }
        
        let appElement = AXUIElementCreateApplication(chromeApp.processIdentifier)
        var menuBarRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXMenuBarAttribute as CFString, &menuBarRef) == .success,
              let menuBar = menuBarRef,
              CFGetTypeID(menuBar) == AXUIElementGetTypeID() else {
            return []
        }
        let menuBarElement = menuBar as! AXUIElement
        
        var menuBarItemsRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(menuBarElement, kAXChildrenAttribute as CFString, &menuBarItemsRef) == .success,
              let menuBarItems = menuBarItemsRef as? [AXUIElement] else {
            return []
        }
        
        for item in menuBarItems {
            var titleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(item, kAXTitleAttribute as CFString, &titleRef)
            let title = (titleRef as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if Self.isProfileMenuTitle(title) {
                var childrenRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(item, kAXChildrenAttribute as CFString, &childrenRef) == .success,
                   let subMenus = childrenRef as? [AXUIElement], let subMenu = subMenus.first {
                    var itemsRef: CFTypeRef?
                    if AXUIElementCopyAttributeValue(subMenu, kAXChildrenAttribute as CFString, &itemsRef) == .success,
                       let items = itemsRef as? [AXUIElement] {
                        return items
                    }
                }
            }
        }
        
        return []
    }
    
    public static func isProfileMenuTitle(_ title: String) -> Bool {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = clean.lowercased()
        return lower == "profiles" || lower == "profile" ||
               lower == "profils" || lower == "perfiles" ||
               lower == "профили" || lower == "профиль" ||
               lower == "perfis" || lower == "profili" ||
               clean == "个人资料" || clean == "プロファイル"
    }
    
    private func findMenuItem(for profile: ChromeProfile, in menuItems: [AXUIElement]) -> AXUIElement? {
        let targetNorm = profile.expectedMenuTitle.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let effNorm = profile.effectiveName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        for item in menuItems {
            var titleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(item, kAXTitleAttribute as CFString, &titleRef)
            guard let title = titleRef as? String else { continue }
            let norm = title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            if norm == targetNorm || norm == effNorm || norm.contains("(\(effNorm))") {
                return item
            }
            if let email = profile.email?.lowercased(), !email.isEmpty, norm.contains(email) {
                return item
            }
        }
        return nil
    }
    
    // MARK: - Avatar & Monogram Helpers
    private func resolveAvatar(baseDir: String, dirKey: String, info: [String: Any]) -> NSImage {
        if let cached = cachedAvatars[dirKey] { return cached }
        
        let name = (info["name"] as? String) ?? (info["gaia_name"] as? String) ?? dirKey
        let profileDir = (baseDir as NSString).appendingPathComponent(dirKey)
        
        var candidatePics = [
            (profileDir as NSString).appendingPathComponent("Google Profile Picture.png"),
            (profileDir as NSString).appendingPathComponent("Google Profile Picture.jpg"),
            (profileDir as NSString).appendingPathComponent("Edge Profile Picture.png"),
            (profileDir as NSString).appendingPathComponent("Custom Profile Picture.png")
        ]
        if let gaiaName = info["gaia_picture_file_name"] as? String, !gaiaName.isEmpty {
            candidatePics.insert((profileDir as NSString).appendingPathComponent(gaiaName), at: 0)
        }
        
        for picPath in candidatePics {
            if FileManager.default.fileExists(atPath: picPath),
               let image = NSImage(contentsOfFile: picPath) {
                let circular = makeCircularImage(image: image)
                cachedAvatars[dirKey] = circular
                return circular
            }
        }
        
        let colorSeed = info["profile_color_seed"] as? Int
        let monogram = makeMonogramImage(name: name, colorSeed: colorSeed)
        cachedAvatars[dirKey] = monogram
        return monogram
    }
    
    public func makeCircularImage(image: NSImage) -> NSImage {
        let size = NSSize(width: 96, height: 96)
        let output = NSImage(size: size)
        output.lockFocus()
        let rect = NSRect(origin: .zero, size: size)
        let path = NSBezierPath(ovalIn: rect)
        path.addClip()
        
        let srcSize = image.size
        let minSide = min(srcSize.width, srcSize.height)
        let srcRect = NSRect(
            x: (srcSize.width - minSide) / 2,
            y: (srcSize.height - minSide) / 2,
            width: minSide,
            height: minSide
        )
        image.draw(in: rect, from: srcRect, operation: .sourceOver, fraction: 1.0)
        
        let ring = NSBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1))
        NSColor.white.withAlphaComponent(0.3).setStroke()
        ring.lineWidth = 2
        ring.stroke()
        output.unlockFocus()
        return output
    }
    
    public func makeMonogramImage(name: String, colorSeed: Int? = nil) -> NSImage {
        let size = NSSize(width: 96, height: 96)
        let output = NSImage(size: size)
        output.lockFocus()
        
        let colors: [NSColor] = [
            NSColor(red: 0.22, green: 0.50, blue: 0.95, alpha: 1.0),
            NSColor(red: 0.58, green: 0.30, blue: 0.88, alpha: 1.0),
            NSColor(red: 0.95, green: 0.42, blue: 0.25, alpha: 1.0),
            NSColor(red: 0.18, green: 0.70, blue: 0.45, alpha: 1.0),
            NSColor(red: 0.92, green: 0.65, blue: 0.15, alpha: 1.0)
        ]
        let idx = abs(colorSeed ?? name.hashValue) % colors.count
        let bg = colors[idx]
        
        let rect = NSRect(origin: .zero, size: size)
        let path = NSBezierPath(ovalIn: rect)
        bg.setFill()
        path.fill()
        
        let initial = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1)).uppercased()
        let font = NSFont.systemFont(ofSize: 44, weight: .semibold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white
        ]
        let str = NSAttributedString(string: initial.isEmpty ? "C" : initial, attributes: attrs)
        let strSize = str.size()
        let strRect = NSRect(
            x: (size.width - strSize.width) / 2,
            y: (size.height - strSize.height) / 2,
            width: strSize.width,
            height: strSize.height
        )
        str.draw(in: strRect)
        output.unlockFocus()
        return output
    }
}
