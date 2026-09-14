import Foundation
import Cocoa
import AppKit
import ApplicationServices
import os

// MARK: - App Candidate
public struct AppCandidate: Sendable, Equatable {
    public let name: String
    public let bundleID: String
    public let defaultPaths: [String]
    
    public var firstLetter: Character {
        Character((name.first(where: { $0.isLetter }) ?? "A").uppercased())
    }
    
    public init(name: String, bundleID: String, defaultPaths: [String]) {
        self.name = name
        self.bundleID = bundleID
        self.defaultPaths = defaultPaths
    }
}

// MARK: - App Group Engine
@MainActor
public final class AppGroupEngine: ObservableObject, @unchecked Sendable {
    public let category: String
    public let candidates: [AppCandidate]
    
    /// Test hooks
    public var customItemsOverride: [AntigravityItem]? = nil
    public var mockFrontmostBundleID: String? = nil
    
    @Published public var items: [AntigravityItem] = []
    public var lastActiveIndex: Int = 0
    
    public var activeShortcutChar: Character {
        if let selected = selectedItem {
            return Character((selected.name.first(where: { $0.isLetter }) ?? "A").uppercased())
        }
        return Character((category.first(where: { $0.isLetter }) ?? "A").uppercased())
    }
    
    public var activeShortcutKeyCode: UInt32 {
        KeyCodes.keyCode(for: activeShortcutChar) ?? KeyCodes.kVK_ANSI_A
    }
    
    public func candidate(for bundleID: String) -> AppCandidate? {
        candidates.first(where: { $0.bundleID == bundleID })
    }
    
    @Published public var selectedBundleID: String? {
        didSet {
            if let id = selectedBundleID {
                UserDefaults.standard.set(id, forKey: "SelectedApp_\(category)")
            }
        }
    }
    
    public var selectedItem: AntigravityItem? {
        if let id = selectedBundleID, let found = items.first(where: { $0.bundleID == id }) {
            return found
        }
        return items.first
    }
    
    public func select(bundleID: String) {
        if items.contains(where: { $0.bundleID == bundleID }) {
            selectedBundleID = bundleID
        }
    }
    
    public func isSelected(bundleID: String) -> Bool {
        selectedItem?.bundleID == bundleID
    }
    
    private let logger: Logger
    
    public init(category: String, candidates: [AppCandidate]) {
        self.category = category
        self.candidates = candidates
        self.logger = Logger(subsystem: "com.unacau.chromequickaccess", category: category.lowercased())
        refreshItems()
        setupAppSwitchObserver()
    }
    
    // MARK: - Pre-configured Shared Engines
    
    /// Terminal Engine: iTerm2 (I), Ghostty (G), Warp (W), macOS Terminal (T)
    public static let terminal = AppGroupEngine(
        category: "Terminal",
        candidates: [
            AppCandidate(
                name: "iTerm2",
                bundleID: "com.googlecode.iterm2",
                defaultPaths: [
                    "/Applications/iTerm.app",
                    "\(NSHomeDirectory())/Applications/iTerm.app"
                ]
            ),
            AppCandidate(
                name: "Ghostty",
                bundleID: "com.mitchellh.ghostty",
                defaultPaths: [
                    "/Applications/Ghostty.app",
                    "\(NSHomeDirectory())/Applications/Ghostty.app"
                ]
            ),
            AppCandidate(
                name: "Warp",
                bundleID: "dev.warp.Warp-Stable",
                defaultPaths: [
                    "/Applications/Warp.app",
                    "\(NSHomeDirectory())/Applications/Warp.app"
                ]
            ),
            AppCandidate(
                name: "Terminal",
                bundleID: "com.apple.Terminal",
                defaultPaths: [
                    "/System/Applications/Utilities/Terminal.app",
                    "/Applications/Utilities/Terminal.app"
                ]
            )
        ]
    )
    
