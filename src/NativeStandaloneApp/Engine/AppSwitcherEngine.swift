import Cocoa
import SwiftUI

struct AppSwitcherItem: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let displayName: String
    let icon: NSImage
    var isChromeProfile: Bool = false
    var profileIndex: Int? = nil
    var badge: String? = nil
}

@MainActor
final class AppSwitcherEngine: ObservableObject {
    static let shared = AppSwitcherEngine()
    
    @Published var isVisible: Bool = false
    @Published var currentItems: [AppSwitcherItem] = []
    @Published var selectedIndex: Int = 0
    
    private var dismissTimer: Timer?
    private var keyBindings: [UInt32: [String]] = [:]
    private var lastActiveIndices: [UInt32: Int] = [:]
    
    private init() {
        setupDefaultBindings()
    }
    
    private func setupDefaultBindings() {
        // Cmd + Option modifiers in Carbon
        let cmdOptModifiers = KeyCodes.cmdOptModifiers
        
        // Bindings matching Hammerspoon spec
        bind(keyCode: KeyCodes.kVK_ANSI_I, apps: ["iTerm", "Terminal"])
        bind(keyCode: KeyCodes.kVK_ANSI_S, apps: ["Spotify", "SoundCloud", "System Settings"])
        bind(keyCode: KeyCodes.kVK_ANSI_T, apps: ["Telegram"])
        bind(keyCode: KeyCodes.kVK_ANSI_A, apps: ["Antigravity", "Antigravity IDE"])
        bind(keyCode: KeyCodes.kVK_ANSI_N, apps: ["Notes"])
        bind(keyCode: KeyCodes.kVK_ANSI_P, apps: ["Photos", "Preview", "Passwords"])
        bind(keyCode: KeyCodes.kVK_ANSI_C, apps: ["Google Chrome", "Calendar"])
        bind(keyCode: KeyCodes.kVK_ANSI_M, apps: ["Activity Monitor"])
        bind(keyCode: KeyCodes.kVK_ANSI_F, apps: ["Finder", "Freeform"])
        
        // Contextual numbers 1..4 for Chrome profiles when focused
        HotkeyManager.shared.register(keyCode: KeyCodes.kVK_ANSI_1, modifiers: cmdOptModifiers) {
            ChromeProfileHelper.shared.focusProfile(index: 1)
        }
        HotkeyManager.shared.register(keyCode: KeyCodes.kVK_ANSI_2, modifiers: cmdOptModifiers) {
            ChromeProfileHelper.shared.focusProfile(index: 2)
        }
        HotkeyManager.shared.register(keyCode: KeyCodes.kVK_ANSI_3, modifiers: cmdOptModifiers) {
            ChromeProfileHelper.shared.focusProfile(index: 3)
        }
        HotkeyManager.shared.register(keyCode: KeyCodes.kVK_ANSI_4, modifiers: cmdOptModifiers) {
            ChromeProfileHelper.shared.focusProfile(index: 4)
        }
    }
    
    func bind(keyCode: UInt32, apps: [String]) {
        keyBindings[keyCode] = apps
        let cmdOptModifiers = KeyCodes.cmdOptModifiers
        
        HotkeyManager.shared.register(keyCode: keyCode, modifiers: cmdOptModifiers) { [weak self] in
            Task { @MainActor in
                self?.handleKeyPress(keyCode: keyCode)
            }
        }
    }
    
    func handleKeyPress(keyCode: UInt32) {
        guard let apps = keyBindings[keyCode], !apps.isEmpty else { return }
        
        if apps.count == 1 {
            // Instant launch if only 1 app bound
            launchOrFocusApp(name: apps[0])
            return
        }
        
        // Build items
        var items: [AppSwitcherItem] = []
        for appName in apps {
            let icon = iconForApp(appName: appName)
            items.append(AppSwitcherItem(name: appName, displayName: appName, icon: icon))
        }
        
        if isVisible && currentItems.map({ $0.name }) == items.map({ $0.name }) {
            // Cycle to next item
            selectedIndex = (selectedIndex + 1) % items.count
            resetDismissTimer()
        } else {
            // Start switching session
            currentItems = items
            
            // Check frontmost app to select next candidate
            if let frontApp = NSWorkspace.shared.frontmostApplication?.localizedName {
                if let idx = items.firstIndex(where: { $0.name.lowercased() == frontApp.lowercased() }) {
                    selectedIndex = (idx + 1) % items.count
                } else {
                    selectedIndex = lastActiveIndices[keyCode] ?? 0
                    if selectedIndex >= items.count { selectedIndex = 0 }
                }
            } else {
                selectedIndex = lastActiveIndices[keyCode] ?? 0
            }
            
            showHUD()
            resetDismissTimer()
        }
    }
    
    private func resetDismissTimer() {
        dismissTimer?.invalidate()
        // Automatically commit and dismiss 750ms after user stops tapping shortcut
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.commitAndHide()
            }
        }
    }
    
    func commitAndHide() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        
        if isVisible && !currentItems.isEmpty {
            let selected = currentItems[selectedIndex]
            launchOrFocusApp(name: selected.name)
        }
        
        isVisible = false
        HUDOverlayWindow.shared.hide()
    }
    
    private func showHUD() {
        isVisible = true
        HUDOverlayWindow.shared.show()
    }
    
    func launchOrFocusApp(name: String) {
        let running = NSWorkspace.shared.runningApplications
        if let app = running.first(where: { $0.localizedName?.lowercased() == name.lowercased() || $0.bundleIdentifier?.lowercased().contains(name.lowercased()) == true }) {
            app.activate()
            return
        }
        
        // Search in /Applications
        let candidatePaths = [
            "/Applications/\(name).app",
            "/System/Applications/\(name).app",
            "/System/Applications/Utilities/\(name).app",
            "\(NSHomeDirectory())/Applications/\(name).app"
        ]
        
        for path in candidatePaths {
            if FileManager.default.fileExists(atPath: path) {
                let url = URL(fileURLWithPath: path)
                NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
                return
            }
        }
        
        // Fallback open by name
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-a", name]
        try? task.run()
    }
    
    func iconForApp(appName: String) -> NSImage {
        let candidatePaths = [
            "/Applications/\(appName).app",
            "/System/Applications/\(appName).app",
            "/System/Applications/Utilities/\(appName).app",
            "\(NSHomeDirectory())/Applications/\(appName).app"
        ]
        
        for path in candidatePaths {
            if FileManager.default.fileExists(atPath: path) {
                return NSWorkspace.shared.icon(forFile: path)
            }
        }
        
        if let runningApp = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName?.lowercased() == appName.lowercased() }) {
            return runningApp.icon ?? NSWorkspace.shared.icon(forFile: "/System/Library/CoreServices/Finder.app")
        }
        
        return NSWorkspace.shared.icon(forFile: "/System/Library/CoreServices/Finder.app")
    }
}