    /// Notes Engine: Obsidian (O), Apple Notes (N), Notion (N), Bear (B)
    public static let notes = AppGroupEngine(
        category: "Notes",
        candidates: [
            AppCandidate(
                name: "Obsidian",
                bundleID: "md.obsidian",
                defaultPaths: [
                    "/Applications/Obsidian.app",
                    "\(NSHomeDirectory())/Applications/Obsidian.app"
                ]
            ),
            AppCandidate(
                name: "Notes",
                bundleID: "com.apple.Notes",
                defaultPaths: [
                    "/System/Applications/Notes.app",
                    "/Applications/Notes.app"
                ]
            ),
            AppCandidate(
                name: "Notion",
                bundleID: "notion.id",
                defaultPaths: [
                    "/Applications/Notion.app",
                    "\(NSHomeDirectory())/Applications/Notion.app"
                ]
            ),
            AppCandidate(
                name: "Bear",
                bundleID: "net.shinyfrog.bear",
                defaultPaths: [
                    "/Applications/Bear.app",
                    "\(NSHomeDirectory())/Applications/Bear.app"
                ]
            )
        ]
    )
    
    /// IDE Engine: Antigravity IDE (A), Cursor (C), VS Code (V), Xcode (X)
    public static let ide = AppGroupEngine(
        category: "IDE",
        candidates: [
            AppCandidate(
                name: "IntelliJ IDEA",
                bundleID: "com.jetbrains.intellij",
                defaultPaths: [
                    "/Applications/IntelliJ IDEA.app",
                    "/Applications/IntelliJ IDEA Ultimate.app",
                    "/Applications/IntelliJ IDEA CE.app",
                    "\(NSHomeDirectory())/Applications/IntelliJ IDEA.app",
                    "\(NSHomeDirectory())/Applications/IntelliJ IDEA Ultimate.app",
                    "\(NSHomeDirectory())/Applications/IntelliJ IDEA CE.app"
                ]
            ),
            AppCandidate(
                name: "IntelliJ IDEA CE",
                bundleID: "com.jetbrains.intellij.ce",
                defaultPaths: [
                    "/Applications/IntelliJ IDEA CE.app",
                    "\(NSHomeDirectory())/Applications/IntelliJ IDEA CE.app"
                ]
            ),
            AppCandidate(
                name: "Antigravity IDE",
                bundleID: "com.google.antigravity-ide",
                defaultPaths: [
                    "/Applications/Antigravity IDE.app",
                    "\(NSHomeDirectory())/Applications/Antigravity IDE.app"
                ]
            ),
            AppCandidate(
                name: "Cursor",
                bundleID: "com.todesktop.230313mzl4w4u92",
                defaultPaths: [
                    "/Applications/Cursor.app",
                    "\(NSHomeDirectory())/Applications/Cursor.app"
                ]
            ),
            AppCandidate(
                name: "Visual Studio Code",
                bundleID: "com.microsoft.VSCode",
                defaultPaths: [
                    "/Applications/Visual Studio Code.app",
                    "\(NSHomeDirectory())/Applications/Visual Studio Code.app"
                ]
            ),
            AppCandidate(
                name: "Xcode",
                bundleID: "com.apple.dt.Xcode",
                defaultPaths: [
                    "/Applications/Xcode.app"
                ]
            )
        ]
    )
    
    /// AI Agent Engine: Antigravity (A), Claude (C), ChatGPT (C)
    public static let aiAgent = AppGroupEngine(
        category: "AI Agent",
        candidates: [
            AppCandidate(
                name: "Antigravity",
                bundleID: "com.google.antigravity",
                defaultPaths: [
                    "/Applications/Antigravity.app",
                    "\(NSHomeDirectory())/Applications/Antigravity.app"
                ]
            ),
            AppCandidate(
                name: "Claude",
                bundleID: "com.anthropic.claudefordesktop",
                defaultPaths: [
                    "/Applications/Claude.app",
                    "\(NSHomeDirectory())/Applications/Claude.app"
                ]
            ),
            AppCandidate(
                name: "ChatGPT",
                bundleID: "com.openai.chat",
                defaultPaths: [
                    "/Applications/ChatGPT.app",
                    "\(NSHomeDirectory())/Applications/ChatGPT.app"
                ]
            )
        ]
    )
    
    // MARK: - Discovery & Refresh
    
    public func refreshItems() {
        if let override = self.customItemsOverride {
            self.items = override
            if let saved = UserDefaults.standard.string(forKey: "SelectedApp_\(category)"),
               override.contains(where: { $0.bundleID == saved }) {
                self.selectedBundleID = saved
            } else {
                self.selectedBundleID = override.first?.bundleID
            }
            return
        }
        
        var discovered: [AntigravityItem] = []
        let runningBundles = Set(NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier })
        
        for candidate in candidates {
            var appPath: String?
            for path in candidate.defaultPaths {
                if FileManager.default.fileExists(atPath: path) {
                    appPath = path
                    break
                }
            }
            
            if appPath == nil {
                if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: candidate.bundleID) {
                    appPath = url.path
                }
            }
            
            let isRunning = runningBundles.contains(candidate.bundleID)
            let isInstalled = appPath != nil && FileManager.default.fileExists(atPath: appPath!)
            
            // Only add candidate if installed or currently running
            guard isInstalled || isRunning else { continue }
            
            let finalPath = appPath ?? candidate.defaultPaths.first ?? ""
            let icon: NSImage
            if !finalPath.isEmpty && FileManager.default.fileExists(atPath: finalPath) {
                icon = NSWorkspace.shared.icon(forFile: finalPath)
            } else if let running = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == candidate.bundleID }),
                      let runningIcon = running.icon {
                icon = runningIcon
            } else {
                icon = makeMonogramImage(name: candidate.name)
            }
            icon.size = NSSize(width: 64, height: 64)
            
            discovered.append(
                AntigravityItem(
                    name: candidate.name,
                    bundleID: candidate.bundleID,
                    path: finalPath,
                    icon: icon,
                    index: discovered.count + 1
                )
            )
        }
        
        // Fallback if none discovered: add the last candidate (system default)
        if discovered.isEmpty, let fallback = candidates.last {
            let finalPath = fallback.defaultPaths.first ?? ""
            let icon: NSImage
            if !finalPath.isEmpty && FileManager.default.fileExists(atPath: finalPath) {
                icon = NSWorkspace.shared.icon(forFile: finalPath)
            } else {
                icon = makeMonogramImage(name: fallback.name)
            }
            icon.size = NSSize(width: 64, height: 64)
            
            discovered.append(
                AntigravityItem(
                    name: fallback.name,
                    bundleID: fallback.bundleID,
                    path: finalPath,
                    icon: icon,
                    index: 1
                )
            )
        }
        
        self.items = discovered
        
        // Restore selectedBundleID from UserDefaults or default to first
        let saved = UserDefaults.standard.string(forKey: "SelectedApp_\(category)")
        if let saved = saved, discovered.contains(where: { $0.bundleID == saved }) {
            self.selectedBundleID = saved
        } else {
            self.selectedBundleID = discovered.first?.bundleID
        }
        
        logger.info("Discovered \(discovered.count) \(self.category) applications. Selected: \(self.selectedItem?.name ?? "none")")
    }
    
    private func setupAppSwitchObserver() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notif in
            guard let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleID = app.bundleIdentifier else { return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if let idx = self.items.firstIndex(where: { $0.bundleID == bundleID }) {
                    self.lastActiveIndex = idx
                }
            }
        }
    }
    
    /// Returns the index of the currently active/frontmost application in this group, if any.
    public func getActiveAppIndex() -> Int? {
        let frontBundleID = self.mockFrontmostBundleID ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        guard let bundleID = frontBundleID else { return nil }
        return items.firstIndex(where: { $0.bundleID == bundleID })
    }
    
    /// Focus the item with given bundle identifier
    public func focusItem(bundleID: String) {
        guard let item = items.first(where: { $0.bundleID == bundleID }) else {
            logger.warning("\(self.category) app with bundle ID \(bundleID) not found.")
            return
        }
        
        if let idx = items.firstIndex(where: { $0.bundleID == bundleID }) {
            lastActiveIndex = idx
        }
        
        let runningApps = NSWorkspace.shared.runningApplications
        if let running = runningApps.first(where: { $0.bundleIdentifier == bundleID }) {
            logger.info("Activating running application: \(item.name) (PID: \(running.processIdentifier))")
            if #available(macOS 14.0, *) {
                running.activate()
            } else {
                running.activate(options: .activateIgnoringOtherApps)
            }
            
            // Raise and unminimize windows
            let appElement = AXUIElementCreateApplication(running.processIdentifier)
            var windowsRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef) == .success,
               let windows = windowsRef as? [AXUIElement], !windows.isEmpty {
                for window in windows {
                    var isMinRef: CFTypeRef?
                    if AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &isMinRef) == .success,
                       let isMin = isMinRef as? Bool, isMin {
                        AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, false as CFTypeRef)
                    }
                }
                if let first = windows.first {
                    AXUIElementPerformAction(first, kAXRaiseAction as CFString)
                    AXUIElementSetAttributeValue(first, kAXMainAttribute as CFString, true as CFTypeRef)
                }
            }
        } else {
            // Cold start
            logger.info("Cold starting application: \(item.name) at path \(item.path)")
            if !item.path.isEmpty && FileManager.default.fileExists(atPath: item.path) {
                let url = URL(fileURLWithPath: item.path)
                NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
            } else if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
            } else {
                let task = Process()
                task.launchPath = "/usr/bin/open"
                task.arguments = ["-b", bundleID]
                try? task.run()
                task.waitUntilExit()
            }
        }
    }
    
    public func makeMonogramImage(name: String) -> NSImage {
        let size = NSSize(width: 64, height: 64)
        let img = NSImage(size: size)
        img.lockFocus()
        
        let rect = NSRect(origin: .zero, size: size)
        let path = NSBezierPath(ovalIn: rect)
        NSColor(red: 70/255, green: 130/255, blue: 230/255, alpha: 1.0).setFill()
        path.fill()
        
        let letter = String(name.prefix(1)).uppercased()
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 28),
            .foregroundColor: NSColor.white
        ]
        let str = NSAttributedString(string: letter, attributes: attrs)
        let strSize = str.size()
        let strRect = NSRect(
            x: (size.width - strSize.width) / 2,
            y: (size.height - strSize.height) / 2,
            width: strSize.width,
            height: strSize.height
        )
        str.draw(in: strRect)
        
        img.unlockFocus()
        return img
    }
    
    // MARK: - Unified Letter-Based Discovery & Selection
    
    public static var allEngines: [AppGroupEngine] {
        [aiAgent, ide, terminal, notes]
    }
    
    public static var selectedBundleIDs: Set<String> {
        get {
            if let saved = UserDefaults.standard.stringArray(forKey: "SelectedAppBundleIDs") {
                return Set(saved)
            }
            var initial = Set<String>()
            for engine in allEngines {
                if let id = engine.selectedBundleID {
                    initial.insert(id)
                }
            }
            if initial.isEmpty {
                initial = [
                    "com.google.antigravity",
                    "com.google.antigravity-ide",
                    "com.googlecode.iterm2",
                    "com.apple.Notes"
                ]
            }
            UserDefaults.standard.set(Array(initial), forKey: "SelectedAppBundleIDs")
            return initial
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: "SelectedAppBundleIDs")
        }
    }
    
    public static func isAppSelected(bundleID: String) -> Bool {
        selectedBundleIDs.contains(bundleID)
    }
    
    public static func selectApp(bundleID: String) {
        var set = selectedBundleIDs
        set.insert(bundleID)
        selectedBundleIDs = set
    }
    
    public static func deselectApp(bundleID: String) {
        var set = selectedBundleIDs
        set.remove(bundleID)
        selectedBundleIDs = set
    }
    
    public static func toggleApp(bundleID: String) {
        var set = selectedBundleIDs
        if set.contains(bundleID) {
            set.remove(bundleID)
        } else {
            set.insert(bundleID)
        }
        selectedBundleIDs = set
    }
    
    /// Discovers and groups all available application items strictly by their first letter.
    public static func discoveredItemsByLetter() -> [Character: [AntigravityItem]] {
        var seen = Set<String>()
        var result: [Character: [AntigravityItem]] = [:]
        
        for engine in allEngines {
            for item in engine.items {
                guard !seen.contains(item.bundleID) else { continue }
                seen.insert(item.bundleID)
                
                let char = Character((item.name.first(where: { $0.isLetter }) ?? "A").uppercased())
                if result[char] == nil {
                    result[char] = []
                }
                result[char]?.append(item)
            }
        }
        
        return result
    }
    
    /// Focus an application item across all engines.
    public static func focusItem(bundleID: String) {
        if let engine = allEngines.first(where: { $0.items.contains(where: { $0.bundleID == bundleID }) }) {
            engine.focusItem(bundleID: bundleID)
        } else {
            AntigravityEngine.shared.focusItem(bundleID: bundleID)
        }
    }
}

